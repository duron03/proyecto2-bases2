:on error exit
SET NOCOUNT ON;

USE [WideWorldImporters];
GO

SELECT CustomerID, CustomerName, Activo, VersionCatalogo
FROM Sales.Customers
WHERE CustomerName LIKE N'P2_DEMO_%'
ORDER BY CustomerID;

SELECT SupplierID, SupplierName, Activo, VersionCatalogo
FROM Purchasing.Suppliers
WHERE SupplierName LIKE N'P2_DEMO_%'
ORDER BY SupplierID;

SELECT StockItemID, StockItemName, Activo, VersionCatalogo
FROM Warehouse.StockItems
WHERE StockItemName LIKE N'P2_DEMO_%'
ORDER BY StockItemID;
GO
