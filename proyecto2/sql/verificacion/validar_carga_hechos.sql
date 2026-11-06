:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;

USE [WideWorldImporters];
GO

IF N'$(NodeCode)' NOT IN (N'SJ', N'LI')
    THROW 51340, N'NodeCode debe ser SJ o LI.', 1;

IF NOT EXISTS
(
    SELECT 1
    FROM Control.Nodo
    WHERE Id = 1
      AND Codigo = N'$(NodeCode)'
)
    THROW 51341, N'La identidad de la sucursal no coincide.', 1;

IF NOT EXISTS
(
    SELECT 1
    FROM Control.EstadoCatalogo
    WHERE Id = 1
      AND DatosValidados = 1
      AND ValidadoUtc IS NOT NULL
)
    THROW 51342, N'El catalogo local no fue validado.', 1;

IF N'$(NodeCode)' = N'SJ'
BEGIN
    IF (SELECT COUNT_BIG(*) FROM Sales.Orders) <> 36797
       OR (SELECT COUNT_BIG(*) FROM Sales.Invoices) <> 35254
       OR (SELECT COUNT_BIG(*) FROM Sales.InvoiceLines) <> 114208
       OR (SELECT COUNT_BIG(*) FROM Sales.CustomerTransactions) <> 48585
       OR (SELECT COUNT_BIG(*) FROM Purchasing.PurchaseOrders) <> 1037
       OR (SELECT COUNT_BIG(*) FROM Purchasing.PurchaseOrderLines) <> 4215
       OR (SELECT COUNT_BIG(*) FROM Purchasing.SupplierTransactions) <> 1218
       OR (SELECT COUNT_BIG(*) FROM Warehouse.StockItemHoldings) <> 228
        THROW 51343, N'Los conteos de hechos de San Jose no coinciden.', 1;
END;

IF N'$(NodeCode)' = N'LI'
BEGIN
    IF (SELECT COUNT_BIG(*) FROM Sales.Orders) <> 36798
       OR (SELECT COUNT_BIG(*) FROM Sales.Invoices) <> 35257
       OR (SELECT COUNT_BIG(*) FROM Sales.InvoiceLines) <> 114059
       OR (SELECT COUNT_BIG(*) FROM Sales.CustomerTransactions) <> 48562
       OR (SELECT COUNT_BIG(*) FROM Purchasing.PurchaseOrders) <> 1037
       OR (SELECT COUNT_BIG(*) FROM Purchasing.PurchaseOrderLines) <> 4152
       OR (SELECT COUNT_BIG(*) FROM Purchasing.SupplierTransactions) <> 1220
       OR (SELECT COUNT_BIG(*) FROM Warehouse.StockItemHoldings) <> 228
        THROW 51344, N'Los conteos de hechos de Limon no coinciden.', 1;
END;

IF EXISTS
(
    SELECT 1
    FROM sys.foreign_keys AS foreignKeyObject
    INNER JOIN sys.tables AS tableObject
        ON tableObject.object_id = foreignKeyObject.parent_object_id
    INNER JOIN sys.schemas AS schemaObject
        ON schemaObject.schema_id = tableObject.schema_id
    WHERE schemaObject.name IN (N'Sales', N'Purchasing', N'Warehouse')
      AND (foreignKeyObject.is_disabled = 1 OR foreignKeyObject.is_not_trusted = 1)
      AND foreignKeyObject.is_not_for_replication = 0
)
    THROW 51345, N'Una FK operativa esta deshabilitada o no es confiable.', 1;

IF EXISTS
(
    SELECT 1
    FROM Sales.Invoices
    WHERE CreditNoteReason IS NOT NULL
       OR Comments IS NOT NULL
       OR DeliveryInstructions IS NOT NULL
       OR InternalComments IS NOT NULL
       OR DeliveryRun IS NOT NULL
       OR RunPosition IS NOT NULL
       OR ReturnedDeliveryData IS NOT NULL
)
    THROW 51346, N'Una factura historica conserva un texto excluido por la matriz.', 1;

IF EXISTS
(
    SELECT 1
    FROM Warehouse.StockItemHoldings
    WHERE QuantityOnHand < 0
       OR LastStocktakeQuantity < 0
       OR LastCostPrice < 0
       OR ReorderLevel < 0
       OR TargetStockLevel < 0
       OR VersionExistencias <> 1
)
    THROW 51347, N'Una existencia inicial tiene cantidad, costo o version invalida.', 1;

IF EXISTS (SELECT 1 FROM Sales.Invoices WHERE InvoiceID >= 1000000000)
   OR EXISTS (SELECT 1 FROM Sales.InvoiceLines WHERE InvoiceLineID >= 1000000000)
    THROW 51348, N'La carga historica invadio los rangos de IDs nuevos.', 1;

SELECT
    @@SERVERNAME AS ServerName,
    N'$(NodeCode)' AS NodeCode,
    N'T04_FACTS_PASS' AS Result;
