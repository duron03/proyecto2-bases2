:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;

USE [WideWorldImporters];
GO

DECLARE @JobName sysname = N'P2_Resumen_Ventas_Mensuales';
DECLARE @ScheduleName sysname = N'P2_Resumen_Cada_Minuto';

IF OBJECT_ID(N'Corporativo.usp_ActualizarResumenVentas', N'P') IS NULL
    THROW 50503, 'Primero debe instalarse el procedimiento de materializacion.', 1;

IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = @JobName)
BEGIN
    EXEC msdb.dbo.sp_add_job
        @job_name = @JobName,
        @enabled = 1,
        @description = N'Actualiza el resumen fisico de ventas del proyecto 2';

    EXEC msdb.dbo.sp_add_jobstep
        @job_name = @JobName,
        @step_name = N'Actualizar resumen',
        @subsystem = N'TSQL',
        @database_name = N'WideWorldImporters',
        @command = N'EXEC Corporativo.usp_ActualizarResumenVentas;',
        @on_success_action = 1,
        @on_fail_action = 2;

    EXEC msdb.dbo.sp_add_jobserver @job_name = @JobName;
END
ELSE
BEGIN
    EXEC msdb.dbo.sp_update_job @job_name = @JobName, @enabled = 1;
END;

IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysschedules WHERE name = @ScheduleName)
BEGIN
    EXEC msdb.dbo.sp_add_schedule
        @schedule_name = @ScheduleName,
        @enabled = 1,
        @freq_type = 4,
        @freq_interval = 1,
        @freq_subday_type = 4,
        @freq_subday_interval = 1,
        @active_start_time = 0;
END;

IF NOT EXISTS
(
    SELECT 1
    FROM msdb.dbo.sysjobschedules AS JS
    INNER JOIN msdb.dbo.sysjobs AS J ON JS.job_id = J.job_id
    INNER JOIN msdb.dbo.sysschedules AS S ON JS.schedule_id = S.schedule_id
    WHERE J.name = @JobName AND S.name = @ScheduleName
)
    EXEC msdb.dbo.sp_attach_schedule
        @job_name = @JobName,
        @schedule_name = @ScheduleName;

IF NOT EXISTS
(
    SELECT 1
    FROM msdb.dbo.sysjobactivity AS A
    INNER JOIN msdb.dbo.sysjobs AS J ON A.job_id = J.job_id
    WHERE J.name = @JobName
      AND A.session_id = (SELECT MAX(session_id) FROM msdb.dbo.syssessions)
      AND A.start_execution_date IS NOT NULL
      AND A.stop_execution_date IS NULL
)
    EXEC msdb.dbo.sp_start_job @job_name = @JobName;

SELECT @JobName AS JobName, N'RESUMEN_JOB_READY' AS Result;
GO

