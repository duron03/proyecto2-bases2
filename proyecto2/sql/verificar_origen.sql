:on error exit
SET NOCOUNT ON;

USE [master];
GO

SELECT
    @@SERVERNAME AS ServerName,
    CAST(SERVERPROPERTY(N'ProductVersion') AS nvarchar(50)) AS ProductVersion,
    CAST(SERVERPROPERTY(N'ProductLevel') AS nvarchar(50)) AS ProductLevel,
    CAST(SERVERPROPERTY(N'Edition') AS nvarchar(100)) AS Edition,
    SERVERPROPERTY(N'EngineEdition') AS EngineEdition;

SELECT
    name AS DatabaseName,
    state_desc AS Estado,
    recovery_model_desc AS RecoveryModel,
    is_read_only AS IsReadOnly,
    is_published AS IsPublished,
    is_subscribed AS IsSubscribed
FROM sys.databases
ORDER BY name;

IF DB_ID(N'WWI_Origen') IS NULL
BEGIN
    THROW 51101, N'WWI_Origen no existe. Restaure y verifique el respaldo antes de T02.', 1;
END;

IF (SELECT is_read_only FROM sys.databases WHERE name = N'WWI_Origen') <> 1
BEGIN
    THROW 51102, N'WWI_Origen debe permanecer en modo READ_ONLY.', 1;
END;
GO

USE [WWI_Origen];
GO

SELECT
    schemaObject.name AS SchemaName,
    tableObject.name AS TableName,
    tableObject.temporal_type_desc AS TemporalType,
    SUM(partitionObject.rows) AS TotalFilas
FROM sys.tables AS tableObject
INNER JOIN sys.schemas AS schemaObject
    ON schemaObject.schema_id = tableObject.schema_id
LEFT JOIN sys.partitions AS partitionObject
    ON partitionObject.object_id = tableObject.object_id
   AND partitionObject.index_id IN (0, 1)
WHERE
    (schemaObject.name = N'Application' AND tableObject.name IN
        (N'People', N'Cities', N'StateProvinces', N'Countries', N'DeliveryMethods', N'PaymentMethods', N'TransactionTypes'))
    OR (schemaObject.name = N'Sales' AND tableObject.name IN
        (N'Customers', N'CustomerCategories', N'BuyingGroups', N'Invoices', N'InvoiceLines', N'CustomerTransactions', N'Orders'))
    OR (schemaObject.name = N'Purchasing' AND tableObject.name IN
        (N'Suppliers', N'SupplierCategories', N'PurchaseOrders', N'PurchaseOrderLines', N'SupplierTransactions'))
    OR (schemaObject.name = N'Warehouse' AND tableObject.name IN
        (N'StockItems', N'StockItemStockGroups', N'StockGroups', N'Colors', N'PackageTypes', N'StockItemHoldings'))
GROUP BY schemaObject.name, tableObject.name, tableObject.temporal_type_desc
ORDER BY schemaObject.name, tableObject.name;

SELECT N'Application.People' AS Tabla, COUNT_BIG(*) AS Filas, MIN(PersonID) AS MinId, MAX(PersonID) AS MaxId
FROM Application.People
UNION ALL
SELECT N'Sales.Customers', COUNT_BIG(*), MIN(CustomerID), MAX(CustomerID) FROM Sales.Customers
UNION ALL
SELECT N'Purchasing.Suppliers', COUNT_BIG(*), MIN(SupplierID), MAX(SupplierID) FROM Purchasing.Suppliers
UNION ALL
SELECT N'Warehouse.StockItems', COUNT_BIG(*), MIN(StockItemID), MAX(StockItemID) FROM Warehouse.StockItems
UNION ALL
SELECT N'Warehouse.StockItemStockGroups', COUNT_BIG(*), MIN(StockItemStockGroupID), MAX(StockItemStockGroupID) FROM Warehouse.StockItemStockGroups
UNION ALL
SELECT N'Sales.Orders', COUNT_BIG(*), MIN(OrderID), MAX(OrderID) FROM Sales.Orders
UNION ALL
SELECT N'Sales.Invoices', COUNT_BIG(*), MIN(InvoiceID), MAX(InvoiceID) FROM Sales.Invoices
UNION ALL
SELECT N'Sales.InvoiceLines', COUNT_BIG(*), MIN(InvoiceLineID), MAX(InvoiceLineID) FROM Sales.InvoiceLines
UNION ALL
SELECT N'Sales.CustomerTransactions', COUNT_BIG(*), MIN(CustomerTransactionID), MAX(CustomerTransactionID) FROM Sales.CustomerTransactions
UNION ALL
SELECT N'Purchasing.PurchaseOrders', COUNT_BIG(*), MIN(PurchaseOrderID), MAX(PurchaseOrderID) FROM Purchasing.PurchaseOrders
UNION ALL
SELECT N'Purchasing.PurchaseOrderLines', COUNT_BIG(*), MIN(PurchaseOrderLineID), MAX(PurchaseOrderLineID) FROM Purchasing.PurchaseOrderLines
UNION ALL
SELECT N'Purchasing.SupplierTransactions', COUNT_BIG(*), MIN(SupplierTransactionID), MAX(SupplierTransactionID) FROM Purchasing.SupplierTransactions
UNION ALL
SELECT N'Warehouse.StockItemHoldings', COUNT_BIG(*), MIN(StockItemID), MAX(StockItemID) FROM Warehouse.StockItemHoldings;

