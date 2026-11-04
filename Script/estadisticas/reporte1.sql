USE [WideWorldImporters];
GO

-- Sinónimos utilizados por el reporte 1.
IF OBJECT_ID('dbo.src_OrdenCompra', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_OrdenCompra FOR Purchasing.PurchaseOrders;');
GO

IF OBJECT_ID('dbo.src_Proveedor', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_Proveedor FOR Purchasing.Suppliers;');
GO

IF OBJECT_ID('dbo.src_CategoriaProveedor', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_CategoriaProveedor FOR Purchasing.SupplierCategories;');
GO

IF OBJECT_ID('dbo.src_TransaccionProveedor', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_TransaccionProveedor FOR Purchasing.SupplierTransactions;');
GO

-- Muestra las compras máximas, mínimas y promedio por proveedor y categoría.
CREATE OR ALTER PROCEDURE dbo.usp_Estadisticas_Reporte1
    @SupplierName nvarchar(100) = NULL,
    @SupplierCategoryName nvarchar(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT
            CASE
                WHEN GROUPING(S.SupplierName) = 1
                    THEN 'TOTAL PER SUPPLIER'
                ELSE S.SupplierName
            END AS SupplierName,
            CASE
                WHEN GROUPING(S.SupplierName) <> 1
                    THEN
                        CASE
                            WHEN GROUPING(SC.SupplierCategoryName) = 1
                                THEN CONCAT('TOTAL', ' - ', UPPER(S.SupplierName))
                            ELSE SC.SupplierCategoryName
                        END
                ELSE ' '
            END AS SupplierCategoryName,
            MAX(ST.TransactionAmount) AS MaxSupplierPurchase,
            MIN(ST.TransactionAmount) AS MinSupplierPurchase,
            AVG(ST.TransactionAmount) AS AvgSupplierPurchase
        FROM dbo.src_OrdenCompra AS PO
        INNER JOIN dbo.src_Proveedor AS S
            ON PO.SupplierID = S.SupplierID
        INNER JOIN dbo.src_CategoriaProveedor AS SC
            ON S.SupplierCategoryID = SC.SupplierCategoryID
        INNER JOIN dbo.src_TransaccionProveedor AS ST
            ON PO.PurchaseOrderID = ST.PurchaseOrderID
        WHERE
            (
                @SupplierName IS NULL
                OR S.SupplierName LIKE '%' + @SupplierName + '%'
            )
            AND
            (
                @SupplierCategoryName IS NULL
                OR SC.SupplierCategoryName LIKE '%' + @SupplierCategoryName + '%'
            )
        GROUP BY ROLLUP
        (
            S.SupplierName,
            SC.SupplierCategoryName
        );

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO
