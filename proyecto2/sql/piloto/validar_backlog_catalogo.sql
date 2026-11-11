:on error exit
SET NOCOUNT ON;

USE [PilotoReplicacion];
GO

IF NOT EXISTS
(
    SELECT 1
    FROM dbo.CatalogoPiloto
    WHERE Id = 3
      AND Nombre = N'Backlog final'
      AND VersionCatalogo = 3
)
BEGIN
    THROW 51024, N'El estado final del backlog no ha llegado.', 1;
END;

IF EXISTS (SELECT 1 FROM dbo.CatalogoPiloto WHERE Id = 4)
BEGIN
    THROW 51025, N'La fila temporal eliminada quedo en el destino.', 1;
END;

SELECT @@SERVERNAME AS ServerName, N'PASS' AS BacklogResult;

