USE [WideWorldImporters];
GO

-- Sinónimos utilizados por el reporte 7.
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

-- Muestra el seguimiento mensual de clientes (Total comprado, fechas y cantidades).
CREATE OR ALTER PROCEDURE dbo.usp_Estadisticas_Reporte7
    @Year int = NULL,
    @Month int = NULL,
    @StockGroupName nvarchar(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT
            C.CustomerName,
            YEAR(I.InvoiceDate) AS InvoiceYear,
            MONTH(I.InvoiceDate) AS InvoiceMonth,
            SUM(IL.ExtendedPrice) AS TotalPurchasedAmount,
            MIN(I.InvoiceDate) AS FirstInvoiceDate,
            MAX(I.InvoiceDate) AS LastInvoiceDate,
            SUM(IL.Quantity) AS TotalQuantity,
            MIN(IL.Quantity) AS MinQuantity,
            MAX(IL.Quantity) AS MaxQuantity
        FROM dbo.src_Factura AS I
        INNER JOIN dbo.src_Cliente AS C
            ON I.CustomerID = C.CustomerID
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
                @Year IS NULL
                OR YEAR(I.InvoiceDate) = @Year
            )
            AND
            (
                @Month IS NULL
                OR MONTH(I.InvoiceDate) = @Month
            )
            AND
            (
                @StockGroupName IS NULL
                OR SG.StockGroupName LIKE '%' + @StockGroupName + '%'
            )
        GROUP BY
            C.CustomerName,
            YEAR(I.InvoiceDate),
            MONTH(I.InvoiceDate)
        ORDER BY
            C.CustomerName ASC,
            InvoiceYear DESC,
            InvoiceMonth DESC;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO