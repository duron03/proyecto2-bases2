USE [WideWorldImporters];
GO

-- Sinónimos utilizados por el reporte 5.
IF OBJECT_ID('dbo.src_OrdenCompra', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_OrdenCompra FOR Purchasing.PurchaseOrders;');
GO

IF OBJECT_ID('dbo.src_Proveedor', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_Proveedor FOR Purchasing.Suppliers;');
GO

-- Muestra el Top 5 de proveedores con mayor cantidad de órdenes de compra por año.
CREATE OR ALTER PROCEDURE dbo.usp_Estadisticas_Reporte5
    @Year int = NULL,
    @SupplierName nvarchar(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        WITH CTE_Ordenes AS (
            SELECT
                YEAR(OC.OrderDate) AS OrderYear,
                P.SupplierName,
                COUNT(OC.PurchaseOrderID) AS OrderCount
            FROM dbo.src_OrdenCompra AS OC
            INNER JOIN dbo.src_Proveedor AS P
                ON OC.SupplierID = P.SupplierID
            WHERE
                (
                    @Year IS NULL
                    OR YEAR(OC.OrderDate) = @Year
                )
                AND
                (
                    @SupplierName IS NULL
                    OR P.SupplierName LIKE '%' + @SupplierName + '%'
                )
            GROUP BY
                YEAR(OC.OrderDate),
                P.SupplierName
        ),
        CTE_Ranking AS (
            SELECT
                OrderYear,
                SupplierName,
                OrderCount,
                DENSE_RANK() OVER (PARTITION BY OrderYear ORDER BY OrderCount DESC) AS SupplierRank
            FROM CTE_Ordenes
        )
        SELECT
            OrderYear,
            SupplierName,
            OrderCount,
            SupplierRank
        FROM CTE_Ranking
        WHERE SupplierRank <= 5
        ORDER BY
            OrderYear DESC,
            SupplierRank ASC;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO