:on error exit
SET NOCOUNT ON;

SELECT
    @@SERVERNAME AS ServerName,
    CAST(SERVERPROPERTY(N'ProductVersion') AS nvarchar(50)) AS ProductVersion,
    CAST(SERVERPROPERTY(N'ProductLevel') AS nvarchar(50)) AS ProductLevel,
    CAST(SERVERPROPERTY(N'Edition') AS nvarchar(100)) AS Edition;

SELECT
    servicename,
    status_desc,
    startup_type_desc
FROM sys.dm_server_services
WHERE servicename LIKE N'SQL Server Agent%';

SELECT
    name,
    is_distributor,
    is_publisher,
    is_subscriber
FROM master.sys.servers
ORDER BY server_id;

IF DB_ID(N'distribution') IS NOT NULL
BEGIN
    SELECT columnObject.name AS MSreplserversColumn
    FROM distribution.sys.columns AS columnObject
    WHERE columnObject.object_id = OBJECT_ID(N'distribution.dbo.MSreplservers')
    ORDER BY columnObject.column_id;

    SELECT
        jobObject.name AS JobName,
        jobStep.step_id AS StepId,
        jobStep.subsystem AS Subsystem
    FROM msdb.dbo.sysjobs AS jobObject
    INNER JOIN msdb.dbo.sysjobsteps AS jobStep
        ON jobStep.job_id = jobObject.job_id
    WHERE jobObject.name LIKE N'%PilotoReplicacion%'
    ORDER BY jobObject.name, jobStep.step_id;
END;

SELECT
    procedureObject.name AS ProcedureName,
    procedureParameter.name AS ParameterName,
    procedureParameter.parameter_id
FROM master.sys.all_objects AS procedureObject
INNER JOIN master.sys.all_parameters AS procedureParameter
    ON procedureParameter.object_id = procedureObject.object_id
WHERE procedureObject.name IN
(
    N'sp_adddistributor',
    N'sp_adddistributiondb',
    N'sp_adddistpublisher',
    N'sp_changedistpublisher'
)
ORDER BY procedureObject.name, procedureParameter.parameter_id;

