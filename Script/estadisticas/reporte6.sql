USE [WideWorldImporters];
GO

-- Sinónimos utilizados por el reporte 4.
IF OBJECT_ID('dbo.src_Factura', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_Factura FOR Sales.Invoices;');
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

-- Muestra una matriz cruzando las categorías de productos con los años de venta.
CREATE OR ALTER PROCEDURE dbo.usp_Estadisticas_Reporte6
    @StockGroupName nvarchar(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        WITH CTE_BaseData AS (
            SELECT
                ISNULL(SG.StockGroupName, 'No Category') AS StockGroupName,
                YEAR(I.InvoiceDate) AS InvoiceYear,
                IL.ExtendedPrice
            FROM dbo.src_Factura AS I
            INNER JOIN dbo.src_DetalleFactura AS IL
                ON I.InvoiceID = IL.InvoiceID
            INNER JOIN dbo.src_Producto AS SI
                ON IL.StockItemID = SI.StockItemID
            LEFT JOIN dbo.src_ProductoGrupo AS SISG
                ON SI.StockItemID = SISG.StockItemID
            LEFT JOIN dbo.src_GrupoProducto AS SG
                ON SISG.StockGroupID = SG.StockGroupID
            WHERE
                (
                    @StockGroupName IS NULL
                    OR SG.StockGroupName LIKE '%' + @StockGroupName + '%'
                )
        )
        SELECT 
            StockGroupName,
            ISNULL([2013], 0) AS Sales_2013,
            ISNULL([2014], 0) AS Sales_2014,
            ISNULL([2015], 0) AS Sales_2015,
            ISNULL([2016], 0) AS Sales_2016,
            (ISNULL([2013], 0) + ISNULL([2014], 0) + ISNULL([2015], 0) + ISNULL([2016], 0)) AS GrandTotal
        FROM CTE_BaseData
        PIVOT (
            SUM(ExtendedPrice)
            FOR InvoiceYear IN ([2013], [2014], [2015], [2016])
        ) AS PivotMatrix
        ORDER BY 
            GrandTotal DESC;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO