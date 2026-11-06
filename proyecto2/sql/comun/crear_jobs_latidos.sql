:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;

USE [WideWorldImporters];
GO

DECLARE @NodeCode varchar(4) = '$(NodeCode)';
DECLARE @JobName sysname;
DECLARE @StepCommand nvarchar(max);

IF @NodeCode NOT IN ('CORP', 'SJ', 'LI')
    THROW 51540, N'NodeCode debe ser CORP, SJ o LI.', 1;

IF NOT EXISTS (SELECT 1 FROM Control.Nodo WHERE Id = 1 AND Codigo = @NodeCode)
    THROW 51541, N'La identidad del nodo no coincide.', 1;

IF @NodeCode = 'CORP'
BEGIN
    SET @JobName = N'P2_Latido_Catalogo';
    SET @StepCommand = N'
        SET NOCOUNT ON;
        UPDATE Control.LatidoCatalogo
        SET FechaUtc = SYSUTCDATETIME()
        WHERE Id = 1;';
END;
ELSE
BEGIN
    SET @JobName = N'P2_Latido_Sucursal_' + @NodeCode;
    SET @StepCommand = N'
        SET NOCOUNT ON;
        UPDATE Control.LatidoSucursal
        SET FechaUtc = SYSUTCDATETIME()
        WHERE SucursalID = ' + CASE @NodeCode WHEN 'SJ' THEN N'1' ELSE N'2' END + N';';
END;

IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = @JobName)
BEGIN
    EXEC msdb.dbo.sp_add_job
        @job_name = @JobName,
        @enabled = 1,
        @description = N'Senal UTC de avance para el proyecto distribuido';

    EXEC msdb.dbo.sp_add_jobstep
        @job_name = @JobName,
        @step_name = N'Actualizar latido',
        @subsystem = N'TSQL',
        @database_name = N'WideWorldImporters',
        @command = @StepCommand,
        @on_success_action = 1,
        @on_fail_action = 2;

    EXEC msdb.dbo.sp_add_schedule
        @schedule_name = @JobName,
        @enabled = 1,
        @freq_type = 4,
        @freq_interval = 1,
        @freq_subday_type = 2,
        @freq_subday_interval = 15,
        @active_start_time = 0;

    EXEC msdb.dbo.sp_attach_schedule
        @job_name = @JobName,
        @schedule_name = @JobName;

    EXEC msdb.dbo.sp_add_jobserver
        @job_name = @JobName;
END;
ELSE
BEGIN
    EXEC msdb.dbo.sp_update_job
        @job_name = @JobName,
        @enabled = 1;
END;

IF NOT EXISTS
(
    SELECT 1
    FROM msdb.dbo.sysjobactivity AS activityObject
    INNER JOIN msdb.dbo.sysjobs AS jobObject
        ON jobObject.job_id = activityObject.job_id
    WHERE jobObject.name = @JobName
      AND activityObject.session_id = (SELECT MAX(session_id) FROM msdb.dbo.syssessions)
      AND activityObject.start_execution_date IS NOT NULL
      AND activityObject.stop_execution_date IS NULL
)
    EXEC msdb.dbo.sp_start_job @job_name = @JobName;

SELECT
    @@SERVERNAME AS ServerName,
    @NodeCode AS NodeCode,
    @JobName AS JobName,
    N'HEARTBEAT_JOB_READY' AS Result;
