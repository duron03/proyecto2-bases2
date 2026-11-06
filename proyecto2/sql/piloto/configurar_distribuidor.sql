:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @ServerName sysname = N'$(ServerName)';
DECLARE @Password varchar(128) = CONVERT(varchar(128), CONVERT(varbinary(256), '$(PasswordHex)', 2));

IF @@SERVERNAME <> @ServerName
BEGIN
    THROW 51001, N'@@SERVERNAME no coincide con ServerName.', 1;
END;

IF NOT EXISTS (SELECT 1 FROM master.sys.servers WHERE is_distributor = 1)
BEGIN
    EXEC master.dbo.sp_adddistributor
        @distributor = @ServerName,
        @password = @Password,
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
        @login = N'sa',
        @password = @Password;
END;

EXEC master.dbo.xp_create_subdir N'/var/opt/mssql/repldata';

IF NOT EXISTS
(
    SELECT 1
    FROM distribution.sys.symmetric_keys
    WHERE name = N'##MS_DatabaseMasterKey##'
)
BEGIN
    DECLARE @CreateMasterKey nvarchar(1000);

    SET @CreateMasterKey =
        N'USE [distribution]; CREATE MASTER KEY ENCRYPTION BY PASSWORD = '
        + QUOTENAME(@Password, N'''')
        + N';';

    EXEC sys.sp_executesql @CreateMasterKey;
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
        @login = N'sa',
        @password = @Password,
        @working_directory = N'/var/opt/mssql/repldata',
        @trusted = N'false',
        @thirdparty_flag = 0,
        @publisher_type = N'MSSQLSERVER';
END;

EXEC master.dbo.sp_changedistpublisher
    @publisher = @ServerName,
    @property = N'password',
    @value = @Password;

SELECT
    @@SERVERNAME AS ServerName,
    DB_ID(N'distribution') AS DistributionDatabaseId,
    N'/var/opt/mssql/repldata' AS SnapshotDirectory;

