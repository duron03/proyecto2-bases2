:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;

USE [distribution];
GO

DECLARE @JobId uniqueidentifier;
DECLARE @StepId int;
DECLARE @Command nvarchar(max);

DECLARE agent_job_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT
        jobObject.job_id,
        jobStep.step_id,
        jobStep.command
    FROM msdb.dbo.sysjobs AS jobObject
    INNER JOIN msdb.dbo.sysjobsteps AS jobStep
        ON jobStep.job_id = jobObject.job_id
    WHERE jobObject.name LIKE N'%PilotoReplicacion%'
      AND jobStep.subsystem IN (N'Snapshot', N'LogReader', N'Distribution');

OPEN agent_job_cursor;
FETCH NEXT FROM agent_job_cursor INTO @JobId, @StepId, @Command;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF @Command NOT LIKE N'%-EncryptionLevel%'
    BEGIN
        SET @Command = @Command + N' -EncryptionLevel 1';

        EXEC msdb.dbo.sp_update_jobstep
            @job_id = @JobId,
            @step_id = @StepId,
            @command = @Command;
    END;

    FETCH NEXT FROM agent_job_cursor INTO @JobId, @StepId, @Command;
END;

CLOSE agent_job_cursor;
DEALLOCATE agent_job_cursor;

SELECT
    jobObject.name AS JobName,
    jobStep.subsystem AS AgentType,
    CASE
        WHEN jobStep.command LIKE N'%-EncryptionLevel 1%' THEN 1
        ELSE 0
    END AS EncryptionLevelConfigured
FROM msdb.dbo.sysjobs AS jobObject
INNER JOIN msdb.dbo.sysjobsteps AS jobStep
    ON jobStep.job_id = jobObject.job_id
WHERE jobObject.name LIKE N'%PilotoReplicacion%'
  AND jobStep.subsystem IN (N'Snapshot', N'LogReader', N'Distribution')
ORDER BY AgentType, JobName;

