USE [WideWorldImporters];
GO

CREATE OR ALTER PROCEDURE dbo.usp_Estadisticas_Reporte1
    @SupplierName nvarchar(100) = NULL,
    @SupplierCategoryName nvarchar(50) = NULL,
    @SucursalID int = NULL
AS
BEGIN
    SET NOCOUNT ON;
    EXEC Seguridad.usp_ValidarAlcanceReporte @SucursalID OUTPUT;

    ;WITH Base AS
    (
        SELECT S.SupplierName, SC.SupplierCategoryName, ST.TransactionAmount
        FROM Corporativo.v_PurchaseOrders AS PO
        INNER JOIN Corporativo.v_SupplierTransactions AS ST
            ON PO.SucursalID = ST.SucursalID
           AND PO.PurchaseOrderID = ST.PurchaseOrderID
        INNER JOIN Purchasing.Suppliers AS S ON PO.SupplierID = S.SupplierID
        INNER JOIN Purchasing.SupplierCategories AS SC
            ON S.SupplierCategoryID = SC.SupplierCategoryID
        WHERE (@SucursalID IS NULL OR PO.SucursalID = @SucursalID)
          AND (@SupplierName IS NULL OR S.SupplierName LIKE N'%' + @SupplierName + N'%')
          AND (@SupplierCategoryName IS NULL
               OR SC.SupplierCategoryName LIKE N'%' + @SupplierCategoryName + N'%')
    )
    SELECT
        CASE WHEN GROUPING(SupplierName) = 1
            THEN N'TOTAL PER SUPPLIER' ELSE SupplierName END AS SupplierName,
        CASE WHEN GROUPING(SupplierName) = 1 THEN N' '
             WHEN GROUPING(SupplierCategoryName) = 1
                THEN CONCAT(N'TOTAL - ', UPPER(SupplierName))
             ELSE SupplierCategoryName END AS SupplierCategoryName,
        MAX(TransactionAmount) AS MaxSupplierPurchase,
        MIN(TransactionAmount) AS MinSupplierPurchase,
        AVG(TransactionAmount) AS AvgSupplierPurchase
    FROM Base
    GROUP BY ROLLUP (SupplierName, SupplierCategoryName);
END;
GO
