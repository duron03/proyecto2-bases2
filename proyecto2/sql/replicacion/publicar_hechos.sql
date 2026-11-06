:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;

USE [master];
GO

EXEC master.dbo.sp_replicationdboption
    @dbname = N'WideWorldImporters',
    @optname = N'publish',
    @value = N'true';
GO

USE [WideWorldImporters];
GO

DECLARE @BranchCode varchar(2) = '$(BranchCode)';
DECLARE @DestinationOwner sysname = N'$(DestinationOwner)';
DECLARE @PublisherPassword varchar(128) =
    CONVERT(varchar(128), CONVERT(varbinary(256), '$(PublisherPasswordHex)', 2));
DECLARE @ReceiverPassword varchar(128) =
    CONVERT(varchar(128), CONVERT(varbinary(256), '$(ReceiverPasswordHex)', 2));
DECLARE @Publication sysname;
DECLARE @PublisherLogin sysname;
DECLARE @ReceiverLogin sysname;
DECLARE @NeedsSnapshot bit = 0;

IF @BranchCode NOT IN ('SJ', 'LI')
    THROW 51420, N'BranchCode debe ser SJ o LI.', 1;

IF (@BranchCode = 'SJ' AND (@@SERVERNAME <> N'wwi-sj' OR @DestinationOwner <> N'sj'))
   OR (@BranchCode = 'LI' AND (@@SERVERNAME <> N'wwi-limon' OR @DestinationOwner <> N'limon'))
    THROW 51421, N'La sucursal o el esquema receptor no coinciden.', 1;

SET @Publication = N'P2_Operacion_' + @BranchCode;
SET @PublisherLogin = CASE @BranchCode WHEN 'SJ' THEN N'repl_sj' ELSE N'repl_li' END;
SET @ReceiverLogin = CASE @BranchCode WHEN 'SJ' THEN N'repl_recibe_sj' ELSE N'repl_recibe_li' END;

IF NOT EXISTS (SELECT 1 FROM syspublications WHERE name = @Publication)
BEGIN
    SET @NeedsSnapshot = 1;

    EXEC dbo.sp_addpublication
        @publication = @Publication,
        @description = N'Hechos de sucursal hacia su esquema separado en CORP',
        @sync_method = N'concurrent',
        @retention = 72,
        @repl_freq = N'continuous',
        @status = N'active',
        @independent_agent = N'true',
        @immediate_sync = N'true',
        @allow_push = N'true',
        @allow_pull = N'false',
        @allow_anonymous = N'false',
        @replicate_ddl = 0;
END;

IF NOT EXISTS
(
    SELECT 1
    FROM syspublications
    WHERE name = @Publication
      AND snapshot_jobid IS NOT NULL
)
BEGIN
    EXEC dbo.sp_addpublication_snapshot
        @publication = @Publication,
        @frequency_type = 1,
        @publisher_security_mode = 0,
        @publisher_login = @PublisherLogin,
        @publisher_password = @PublisherPassword;
END;

IF NOT EXISTS
(
    SELECT 1
    FROM distribution.dbo.MSlogreader_agents
    WHERE publisher_db = N'WideWorldImporters'
)
BEGIN
    EXEC dbo.sp_addlogreader_agent
        @publisher_security_mode = 0,
        @publisher_login = @PublisherLogin,
        @publisher_password = @PublisherPassword;
END;

DECLARE @Articles TABLE
(
    Id int IDENTITY(1, 1) PRIMARY KEY,
    ArticleName sysname NOT NULL,
    SourceOwner sysname NOT NULL,
    SourceTable sysname NOT NULL
);

INSERT INTO @Articles (ArticleName, SourceOwner, SourceTable)
VALUES
    (N'Sales_Orders', N'Sales', N'Orders'),
    (N'Purchasing_PurchaseOrders', N'Purchasing', N'PurchaseOrders'),
    (N'Sales_Invoices', N'Sales', N'Invoices'),
    (N'Sales_InvoiceLines', N'Sales', N'InvoiceLines'),
    (N'Purchasing_PurchaseOrderLines', N'Purchasing', N'PurchaseOrderLines'),
    (N'Sales_CustomerTransactions', N'Sales', N'CustomerTransactions'),
    (N'Purchasing_SupplierTransactions', N'Purchasing', N'SupplierTransactions'),
    (N'Warehouse_StockItemHoldings', N'Warehouse', N'StockItemHoldings'),
    (N'Control_LatidoSucursal', N'Control', N'LatidoSucursal');