IF (SELECT MAX(InvoiceID) FROM Sales.Invoices) >= 1000000000
    THROW 51103, N'InvoiceID historico invade el rango reservado para nuevas sedes.', 1;

IF (SELECT MAX(InvoiceLineID) FROM Sales.InvoiceLines) >= 1000000000
    THROW 51104, N'InvoiceLineID historico invade el rango reservado para nuevas sedes.', 1;

IF EXISTS
(
    SELECT 1
    FROM Sales.Invoices AS invoiceObject
    LEFT JOIN Sales.Orders AS orderObject
        ON orderObject.OrderID = invoiceObject.OrderID
    WHERE invoiceObject.OrderID IS NOT NULL
      AND orderObject.OrderID IS NULL
)
    THROW 51105, N'Existe una factura con OrderID huerfano.', 1;

IF EXISTS
(
    SELECT 1
    FROM Sales.InvoiceLines AS lineObject
    LEFT JOIN Sales.Invoices AS invoiceObject
        ON invoiceObject.InvoiceID = lineObject.InvoiceID
    WHERE invoiceObject.InvoiceID IS NULL
)
    THROW 51106, N'Existe una linea de factura huerfana.', 1;

IF EXISTS
(
    SELECT 1
    FROM Purchasing.PurchaseOrderLines AS lineObject
    LEFT JOIN Purchasing.PurchaseOrders AS orderObject
        ON orderObject.PurchaseOrderID = lineObject.PurchaseOrderID
    WHERE orderObject.PurchaseOrderID IS NULL
)
    THROW 51107, N'Existe una linea de compra huerfana.', 1;

IF EXISTS
(
    SELECT 1
    FROM Sales.CustomerTransactions AS transactionObject
    LEFT JOIN Sales.Invoices AS invoiceObject
        ON invoiceObject.InvoiceID = transactionObject.InvoiceID
    WHERE transactionObject.InvoiceID IS NOT NULL
      AND invoiceObject.InvoiceID IS NULL
)
    THROW 51108, N'Existe una transaccion de cliente con factura huerfana.', 1;

IF EXISTS
(
    SELECT 1
    FROM Purchasing.SupplierTransactions AS transactionObject
    LEFT JOIN Purchasing.PurchaseOrders AS orderObject
        ON orderObject.PurchaseOrderID = transactionObject.PurchaseOrderID
    WHERE transactionObject.PurchaseOrderID IS NOT NULL
      AND orderObject.PurchaseOrderID IS NULL
)
    THROW 51109, N'Existe una transaccion de proveedor con compra huerfana.', 1;

IF EXISTS
(
    SELECT 1
    FROM Warehouse.StockItemHoldings
    WHERE QuantityOnHand < 0
       OR LastStocktakeQuantity < 0
       OR LastCostPrice < 0
       OR ReorderLevel < 0
       OR TargetStockLevel < 0
)
    THROW 51110, N'Existen cantidades o costos negativos que impiden el reparto inicial.', 1;

