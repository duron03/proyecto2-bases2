:on error exit
SET NOCOUNT ON;

USE [WideWorldImporters];
GO

IF OBJECT_ID(N'dbo.src_Factura', N'SN') IS NOT NULL DROP SYNONYM dbo.src_Factura;
CREATE SYNONYM dbo.src_Factura FOR Sales.Invoices;

IF OBJECT_ID(N'dbo.src_DetalleFactura', N'SN') IS NOT NULL DROP SYNONYM dbo.src_DetalleFactura;
CREATE SYNONYM dbo.src_DetalleFactura FOR Sales.InvoiceLines;

IF OBJECT_ID(N'dbo.src_TransaccionCliente', N'SN') IS NOT NULL DROP SYNONYM dbo.src_TransaccionCliente;
CREATE SYNONYM dbo.src_TransaccionCliente FOR Sales.CustomerTransactions;

IF OBJECT_ID(N'dbo.src_OrdenCompra', N'SN') IS NOT NULL DROP SYNONYM dbo.src_OrdenCompra;
CREATE SYNONYM dbo.src_OrdenCompra FOR Purchasing.PurchaseOrders;

IF OBJECT_ID(N'dbo.src_DetalleOrdenCompra', N'SN') IS NOT NULL DROP SYNONYM dbo.src_DetalleOrdenCompra;
CREATE SYNONYM dbo.src_DetalleOrdenCompra FOR Purchasing.PurchaseOrderLines;

IF OBJECT_ID(N'dbo.src_TransaccionProveedor', N'SN') IS NOT NULL DROP SYNONYM dbo.src_TransaccionProveedor;
CREATE SYNONYM dbo.src_TransaccionProveedor FOR Purchasing.SupplierTransactions;

IF OBJECT_ID(N'dbo.src_Existencia', N'SN') IS NOT NULL DROP SYNONYM dbo.src_Existencia;
CREATE SYNONYM dbo.src_Existencia FOR Warehouse.StockItemHoldings;

SELECT name AS SynonymName, base_object_name AS TargetObject
FROM sys.synonyms
WHERE name LIKE N'src[_]%'
ORDER BY name;