DECLARE @CurrentId int = 1;
DECLARE @LastId int = (SELECT MAX(Id) FROM @Articles);
DECLARE @ArticleName sysname;
DECLARE @SourceOwner sysname;
DECLARE @SourceTable sysname;

WHILE @CurrentId <= @LastId
BEGIN
    SELECT
        @ArticleName = ArticleName,
        @SourceOwner = SourceOwner,
        @SourceTable = SourceTable
    FROM @Articles
    WHERE Id = @CurrentId;

    IF NOT EXISTS (SELECT 1 FROM sysarticles WHERE name = @ArticleName)
    BEGIN
        SET @NeedsSnapshot = 1;

        EXEC dbo.sp_addarticle
            @publication = @Publication,
            @article = @ArticleName,
            @source_owner = @SourceOwner,
            @source_object = @SourceTable,
            @destination_owner = @DestinationOwner,
            @destination_table = @SourceTable,
            @type = N'logbased',
            @pre_creation_cmd = N'none',
            @schema_option = 0x02,
            @identityrangemanagementoption = N'manual';
    END;

    SET @CurrentId += 1;
END;

IF NOT EXISTS
(
    SELECT 1
    FROM syssubscriptions AS subscriptionObject
    INNER JOIN sys.servers AS serverObject
        ON serverObject.server_id = subscriptionObject.srvid
    WHERE serverObject.name = N'wwi-corp'
)
BEGIN
    SET @NeedsSnapshot = 1;

    EXEC dbo.sp_addsubscription
        @publication = @Publication,
        @subscriber = N'wwi-corp',
        @destination_db = N'WideWorldImporters',
        @subscription_type = N'Push',
        @sync_type = N'automatic',
        @article = N'all',
        @update_mode = N'read only';

    EXEC dbo.sp_addpushsubscription_agent
        @publication = @Publication,
        @subscriber = N'wwi-corp',
        @subscriber_db = N'WideWorldImporters',
        @subscriber_security_mode = 0,
        @subscriber_login = @ReceiverLogin,
        @subscriber_password = @ReceiverPassword,
        @frequency_type = 64;
END;

DECLARE @JobId uniqueidentifier;
DECLARE @StepId int;
DECLARE @Subsystem nvarchar(40);
DECLARE @Command nvarchar(max);

DECLARE tls_job_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT jobObject.job_id, stepObject.step_id, stepObject.subsystem, stepObject.command
    FROM msdb.dbo.sysjobs AS jobObject
    INNER JOIN msdb.dbo.sysjobsteps AS stepObject
        ON stepObject.job_id = jobObject.job_id
    WHERE stepObject.subsystem IN (N'Snapshot', N'LogReader', N'Distribution')
      AND stepObject.command LIKE N'%WideWorldImporters%';

OPEN tls_job_cursor;
FETCH NEXT FROM tls_job_cursor INTO @JobId, @StepId, @Subsystem, @Command;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF @Command NOT LIKE N'%-EncryptionLevel%'
        SET @Command = @Command + N' -EncryptionLevel 1';

    IF @Subsystem IN (N'LogReader', N'Distribution')
       AND @Command NOT LIKE N'%-PollingInterval%'
        SET @Command = @Command + N' -PollingInterval 1';

    IF @Command <> (SELECT command FROM msdb.dbo.sysjobsteps WHERE job_id = @JobId AND step_id = @StepId)
    BEGIN
        EXEC msdb.dbo.sp_update_jobstep
            @job_id = @JobId,
            @step_id = @StepId,
            @command = @Command;
    END;

    FETCH NEXT FROM tls_job_cursor INTO @JobId, @StepId, @Subsystem, @Command;
END;

CLOSE tls_job_cursor;
DEALLOCATE tls_job_cursor;

IF @NeedsSnapshot = 1
    PRINT N'La publicacion cambio. Ejecute inicializar_y_validar.sql para generar el snapshot.';
ELSE
    PRINT N'La publicacion ya estaba configurada. No se modifico el snapshot.';

SELECT
    @Publication AS PublicationName,
    @DestinationOwner AS DestinationOwner,
    (SELECT COUNT(*) FROM sysarticles WHERE pubid =
        (SELECT pubid FROM syspublications WHERE name = @Publication)) AS ArticleCount,
    @NeedsSnapshot AS RequiresSnapshot,
    N'FACT_PUBLICATION_READY' AS Result;
