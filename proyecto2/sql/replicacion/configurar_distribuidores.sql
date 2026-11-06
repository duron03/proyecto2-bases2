:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @NodeCode varchar(4) = '$(NodeCode)';
DECLARE @ServerName sysname = N'$(ServerName)';
DECLARE @PublisherLogin sysname;
DECLARE @PublisherPassword varchar(128) =
    CONVERT(varchar(128), CONVERT(varbinary(256), '$(PublisherPasswordHex)', 2));
DECLARE @ReceiverCatalogPassword varchar(128) =
    CONVERT(varchar(128), CONVERT(varbinary(256), '$(ReceiverCatalogPasswordHex)', 2));
DECLARE @ReceiverSjPassword varchar(128) =
    CONVERT(varchar(128), CONVERT(varbinary(256), '$(ReceiverSjPasswordHex)', 2));
DECLARE @ReceiverLiPassword varchar(128) =
    CONVERT(varchar(128), CONVERT(varbinary(256), '$(ReceiverLiPasswordHex)', 2));
DECLARE @Sql nvarchar(max);

IF @NodeCode NOT IN ('CORP', 'SJ', 'LI')
    THROW 51400, N'NodeCode debe ser CORP, SJ o LI.', 1;

IF @@SERVERNAME <> @ServerName
    THROW 51401, N'@@SERVERNAME no coincide con ServerName.', 1;

SET @PublisherLogin =
    CASE @NodeCode
        WHEN 'CORP' THEN N'repl_corp'
        WHEN 'SJ' THEN N'repl_sj'
        ELSE N'repl_li'
    END;

