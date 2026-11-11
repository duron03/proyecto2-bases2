:on error exit
SET NOCOUNT ON;

USE [master];
GO

IF DB_ID(N'WWI_Origen') IS NOT NULL
BEGIN
    THROW 51100, N'WWI_Origen ya existe. No se restaura encima automaticamente.', 1;
END;

RESTORE DATABASE [WWI_Origen]
FROM DISK = N'/var/opt/mssql/backup/P2_WideWorldImporters_20261105.bak'
WITH
    MOVE N'WWI_Primary' TO N'/var/opt/mssql/data/WWI_Origen_Primary.mdf',
    MOVE N'WWI_UserData' TO N'/var/opt/mssql/data/WWI_Origen_UserData.ndf',
    MOVE N'WWI_Log' TO N'/var/opt/mssql/data/WWI_Origen_Log.ldf',
    MOVE N'WWI_InMemory_Data_1' TO N'/var/opt/mssql/data/WWI_Origen_InMemory_Data_1',
    CHECKSUM,
    RECOVERY,
    STATS = 10;

ALTER DATABASE [WWI_Origen] SET READ_ONLY WITH NO_WAIT;

SELECT
    name AS DatabaseName,
    state_desc AS StateDescription,
    user_access_desc AS UserAccess,
    is_read_only AS IsReadOnly,
    compatibility_level AS CompatibilityLevel
FROM sys.databases
WHERE name = N'WWI_Origen';

