:on error exit
SET NOCOUNT ON;

DECLARE @Action varchar(5) = '$(Action)';
DECLARE @Jobs TABLE (JobName sysname PRIMARY KEY);

IF @Action NOT IN ('STOP', 'START')
    THROW 51098, N'Action debe ser STOP o START.', 1;

INSERT INTO @Jobs (JobName)
SELECT name
FROM msdb.dbo.sysjobs
WHERE name IN
(
    N'wwi-corp-WideWorldImporters-P2_Catalogos-WWI-SJ-1006',
    N'wwi-corp-WideWorldImporters-P2_Catalogos-WWI-LIMON-1007'
);

IF (SELECT COUNT(*) FROM @Jobs) <> 2
    THROW 51099, N'No se encontraron los dos Distribution Agents definitivos.', 1;

DECLARE @JobName sysname;
DECLARE job_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT JobName FROM @Jobs;

OPEN job_cursor;
FETCH NEXT FROM job_cursor INTO @JobName;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF @Action = 'STOP'
        EXEC msdb.dbo.sp_stop_job @job_name = @JobName;
    ELSE
        EXEC msdb.dbo.sp_start_job @job_name = @JobName;

    FETCH NEXT FROM job_cursor INTO @JobName;
END;

CLOSE job_cursor;
DEALLOCATE job_cursor;

SELECT @Action AS ActionName, COUNT(*) AS JobCount, N'CATALOG_AGENTS_CONTROLLED' AS Result
FROM @Jobs;
