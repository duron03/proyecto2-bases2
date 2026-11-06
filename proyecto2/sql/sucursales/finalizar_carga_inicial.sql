:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

USE [WideWorldImporters];
GO

IF N'$(NodeCode)' NOT IN (N'SJ', N'LI')
    THROW 51350, N'NodeCode debe ser SJ o LI.', 1;

IF NOT EXISTS
(
    SELECT 1
    FROM Control.Nodo
    WHERE Id = 1
      AND Codigo = N'$(NodeCode)'
)
    THROW 51351, N'La identidad de la sucursal no coincide.', 1;

ALTER TABLE Sales.Orders WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE Purchasing.PurchaseOrders WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE Sales.Invoices WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE Sales.InvoiceLines WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE Purchasing.PurchaseOrderLines WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE Sales.CustomerTransactions WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE Purchasing.SupplierTransactions WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE Warehouse.StockItemHoldings WITH CHECK CHECK CONSTRAINT ALL;

IF EXISTS
(
    SELECT 1
    FROM sys.foreign_keys AS foreignKeyObject
    INNER JOIN sys.tables AS tableObject
        ON tableObject.object_id = foreignKeyObject.parent_object_id
    INNER JOIN sys.schemas AS schemaObject
        ON schemaObject.schema_id = tableObject.schema_id
    WHERE schemaObject.name IN (N'Sales', N'Purchasing', N'Warehouse')
      AND foreignKeyObject.is_not_for_replication = 0
      AND (foreignKeyObject.is_disabled = 1 OR foreignKeyObject.is_not_trusted = 1)
)
    THROW 51352, N'Una FK operativa no pudo quedar confiable.', 1;

SELECT
    @@SERVERNAME AS ServerName,
    N'$(NodeCode)' AS NodeCode,
    N'INITIAL_FACT_LOAD_FINALIZED' AS Result;
