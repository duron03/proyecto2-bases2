USE [WideWorldImporters];
GO

-- Sinónimos utilizados por el reporte 10.
IF OBJECT_ID('dbo.src_Factura', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_Factura FOR Sales.Invoices;');
GO
IF OBJECT_ID('dbo.src_Cliente', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_Cliente FOR Sales.Customers;');
GO
IF OBJECT_ID('dbo.src_DetalleFactura', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_DetalleFactura FOR Sales.InvoiceLines;');
GO
IF OBJECT_ID('dbo.src_Producto', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_Producto FOR Warehouse.StockItems;');
GO
IF OBJECT_ID('dbo.src_ProductoGrupo', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_ProductoGrupo FOR Warehouse.StockItemStockGroups;');
GO
IF OBJECT_ID('dbo.src_GrupoProducto', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_GrupoProducto FOR Warehouse.StockGroups;');
GO
IF OBJECT_ID('dbo.src_MetodoEntrega', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_MetodoEntrega FOR Application.DeliveryMethods;');
GO
IF OBJECT_ID('dbo.src_Ciudad', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_Ciudad FOR Application.Cities;');
GO
IF OBJECT_ID('dbo.src_Provincia', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_Provincia FOR Application.StateProvinces;');
GO
IF OBJECT_ID('dbo.src_CategoriaCliente', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_CategoriaCliente FOR Sales.CustomerCategories;');
GO

CREATE OR ALTER PROCEDURE dbo.usp_Estadisticas_Reporte10
    @Year int = NULL,
    @Month int = NULL,
    @CustomerCategoryName nvarchar(50) = NULL,
    @StockGroupName nvarchar(100) = NULL,
    @StockItemName nvarchar(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT 
            Ciu.CityName AS DeliveryCity,
            Prov.StateProvinceName AS DeliveryState,
            ME.DeliveryMethodName,
            COUNT(DISTINCT I.InvoiceID) AS SalesCount
        FROM dbo.src_Factura AS I
        INNER JOIN dbo.src_Cliente AS C 
            ON I.CustomerID = C.CustomerID
        INNER JOIN dbo.src_Ciudad AS Ciu 
            ON C.DeliveryCityID = Ciu.CityID
        INNER JOIN dbo.src_Provincia AS Prov 
            ON Ciu.StateProvinceID = Prov.StateProvinceID
        INNER JOIN dbo.src_MetodoEntrega AS ME 
            ON I.DeliveryMethodID = ME.DeliveryMethodID
        INNER JOIN dbo.src_CategoriaCliente AS CC 
            ON C.CustomerCategoryID = CC.CustomerCategoryID
        INNER JOIN dbo.src_DetalleFactura AS IL 
            ON I.InvoiceID = IL.InvoiceID
        INNER JOIN dbo.src_Producto AS SI 
            ON IL.StockItemID = SI.StockItemID
        LEFT JOIN dbo.src_ProductoGrupo AS SISG 
            ON SI.StockItemID = SISG.StockItemID
        LEFT JOIN dbo.src_GrupoProducto AS SG 
            ON SISG.StockGroupID = SG.StockGroupID
        WHERE 
            (@Year IS NULL OR YEAR(I.InvoiceDate) = @Year)
            AND (@Month IS NULL OR MONTH(I.InvoiceDate) = @Month)
            AND (@CustomerCategoryName IS NULL OR CC.CustomerCategoryName LIKE '%' + @CustomerCategoryName + '%')
            AND (@StockGroupName IS NULL OR SG.StockGroupName LIKE '%' + @StockGroupName + '%')
            AND (@StockItemName IS NULL OR SI.StockItemName LIKE '%' + @StockItemName + '%')
        GROUP BY 
            Ciu.CityName,
            Prov.StateProvinceName,
            ME.DeliveryMethodName
        ORDER BY 
            SalesCount DESC, 
            DeliveryCity ASC;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO