USE [WideWorldImporters];
GO

-- Sinónimos utilizados por el reporte 8.
IF OBJECT_ID('dbo.src_OrdenCompra', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_OrdenCompra FOR Purchasing.PurchaseOrders;');
GO

IF OBJECT_ID('dbo.src_Proveedor', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_Proveedor FOR Purchasing.Suppliers;');
GO

IF OBJECT_ID('dbo.src_DetalleOrdenCompra', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_DetalleOrdenCompra FOR Purchasing.PurchaseOrderLines;');
GO

-- Muestra el seguimiento mensual de proveedores (Total comprado, fechas y cantidades).
CREATE OR ALTER PROCEDURE dbo.usp_Estadisticas_Reporte8
    @Year int = NULL,
    @Month int = NULL,
    @StockGroupName nvarchar(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT
            P.SupplierName,
            YEAR(OC.OrderDate) AS OrderYear,
            MONTH(OC.OrderDate) AS OrderMonth,
            SUM(OD.OrderedOuters * OD.ExpectedUnitPricePerOuter) AS TotalPurchasedAmount,
            MIN(OC.OrderDate) AS FirstOrderDate,
            MAX(OC.OrderDate) AS LastOrderDate,
            SUM(OD.OrderedOuters) AS TotalQuantity,
            MIN(OD.OrderedOuters) AS MinQuantity,
            MAX(OD.OrderedOuters) AS MaxQuantity
        FROM dbo.src_OrdenCompra AS OC
        INNER JOIN dbo.src_Proveedor AS P
            ON OC.SupplierID = P.SupplierID
        INNER JOIN dbo.src_DetalleOrdenCompra AS OD
            ON OC.PurchaseOrderID = OD.PurchaseOrderID
        INNER JOIN dbo.src_Producto AS SI
            ON OD.StockItemID = SI.StockItemID
        LEFT JOIN dbo.src_ProductoGrupo AS SISG
            ON SI.StockItemID = SISG.StockItemID
        LEFT JOIN dbo.src_GrupoProducto AS SG
            ON SISG.StockGroupID = SG.StockGroupID
        WHERE
            (
                @Year IS NULL
                OR YEAR(OC.OrderDate) = @Year
            )
            AND
            (
                @Month IS NULL
                OR MONTH(OC.OrderDate) = @Month
            )
            AND
            (
                @StockGroupName IS NULL
                OR SG.StockGroupName LIKE '%' + @StockGroupName + '%'
            )
        GROUP BY
            P.SupplierName,
            YEAR(OC.OrderDate),
            MONTH(OC.OrderDate)
        ORDER BY
            P.SupplierName ASC,
            OrderYear DESC,
            OrderMonth DESC;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO