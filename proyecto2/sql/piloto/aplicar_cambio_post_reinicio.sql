:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;

USE [PilotoReplicacion];
GO

IF N'$(NodeCode)' = N'CORP'
BEGIN
    UPDATE dbo.CatalogoPiloto
    SET Nombre = N'Catalogo despues del reinicio',
        VersionCatalogo = 4,
        LastEditedWhen = SYSUTCDATETIME()
    WHERE Id = 3;

    IF @@ROWCOUNT <> 1
        THROW 51026, N'No se encontro el catalogo persistido despues del reinicio.', 1;
END;
ELSE IF N'$(NodeCode)' IN (N'SJ', N'LI')
BEGIN
    UPDATE dbo.OperacionPiloto
    SET Descripcion = CONCAT(N'Operacion despues del reinicio ', N'$(NodeCode)'),
        LastEditedWhen = SYSUTCDATETIME()
    WHERE Id = 77;

    IF @@ROWCOUNT <> 1
        THROW 51027, N'No se encontro la operacion persistida despues del reinicio.', 1;
END;
ELSE
BEGIN
    THROW 51028, N'NodeCode debe ser CORP, SJ o LI.', 1;
END;

SELECT N'$(NodeCode)' AS NodeCode, N'POST_RESTART_APPLIED' AS Result;

