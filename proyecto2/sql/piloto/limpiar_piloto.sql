:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF N'$(Confirm)' <> N'ELIMINAR_SOLO_PILOTO'
    THROW 51090, N'Falta la confirmacion ELIMINAR_SOLO_PILOTO.', 1;

IF N'$(NodeCode)' NOT IN (N'CORP', N'SJ', N'LI')
    THROW 51091, N'NodeCode debe ser CORP, SJ o LI.', 1;

IF DB_ID(N'PilotoReplicacion') IS NULL
BEGIN
    SELECT @@SERVERNAME AS ServerName, N'PILOT_ALREADY_ABSENT' AS Result;
    RETURN;
END;

USE [PilotoReplicacion];

DECLARE @Publication sysname =
    CASE N'$(NodeCode)'
        WHEN N'CORP' THEN N'P2_Piloto_Catalogos'
        WHEN N'SJ' THEN N'P2_Piloto_Operacion_SJ'
        ELSE N'P2_Piloto_Operacion_LI'
    END;

IF EXISTS (SELECT 1 FROM syspublications WHERE name = @Publication)
BEGIN
    EXEC dbo.sp_dropsubscription
        @publication = @Publication,
        @article = N'all',
        @subscriber = N'all',
        @destination_db = N'all';

    EXEC dbo.sp_droppublication
        @publication = @Publication;
END;

USE [master];

EXEC master.dbo.sp_replicationdboption
    @dbname = N'PilotoReplicacion',
    @optname = N'publish',
    @value = N'false';

ALTER DATABASE [PilotoReplicacion] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE [PilotoReplicacion];

SELECT
    @@SERVERNAME AS ServerName,
    N'$(NodeCode)' AS NodeCode,
    N'PILOT_REMOVED' AS Result;