/* Login que utilizan Snapshot Agent y Log Reader en este publicador. */
IF SUSER_ID(@PublisherLogin) IS NULL
BEGIN
    SET @Sql = N'CREATE LOGIN ' + QUOTENAME(@PublisherLogin)
        + N' WITH PASSWORD = ' + QUOTENAME(@PublisherPassword, N'''')
        + N', CHECK_POLICY = ON, CHECK_EXPIRATION = OFF;';
    EXEC sys.sp_executesql @Sql;
END;
ELSE
BEGIN
    SET @Sql = N'ALTER LOGIN ' + QUOTENAME(@PublisherLogin)
        + N' WITH PASSWORD = ' + QUOTENAME(@PublisherPassword, N'''') + N';';
    EXEC sys.sp_executesql @Sql;
END;

USE [WideWorldImporters];

IF DATABASE_PRINCIPAL_ID(@PublisherLogin) IS NULL
BEGIN
    SET @Sql = N'CREATE USER ' + QUOTENAME(@PublisherLogin)
        + N' FOR LOGIN ' + QUOTENAME(@PublisherLogin) + N';';
    EXEC sys.sp_executesql @Sql;
END;

IF IS_ROLEMEMBER(N'db_owner', @PublisherLogin) <> 1
    EXEC sys.sp_addrolemember N'db_owner', @PublisherLogin;

USE [master];

IF NOT EXISTS (SELECT 1 FROM master.sys.servers WHERE is_distributor = 1)
BEGIN
    EXEC master.dbo.sp_adddistributor
        @distributor = @ServerName,
        @password = @PublisherPassword,
        @encrypt_distributor_connection = N'mandatory',
        @trust_distributor_certificate = N'yes';
END;

IF DB_ID(N'distribution') IS NULL
BEGIN
    EXEC master.dbo.sp_adddistributiondb
        @database = N'distribution',
        @data_folder = N'/var/opt/mssql/data',
        @log_folder = N'/var/opt/mssql/data',
        @min_distretention = 0,
        @max_distretention = 72,
        @history_retention = 48,
        @security_mode = 0,
        @login = @PublisherLogin,
        @password = @PublisherPassword;
END;

EXEC master.dbo.xp_create_subdir N'/var/opt/mssql/repldata';

IF NOT EXISTS
(
    SELECT 1
    FROM distribution.sys.symmetric_keys
    WHERE name = N'##MS_DatabaseMasterKey##'
)
BEGIN
    SET @Sql = N'USE [distribution]; CREATE MASTER KEY ENCRYPTION BY PASSWORD = '
        + QUOTENAME(@PublisherPassword, N'''') + N';';
    EXEC sys.sp_executesql @Sql;
END;

IF NOT EXISTS
(
    SELECT 1
    FROM distribution.dbo.MSreplservers
    WHERE srvname = @ServerName
)
BEGIN
    EXEC master.dbo.sp_adddistpublisher
        @publisher = @ServerName,
        @distribution_db = N'distribution',
        @security_mode = 0,
        @login = @PublisherLogin,
        @password = @PublisherPassword,
        @working_directory = N'/var/opt/mssql/repldata',
        @trusted = N'false',
        @thirdparty_flag = 0,
        @publisher_type = N'MSSQLSERVER';
END;

EXEC master.dbo.sp_changedistpublisher
    @publisher = @ServerName,
    @property = N'security_mode',
    @value = N'0';
EXEC master.dbo.sp_changedistpublisher
    @publisher = @ServerName,
    @property = N'login',
    @value = @PublisherLogin;
EXEC master.dbo.sp_changedistpublisher
    @publisher = @ServerName,
    @property = N'password',
    @value = @PublisherPassword;

USE [distribution];

IF DATABASE_PRINCIPAL_ID(@PublisherLogin) IS NULL
BEGIN
    SET @Sql = N'CREATE USER ' + QUOTENAME(@PublisherLogin)
        + N' FOR LOGIN ' + QUOTENAME(@PublisherLogin) + N';';
    EXEC sys.sp_executesql @Sql;
END;

IF IS_ROLEMEMBER(N'db_owner', @PublisherLogin) <> 1
    EXEC sys.sp_addrolemember N'db_owner', @PublisherLogin;

USE [master];

/* Logins que solamente reciben cambios en la base activa de este nodo. */
IF @NodeCode IN ('SJ', 'LI')
BEGIN
    IF SUSER_ID(N'repl_recibe_catalogos') IS NULL
    BEGIN
        SET @Sql = N'CREATE LOGIN [repl_recibe_catalogos] WITH PASSWORD = '
            + QUOTENAME(@ReceiverCatalogPassword, N'''')
            + N', CHECK_POLICY = ON, CHECK_EXPIRATION = OFF;';
        EXEC sys.sp_executesql @Sql;
    END;
    ELSE
    BEGIN
        SET @Sql = N'ALTER LOGIN [repl_recibe_catalogos] WITH PASSWORD = '
            + QUOTENAME(@ReceiverCatalogPassword, N'''') + N';';
        EXEC sys.sp_executesql @Sql;
    END;

    USE [WideWorldImporters];
    IF DATABASE_PRINCIPAL_ID(N'repl_recibe_catalogos') IS NULL
        CREATE USER [repl_recibe_catalogos] FOR LOGIN [repl_recibe_catalogos];
    IF IS_ROLEMEMBER(N'db_owner', N'repl_recibe_catalogos') <> 1
        ALTER ROLE [db_owner] ADD MEMBER [repl_recibe_catalogos];
END;

IF @NodeCode = 'CORP'
BEGIN
    USE [master];

    IF SUSER_ID(N'repl_recibe_sj') IS NULL
    BEGIN
        SET @Sql = N'CREATE LOGIN [repl_recibe_sj] WITH PASSWORD = '
            + QUOTENAME(@ReceiverSjPassword, N'''')
            + N', CHECK_POLICY = ON, CHECK_EXPIRATION = OFF;';
        EXEC sys.sp_executesql @Sql;
    END;
    ELSE
    BEGIN
        SET @Sql = N'ALTER LOGIN [repl_recibe_sj] WITH PASSWORD = '
            + QUOTENAME(@ReceiverSjPassword, N'''') + N';';
        EXEC sys.sp_executesql @Sql;
    END;

    IF SUSER_ID(N'repl_recibe_li') IS NULL
    BEGIN
        SET @Sql = N'CREATE LOGIN [repl_recibe_li] WITH PASSWORD = '
            + QUOTENAME(@ReceiverLiPassword, N'''')
            + N', CHECK_POLICY = ON, CHECK_EXPIRATION = OFF;';
        EXEC sys.sp_executesql @Sql;
    END;
    ELSE
    BEGIN
        SET @Sql = N'ALTER LOGIN [repl_recibe_li] WITH PASSWORD = '
            + QUOTENAME(@ReceiverLiPassword, N'''') + N';';
        EXEC sys.sp_executesql @Sql;
    END;

    USE [WideWorldImporters];
    IF DATABASE_PRINCIPAL_ID(N'repl_recibe_sj') IS NULL
        CREATE USER [repl_recibe_sj] FOR LOGIN [repl_recibe_sj];
    IF DATABASE_PRINCIPAL_ID(N'repl_recibe_li') IS NULL
        CREATE USER [repl_recibe_li] FOR LOGIN [repl_recibe_li];
    IF IS_ROLEMEMBER(N'db_owner', N'repl_recibe_sj') <> 1
        ALTER ROLE [db_owner] ADD MEMBER [repl_recibe_sj];
    IF IS_ROLEMEMBER(N'db_owner', N'repl_recibe_li') <> 1
        ALTER ROLE [db_owner] ADD MEMBER [repl_recibe_li];
END;

USE [WideWorldImporters];

SELECT
    @@SERVERNAME AS ServerName,
    @NodeCode AS NodeCode,
    @PublisherLogin AS PublisherLogin,
    IS_ROLEMEMBER(N'db_owner', @PublisherLogin) AS PublisherIsDatabaseOwner,
    DB_ID(N'distribution') AS DistributionDatabaseId,
    N'DISTRIBUTOR_READY' AS Result;
