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

DECLARE @PublisherPassword varchar(128) =
    CONVERT(varchar(128), CONVERT(varbinary(256), '$(PublisherPasswordHex)', 2));
DECLARE @ReceiverPassword varchar(128) =
    CONVERT(varchar(128), CONVERT(varbinary(256), '$(ReceiverPasswordHex)', 2));
DECLARE @Publication sysname = N'P2_Catalogos';
DECLARE @PublisherLogin sysname = N'repl_corp';
DECLARE @ReceiverLogin sysname = N'repl_recibe_catalogos';
DECLARE @CreatedPublication bit = 0;
DECLARE @NeedsSnapshot bit = 0;

IF @@SERVERNAME <> N'wwi-corp'
    THROW 51410, N'publicar_catalogos.sql solo se ejecuta en wwi-corp.', 1;

IF EXISTS (SELECT 1 FROM sys.tables WHERE temporal_type <> 0)
    THROW 51411, N'La base activa no debe publicar tablas temporales.', 1;

IF NOT EXISTS (SELECT 1 FROM syspublications WHERE name = @Publication)
BEGIN
    SET @CreatedPublication = 1;
    SET @NeedsSnapshot = 1;

    EXEC dbo.sp_addpublication
        @publication = @Publication,
        @description = N'Catalogos publicos CORP hacia San Jose y Limon',
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
    (N'Application_People', N'Application', N'People'),
    (N'Application_DeliveryMethods', N'Application', N'DeliveryMethods'),
    (N'Application_PaymentMethods', N'Application', N'PaymentMethods'),
    (N'Application_TransactionTypes', N'Application', N'TransactionTypes'),
    (N'Sales_CustomerCategories', N'Sales', N'CustomerCategories'),
    (N'Sales_BuyingGroups', N'Sales', N'BuyingGroups'),
    (N'Purchasing_SupplierCategories', N'Purchasing', N'SupplierCategories'),
    (N'Warehouse_StockGroups', N'Warehouse', N'StockGroups'),
    (N'Warehouse_Colors', N'Warehouse', N'Colors'),
    (N'Warehouse_PackageTypes', N'Warehouse', N'PackageTypes'),
    (N'Sales_Customers', N'Sales', N'Customers'),
    (N'Purchasing_Suppliers', N'Purchasing', N'Suppliers'),
    (N'Warehouse_StockItems', N'Warehouse', N'StockItems'),
    (N'Warehouse_StockItemStockGroups', N'Warehouse', N'StockItemStockGroups'),
    (N'Control_LatidoCatalogo', N'Control', N'LatidoCatalogo');

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
            @destination_owner = @SourceOwner,
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
    WHERE serverObject.name = N'wwi-sj'
)
BEGIN
    SET @NeedsSnapshot = 1;

    EXEC dbo.sp_addsubscription
        @publication = @Publication,
        @subscriber = N'wwi-sj',
        @destination_db = N'WideWorldImporters',
        @subscription_type = N'Push',
        @sync_type = N'automatic',
        @article = N'all',
        @update_mode = N'read only';

    EXEC dbo.sp_addpushsubscription_agent
        @publication = @Publication,
        @subscriber = N'wwi-sj',
        @subscriber_db = N'WideWorldImporters',
        @subscriber_security_mode = 0,
        @subscriber_login = @ReceiverLogin,
        @subscriber_password = @ReceiverPassword,
        @frequency_type = 64;
END;

IF NOT EXISTS
(
    SELECT 1
    FROM syssubscriptions AS subscriptionObject
    INNER JOIN sys.servers AS serverObject
        ON serverObject.server_id = subscriptionObject.srvid
    WHERE serverObject.name = N'wwi-limon'
)
BEGIN
    SET @NeedsSnapshot = 1;

    EXEC dbo.sp_addsubscription
        @publication = @Publication,
        @subscriber = N'wwi-limon',
        @destination_db = N'WideWorldImporters',
        @subscription_type = N'Push',
        @sync_type = N'automatic',
        @article = N'all',
        @update_mode = N'read only';

    EXEC dbo.sp_addpushsubscription_agent
        @publication = @Publication,
        @subscriber = N'wwi-limon',
        @subscriber_db = N'WideWorldImporters',
        @subscriber_security_mode = 0,
        @subscriber_login = @ReceiverLogin,
        @subscriber_password = @ReceiverPassword,
        @frequency_type = 64;
END;

/* El CU usado no admite EncryptionLevel como parametro del SP de perfil. */
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
    PRINT N'P2_Catalogos cambio. Ejecute inicializar_y_validar.sql para generar el snapshot.';
ELSE
    PRINT N'P2_Catalogos ya estaba configurada. No se modifico el snapshot.';

SELECT
    @Publication AS PublicationName,
    (SELECT COUNT(*) FROM sysarticles WHERE pubid =
        (SELECT pubid FROM syspublications WHERE name = @Publication)) AS ArticleCount,
    (SELECT COUNT(DISTINCT serverObject.name)
     FROM syssubscriptions AS subscriptionObject
     INNER JOIN sys.servers AS serverObject
        ON serverObject.server_id = subscriptionObject.srvid
     WHERE serverObject.name IN (N'wwi-sj', N'wwi-limon')) AS SubscriberCount,
    @NeedsSnapshot AS RequiresSnapshot,
    N'CATALOG_PUBLICATION_READY' AS Result;
