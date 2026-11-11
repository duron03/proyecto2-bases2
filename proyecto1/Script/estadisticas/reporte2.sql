USE [WideWorldImporters];
GO

CREATE OR ALTER PROCEDURE dbo.usp_Estadisticas_Reporte2
    @CustomerName nvarchar(100) = NULL,
    @CustomerCategoryName nvarchar(50) = NULL,
    @SucursalID int = NULL
AS
BEGIN
    SET NOCOUNT ON;
    EXEC Seguridad.usp_ValidarAlcanceReporte @SucursalID OUTPUT;

    ;WITH Base AS
    (
        SELECT C.CustomerName, CC.CustomerCategoryName, CT.TransactionAmount
        FROM Corporativo.v_Invoices AS I
        INNER JOIN Corporativo.v_CustomerTransactions AS CT
            ON I.SucursalID = CT.SucursalID
           AND I.InvoiceID = CT.InvoiceID
        INNER JOIN Sales.Customers AS C ON I.CustomerID = C.CustomerID
        INNER JOIN Sales.CustomerCategories AS CC
            ON C.CustomerCategoryID = CC.CustomerCategoryID
        WHERE (@SucursalID IS NULL OR I.SucursalID = @SucursalID)
          AND (@CustomerName IS NULL OR C.CustomerName LIKE N'%' + @CustomerName + N'%')
          AND (@CustomerCategoryName IS NULL
               OR CC.CustomerCategoryName LIKE N'%' + @CustomerCategoryName + N'%')
    )
    SELECT
        CASE WHEN GROUPING(CustomerName) = 1
            THEN N'TOTAL PER CUSTOMER' ELSE CustomerName END AS CustomerName,
        CASE WHEN GROUPING(CustomerName) = 1 THEN N' '
             WHEN GROUPING(CustomerCategoryName) = 1
                THEN CONCAT(N'TOTAL - ', UPPER(CustomerName))
             ELSE CustomerCategoryName END AS CustomerCategoryName,
        MAX(TransactionAmount) AS MaxAmount,
        MIN(TransactionAmount) AS MinAmount,
        AVG(TransactionAmount) AS AvgPurchase
    FROM Base
    GROUP BY ROLLUP (CustomerName, CustomerCategoryName);
END;
GO
