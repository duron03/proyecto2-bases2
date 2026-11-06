:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

USE [WideWorldImporters];
GO

IF N'$(Confirm)' <> N'RECUPERAR_CARGA_INICIAL'
    THROW 51330, N'Falta la confirmacion RECUPERAR_CARGA_INICIAL.', 1;

IF N'$(NodeCode)' NOT IN (N'SJ', N'LI')
    THROW 51331, N'NodeCode debe ser SJ o LI.', 1;

IF NOT EXISTS
(
    SELECT 1
    FROM Control.Nodo
    WHERE Id = 1
      AND Codigo = N'$(NodeCode)'
)
    THROW 51332, N'El script se intento ejecutar en otra sucursal.', 1;

IF EXISTS
(
    SELECT 1
    FROM distribution.dbo.MSpublications
    WHERE publisher_db = N'WideWorldImporters'
      AND publication IN (N'P2_Operacion_SJ', N'P2_Operacion_LI')
)
    THROW 51333, N'No se limpia una carga que ya tiene publicacion de hechos.', 1;

BEGIN TRANSACTION;

DELETE FROM Sales.CustomerTransactions;
DELETE FROM Sales.InvoiceLines;
DELETE FROM Sales.Invoices;
DELETE FROM Sales.Orders;

DELETE FROM Purchasing.SupplierTransactions;
DELETE FROM Purchasing.PurchaseOrderLines;
DELETE FROM Purchasing.PurchaseOrders;

DELETE FROM Warehouse.StockItemHoldings;

COMMIT TRANSACTION;

SELECT
    @@SERVERNAME AS ServerName,
    N'$(NodeCode)' AS NodeCode,
    N'INITIAL_FACT_LOAD_CLEARED' AS Result;
