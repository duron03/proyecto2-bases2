:on error exit
SET NOCOUNT ON;

USE [PilotoReplicacion];
GO

SELECT @@SERVERNAME AS ServerName, N'CatalogoPiloto' AS Tabla, Id, Nombre, VersionCatalogo, Activo
FROM dbo.CatalogoPiloto
ORDER BY Id;

IF @@SERVERNAME = N'wwi-corp'
BEGIN
    SELECT @@SERVERNAME AS ServerName, N'sj.OperacionPiloto' AS Tabla, Id, Descripcion
    FROM sj.OperacionPiloto
    ORDER BY Id;

    SELECT @@SERVERNAME AS ServerName, N'limon.OperacionPiloto' AS Tabla, Id, Descripcion
    FROM limon.OperacionPiloto
    ORDER BY Id;
END;

