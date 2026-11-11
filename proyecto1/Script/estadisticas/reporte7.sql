USE [WideWorldImporters];
GO

CREATE OR ALTER PROCEDURE dbo.usp_Estadisticas_Reporte7
    @Year int = NULL,
    @Month int = NULL,
    @StockGroupName nvarchar(100) = NULL,
    @SucursalID int = NULL
AS
BEGIN
    SET NOCOUNT ON;
    EXEC Seguridad.usp_ValidarAlcanceReporte @SucursalID OUTPUT;

    SELECT
        C.CustomerName,
        YEAR(I.InvoiceDate) AS InvoiceYear,
        MONTH(I.InvoiceDate) AS InvoiceMonth,
        SUM(IL.ExtendedPrice) AS TotalPurchasedAmount,
        MIN(I.InvoiceDate) AS FirstInvoiceDate,
        MAX(I.InvoiceDate) AS LastInvoiceDate,
        SUM(CONVERT(bigint, IL.Quantity)) AS TotalQuantity,
        MIN(IL.Quantity) AS MinQuantity,
        MAX(IL.Quantity) AS MaxQuantity
    FROM Corporativo.v_Invoices AS I
    INNER JOIN Corporativo.v_InvoiceLines AS IL
        ON I.SucursalID = IL.SucursalID AND I.InvoiceID = IL.InvoiceID
    INNER JOIN Sales.Customers AS C ON I.CustomerID = C.CustomerID
    WHERE (@SucursalID IS NULL OR I.SucursalID = @SucursalID)
      AND (@Year IS NULL OR YEAR(I.InvoiceDate) = @Year)
      AND (@Month IS NULL OR MONTH(I.InvoiceDate) = @Month)
      AND
      (
          @StockGroupName IS NULL
          OR EXISTS
          (
              SELECT 1
              FROM Warehouse.StockItemStockGroups AS SISG
              INNER JOIN Warehouse.StockGroups AS SG
                  ON SISG.StockGroupID = SG.StockGroupID
              WHERE SISG.StockItemID = IL.StockItemID
                AND SG.StockGroupName LIKE N'%' + @StockGroupName + N'%'
          )
      )
    GROUP BY C.CustomerName, YEAR(I.InvoiceDate), MONTH(I.InvoiceDate)
    ORDER BY C.CustomerName, InvoiceYear DESC, InvoiceMonth DESC;
END;
GO
