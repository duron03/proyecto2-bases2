:on error exit
SET NOCOUNT ON;

USE [PilotoReplicacion];
GO

IF N'$(NodeCode)' IN (N'SJ', N'LI')
BEGIN
    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.CatalogoPiloto
        WHERE Id = 3
          AND Nombre = N'Catalogo despues del reinicio'
          AND VersionCatalogo = 4
    )
        THROW 51029, N'El catalogo post-reinicio no llego a la sucursal.', 1;
END;
ELSE IF N'$(NodeCode)' = N'CORP'
BEGIN
    IF NOT EXISTS
    (
        SELECT 1
        FROM sj.OperacionPiloto
        WHERE Id = 77
          AND Descripcion = N'Operacion despues del reinicio SJ'
    )
        THROW 51030, N'La operacion post-reinicio de SJ no llego a CORP.', 1;

    IF NOT EXISTS
    (
        SELECT 1
        FROM limon.OperacionPiloto
        WHERE Id = 77
          AND Descripcion = N'Operacion despues del reinicio LI'
    )
        THROW 51031, N'La operacion post-reinicio de LI no llego a CORP.', 1;
END;
ELSE
BEGIN
    THROW 51032, N'NodeCode debe ser CORP, SJ o LI.', 1;
END;

SELECT N'$(NodeCode)' AS NodeCode, N'PASS' AS PostRestartResult;

