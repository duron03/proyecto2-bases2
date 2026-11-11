:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;

USE [WideWorldImporters];
GO

EXEC Corporativo.usp_ActualizarResumenVentas;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM Control.EstadoMaterializacion
    WHERE Id = 1
      AND EstadoUltimoIntento = 'correcto'
      AND UltimoExitoUtc IS NOT NULL
      AND LatidoSJUsadoUtc IS NOT NULL
      AND LatidoLIUsadoUtc IS NOT NULL
)
    THROW 51620, 'La materializacion no termino correctamente.', 1;

SELECT
    I.SucursalID,
    YEAR(I.InvoiceDate) AS Anio,
    MONTH(I.InvoiceDate) AS Mes,
    COUNT_BIG(DISTINCT I.InvoiceID) AS CantidadFacturas,
    SUM(CONVERT(bigint, IL.Quantity)) AS CantidadUnidades,
    SUM(CONVERT(decimal(38, 2), IL.ExtendedPrice - IL.TaxAmount)) AS MontoSinImpuesto,
    SUM(CONVERT(decimal(38, 2), IL.TaxAmount)) AS Impuestos,
    SUM(CONVERT(decimal(38, 2), IL.ExtendedPrice)) AS MontoTotal,
    SUM(CONVERT(decimal(38, 2), IL.LineProfit)) AS Utilidad
INTO #Esperado
FROM Corporativo.v_Invoices AS I
INNER JOIN Corporativo.v_InvoiceLines AS IL
    ON I.SucursalID = IL.SucursalID
   AND I.InvoiceID = IL.InvoiceID
GROUP BY I.SucursalID, YEAR(I.InvoiceDate), MONTH(I.InvoiceDate);

IF EXISTS
(
    SELECT SucursalID, Anio, Mes, CantidadFacturas, CantidadUnidades,
        MontoSinImpuesto, Impuestos, MontoTotal, Utilidad
    FROM #Esperado
    EXCEPT
    SELECT SucursalID, Anio, Mes, CantidadFacturas, CantidadUnidades,
        MontoSinImpuesto, Impuestos, MontoTotal, Utilidad
    FROM Corporativo.ResumenVentasMensuales
)
OR EXISTS
(
    SELECT SucursalID, Anio, Mes, CantidadFacturas, CantidadUnidades,
        MontoSinImpuesto, Impuestos, MontoTotal, Utilidad
    FROM Corporativo.ResumenVentasMensuales
    EXCEPT
    SELECT SucursalID, Anio, Mes, CantidadFacturas, CantidadUnidades,
        MontoSinImpuesto, Impuestos, MontoTotal, Utilidad
    FROM #Esperado
)
    THROW 51621, 'El resumen no coincide con las facturas y lineas recibidas.', 1;

SELECT
    COUNT(*) AS FilasResumen,
    SUM(CantidadFacturas) AS FacturasAgrupadas,
    MAX(UltimoExitoUtc) AS UltimoExitoUtc
FROM Corporativo.ResumenVentasMensuales
CROSS JOIN Control.EstadoMaterializacion
WHERE Id = 1;

DROP TABLE #Esperado;
GO

SELECT N'MATERIALIZACION_VALIDADA' AS Result;
GO