SELECT
    SUM(CONVERT(bigint, QuantityOnHand)) AS QuantityOnHandTotal,
    SUM(CONVERT(bigint, LastStocktakeQuantity)) AS LastStocktakeTotal,
    SUM(CONVERT(bigint, ReorderLevel)) AS ReorderLevelTotal,
    SUM(CONVERT(bigint, TargetStockLevel)) AS TargetStockLevelTotal
FROM Warehouse.StockItemHoldings;

WITH Pedidos AS
(
    SELECT
        OrderID,
        CASE WHEN OrderID % 2 = 0 THEN 1 ELSE 2 END AS SucursalID
    FROM Sales.Orders
),
Facturas AS
(
    SELECT
        invoiceObject.InvoiceID,
        CASE
            WHEN invoiceObject.OrderID IS NOT NULL THEN orderObject.SucursalID
            WHEN invoiceObject.InvoiceID % 2 = 0 THEN 1
            ELSE 2
        END AS SucursalID
    FROM Sales.Invoices AS invoiceObject
    LEFT JOIN Pedidos AS orderObject
        ON orderObject.OrderID = invoiceObject.OrderID
),
Compras AS
(
    SELECT
        PurchaseOrderID,
        CASE WHEN PurchaseOrderID % 2 = 0 THEN 1 ELSE 2 END AS SucursalID
    FROM Purchasing.PurchaseOrders
),
Conteos AS
(
    SELECT N'Sales.Orders' AS Tabla, SucursalID, COUNT_BIG(*) AS Filas
    FROM Pedidos GROUP BY SucursalID

    UNION ALL

    SELECT N'Sales.Invoices', SucursalID, COUNT_BIG(*)
    FROM Facturas GROUP BY SucursalID

    UNION ALL

    SELECT N'Sales.InvoiceLines', invoiceObject.SucursalID, COUNT_BIG(*)
    FROM Sales.InvoiceLines AS lineObject
    INNER JOIN Facturas AS invoiceObject
        ON invoiceObject.InvoiceID = lineObject.InvoiceID
    GROUP BY invoiceObject.SucursalID

    UNION ALL

    SELECT
        N'Sales.CustomerTransactions',
        CASE
            WHEN transactionObject.InvoiceID IS NOT NULL THEN invoiceObject.SucursalID
            WHEN transactionObject.CustomerTransactionID % 2 = 0 THEN 1
            ELSE 2
        END,
        COUNT_BIG(*)
    FROM Sales.CustomerTransactions AS transactionObject
    LEFT JOIN Facturas AS invoiceObject
        ON invoiceObject.InvoiceID = transactionObject.InvoiceID
    GROUP BY
        CASE
            WHEN transactionObject.InvoiceID IS NOT NULL THEN invoiceObject.SucursalID
            WHEN transactionObject.CustomerTransactionID % 2 = 0 THEN 1
            ELSE 2
        END

    UNION ALL

    SELECT N'Purchasing.PurchaseOrders', SucursalID, COUNT_BIG(*)
    FROM Compras GROUP BY SucursalID

    UNION ALL

    SELECT N'Purchasing.PurchaseOrderLines', orderObject.SucursalID, COUNT_BIG(*)
    FROM Purchasing.PurchaseOrderLines AS lineObject
    INNER JOIN Compras AS orderObject
        ON orderObject.PurchaseOrderID = lineObject.PurchaseOrderID
    GROUP BY orderObject.SucursalID

    UNION ALL

    SELECT
        N'Purchasing.SupplierTransactions',
        CASE
            WHEN transactionObject.PurchaseOrderID IS NOT NULL THEN orderObject.SucursalID
            WHEN transactionObject.SupplierTransactionID % 2 = 0 THEN 1
            ELSE 2
        END,
        COUNT_BIG(*)
    FROM Purchasing.SupplierTransactions AS transactionObject
    LEFT JOIN Compras AS orderObject
        ON orderObject.PurchaseOrderID = transactionObject.PurchaseOrderID
    GROUP BY
        CASE
            WHEN transactionObject.PurchaseOrderID IS NOT NULL THEN orderObject.SucursalID
            WHEN transactionObject.SupplierTransactionID % 2 = 0 THEN 1
            ELSE 2
        END
)
SELECT Tabla, SucursalID, Filas
FROM Conteos
ORDER BY Tabla, SucursalID;

SELECT N'PASS' AS PreflightResult;

