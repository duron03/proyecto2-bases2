:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;

USE [master];
GO

EXEC master.dbo.sp_replicationdboption
    @dbname = N'PilotoReplicacion',
    @optname = N'publish',
    @value = N'true';
GO

USE [PilotoReplicacion];
GO

DECLARE @Password varchar(128) = CONVERT(varchar(128), CONVERT(varbinary(256), '$(PasswordHex)', 2));
DECLARE @Publication sysname = N'P2_Piloto_Operacion_$(BranchCode)';
DECLARE @DestinationOwner sysname = N'$(DestinationOwner)';
DECLARE @CreatedPublication bit = 0;

IF @DestinationOwner NOT IN (N'sj', N'limon')
BEGIN
    THROW 51002, N'DestinationOwner debe ser sj o limon.', 1;
END;

IF NOT EXISTS (SELECT 1 FROM syspublications WHERE name = @Publication)
BEGIN
    SET @CreatedPublication = 1;

    EXEC dbo.sp_addpublication
        @publication = @Publication,
        @description = N'Piloto tecnico de operacion hacia CORP',
        @sync_method = N'concurrent',
        @retention = 72,
        @repl_freq = N'continuous',
        @status = N'active',
        @independent_agent = N'true',
        @immediate_sync = N'true',
        @allow_push = N'true',
        @allow_pull = N'false',
        @allow_anonymous = N'false';

    EXEC dbo.sp_addpublication_snapshot
        @publication = @Publication,
        @frequency_type = 1,
        @publisher_security_mode = 0,
        @publisher_login = N'sa',
        @publisher_password = @Password;

    IF NOT EXISTS
    (
        SELECT 1
        FROM distribution.dbo.MSlogreader_agents
        WHERE publisher_db = N'PilotoReplicacion'
    )
    BEGIN
        EXEC dbo.sp_addlogreader_agent
            @publisher_security_mode = 0,
            @publisher_login = N'sa',
            @publisher_password = @Password;
    END;

    EXEC dbo.sp_addarticle
        @publication = @Publication,
        @article = N'OperacionPiloto',
        @source_owner = N'dbo',
        @source_object = N'OperacionPiloto',
        @destination_owner = @DestinationOwner,
        @destination_table = N'OperacionPiloto',
        @type = N'logbased',
        @pre_creation_cmd = N'none',
        @schema_option = 0x02,
        @identityrangemanagementoption = N'manual';
END;

IF NOT EXISTS
(
    SELECT 1
    FROM syssubscriptions AS subscription
    INNER JOIN sys.servers AS server
        ON server.server_id = subscription.srvid
    WHERE subscription.artid = (
        SELECT artid FROM sysarticles WHERE name = N'OperacionPiloto'
    )
      AND server.name = N'wwi-corp'
)
BEGIN
    EXEC dbo.sp_addsubscription
        @publication = @Publication,
        @subscriber = N'wwi-corp',
        @destination_db = N'PilotoReplicacion',
        @subscription_type = N'Push',
        @sync_type = N'automatic',
        @article = N'all',
        @update_mode = N'read only';

    EXEC dbo.sp_addpushsubscription_agent
        @publication = @Publication,
        @subscriber = N'wwi-corp',
        @subscriber_db = N'PilotoReplicacion',
        @subscriber_security_mode = 0,
        @subscriber_login = N'sa',
        @subscriber_password = @Password,
        @frequency_type = 64;
END;

IF @CreatedPublication = 1
BEGIN
    EXEC dbo.sp_startpublication_snapshot @publication = @Publication;
END;
ELSE
BEGIN
    PRINT N'La publicacion ya existe. No se genera otro snapshot automaticamente.';
END;

