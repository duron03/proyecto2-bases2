:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;

USE [PilotoReplicacion];
GO

BEGIN TRANSACTION;

IF EXISTS (SELECT 1 FROM dbo.CatalogoPiloto WHERE Id IN (3, 4))
BEGIN
    ROLLBACK TRANSACTION;
    THROW 51023, N'Las filas del backlog ya existen.', 1;
END;

INSERT INTO dbo.CatalogoPiloto
    (Id, Nombre, VersionCatalogo, Activo, LastEditedWhen)
VALUES
    (3, N'Backlog paso 1', 1, 1, SYSUTCDATETIME()),
    (4, N'Backlog fila temporal', 1, 1, SYSUTCDATETIME());

UPDATE dbo.CatalogoPiloto
SET Nombre = N'Backlog paso 2',
    VersionCatalogo = 2,
    LastEditedWhen = SYSUTCDATETIME()
WHERE Id = 3;

UPDATE dbo.CatalogoPiloto
SET Nombre = N'Backlog final',
    VersionCatalogo = 3,
    LastEditedWhen = SYSUTCDATETIME()
WHERE Id = 3;

DELETE FROM dbo.CatalogoPiloto WHERE Id = 4;

COMMIT TRANSACTION;

SELECT Id, Nombre, VersionCatalogo
FROM dbo.CatalogoPiloto
WHERE Id IN (3, 4)
ORDER BY Id;

