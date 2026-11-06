:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @JobId uniqueidentifier;
DECLARE @StepId int;
DECLARE @Subsystem nvarchar(40);
DECLARE @Command nvarchar(max);

DECLARE agent_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT
        jobObject.job_id,
        stepObject.step_id,
        stepObject.subsystem,
        stepObject.command
    FROM msdb.dbo.sysjobs AS jobObject
    INNER JOIN msdb.dbo.sysjobsteps AS stepObject
        ON stepObject.job_id = jobObject.job_id
    WHERE stepObject.subsystem IN (N'Snapshot', N'LogReader', N'Distribution')
      AND stepObject.command LIKE N'%WideWorldImporters%';

OPEN agent_cursor;
FETCH NEXT FROM agent_cursor INTO @JobId, @StepId, @Subsystem, @Command;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF @Command NOT LIKE N'%-EncryptionLevel%'
        SET @Command = @Command + N' -EncryptionLevel 1';

    IF @Subsystem IN (N'LogReader', N'Distribution')
       AND @Command NOT LIKE N'%-PollingInterval%'
        SET @Command = @Command + N' -PollingInterval 1';

    EXEC msdb.dbo.sp_update_jobstep
        @job_id = @JobId,
        @step_id = @StepId,
        @command = @Command;

    FETCH NEXT FROM agent_cursor INTO @JobId, @StepId, @Subsystem, @Command;
END;

CLOSE agent_cursor;
DEALLOCATE agent_cursor;

SELECT
    @@SERVERNAME AS ServerName,
    stepObject.subsystem AS AgentType,
    CASE WHEN stepObject.command LIKE N'%-EncryptionLevel 1%' THEN 1 ELSE 0 END AS TlsConfigured,
    CASE
        WHEN stepObject.subsystem = N'Snapshot' THEN NULL
        WHEN stepObject.command LIKE N'%-PollingInterval 1%' THEN 1
        ELSE 0
    END AS PollingOneSecond
FROM msdb.dbo.sysjobs AS jobObject
INNER JOIN msdb.dbo.sysjobsteps AS stepObject
    ON stepObject.job_id = jobObject.job_id
WHERE stepObject.subsystem IN (N'Snapshot', N'LogReader', N'Distribution')
  AND stepObject.command LIKE N'%WideWorldImporters%'
ORDER BY AgentType, jobObject.name;
