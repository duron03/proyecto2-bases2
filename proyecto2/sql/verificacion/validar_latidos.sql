:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;

USE [WideWorldImporters];
GO

DECLARE @NodeCode varchar(4) = '$(NodeCode)';
DECLARE @AgeSeconds int;

IF @NodeCode = 'CORP'
BEGIN
    IF NOT EXISTS
    (
        SELECT 1
        FROM sj.LatidoSucursal
        WHERE SucursalID = 1
          AND DATEDIFF(second, FechaUtc, SYSUTCDATETIME()) BETWEEN 0 AND 60
    )
       OR NOT EXISTS
    (
        SELECT 1
        FROM limon.LatidoSucursal
        WHERE SucursalID = 2
          AND DATEDIFF(second, FechaUtc, SYSUTCDATETIME()) BETWEEN 0 AND 60
    )
        THROW 51380, N'CORP no tiene latidos recientes de ambas sucursales.', 1;
END;
ELSE
BEGIN
    IF @NodeCode NOT IN ('SJ', 'LI')
        THROW 51381, N'NodeCode debe ser CORP, SJ o LI.', 1;

    SELECT @AgeSeconds = DATEDIFF(second, FechaUtc, SYSUTCDATETIME())
    FROM Control.LatidoCatalogo
    WHERE Id = 1;

    IF @AgeSeconds IS NULL OR @AgeSeconds NOT BETWEEN 0 AND 60
        THROW 51382, N'La sucursal no tiene un latido reciente del catalogo.', 1;
END;

SELECT
    @@SERVERNAME AS ServerName,
    @NodeCode AS NodeCode,
    N'HEARTBEAT_REPLICATION_PASS' AS Result;
