:on error exit
SET NOCOUNT ON;

USE [WideWorldImporters];
GO

IF OBJECT_ID(N'dbo.src_Cliente', N'SN') IS NOT NULL DROP SYNONYM dbo.src_Cliente;
CREATE SYNONYM dbo.src_Cliente FOR Sales.Customers;

IF OBJECT_ID(N'dbo.src_CategoriaCliente', N'SN') IS NOT NULL DROP SYNONYM dbo.src_CategoriaCliente;
CREATE SYNONYM dbo.src_CategoriaCliente FOR Sales.CustomerCategories;

IF OBJECT_ID(N'dbo.src_GrupoCompra', N'SN') IS NOT NULL DROP SYNONYM dbo.src_GrupoCompra;
CREATE SYNONYM dbo.src_GrupoCompra FOR Sales.BuyingGroups;

IF OBJECT_ID(N'dbo.src_Proveedor', N'SN') IS NOT NULL DROP SYNONYM dbo.src_Proveedor;
CREATE SYNONYM dbo.src_Proveedor FOR Purchasing.Suppliers;

IF OBJECT_ID(N'dbo.src_CategoriaProveedor', N'SN') IS NOT NULL DROP SYNONYM dbo.src_CategoriaProveedor;
CREATE SYNONYM dbo.src_CategoriaProveedor FOR Purchasing.SupplierCategories;

IF OBJECT_ID(N'dbo.src_Persona', N'SN') IS NOT NULL DROP SYNONYM dbo.src_Persona;
CREATE SYNONYM dbo.src_Persona FOR Application.People;

IF OBJECT_ID(N'dbo.src_MetodoEntrega', N'SN') IS NOT NULL DROP SYNONYM dbo.src_MetodoEntrega;
CREATE SYNONYM dbo.src_MetodoEntrega FOR Application.DeliveryMethods;

IF OBJECT_ID(N'dbo.src_Producto', N'SN') IS NOT NULL DROP SYNONYM dbo.src_Producto;
CREATE SYNONYM dbo.src_Producto FOR Warehouse.StockItems;

IF OBJECT_ID(N'dbo.src_GrupoProducto', N'SN') IS NOT NULL DROP SYNONYM dbo.src_GrupoProducto;
CREATE SYNONYM dbo.src_GrupoProducto FOR Warehouse.StockGroups;

IF OBJECT_ID(N'dbo.src_ProductoGrupo', N'SN') IS NOT NULL DROP SYNONYM dbo.src_ProductoGrupo;
CREATE SYNONYM dbo.src_ProductoGrupo FOR Warehouse.StockItemStockGroups;

IF OBJECT_ID(N'dbo.src_Color', N'SN') IS NOT NULL DROP SYNONYM dbo.src_Color;
CREATE SYNONYM dbo.src_Color FOR Warehouse.Colors;

IF OBJECT_ID(N'dbo.src_TipoEmpaque', N'SN') IS NOT NULL DROP SYNONYM dbo.src_TipoEmpaque;
CREATE SYNONYM dbo.src_TipoEmpaque FOR Warehouse.PackageTypes;

SELECT name AS SynonymName, base_object_name AS TargetObject
FROM sys.synonyms
WHERE name LIKE N'src[_]%'
ORDER BY name;

