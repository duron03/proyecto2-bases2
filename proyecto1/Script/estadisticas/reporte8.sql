USE [WideWorldImporters];
GO

CREATE OR ALTER PROCEDURE dbo.usp_Estadisticas_Reporte8
    @Year int = NULL,
    @Month int = NULL,
    @StockGroupName nvarchar(100) = NULL,
    @SucursalID int = NULL
AS
BEGIN
    SET NOCOUNT ON;
    EXEC Seguridad.usp_ValidarAlcanceReporte @SucursalID OUTPUT;

    SELECT
        S.SupplierName,
        YEAR(PO.OrderDate) AS OrderYear,
        MONTH(PO.OrderDate) AS OrderMonth,
        SUM(POL.OrderedOuters * POL.ExpectedUnitPricePerOuter) AS TotalPurchasedAmount,
        MIN(PO.OrderDate) AS FirstOrderDate,
        MAX(PO.OrderDate) AS LastOrderDate,
        SUM(CONVERT(bigint, POL.OrderedOuters)) AS TotalQuantity,
        MIN(POL.OrderedOuters) AS MinQuantity,
        MAX(POL.OrderedOuters) AS MaxQuantity
    FROM Corporativo.v_PurchaseOrders AS PO
    INNER JOIN Corporativo.v_PurchaseOrderLines AS POL
        ON PO.SucursalID = POL.SucursalID
       AND PO.PurchaseOrderID = POL.PurchaseOrderID
    INNER JOIN Purchasing.Suppliers AS S ON PO.SupplierID = S.SupplierID
    WHERE (@SucursalID IS NULL OR PO.SucursalID = @SucursalID)
      AND (@Year IS NULL OR YEAR(PO.OrderDate) = @Year)
      AND (@Month IS NULL OR MONTH(PO.OrderDate) = @Month)
      AND
      (
          @StockGroupName IS NULL
          OR EXISTS
          (
              SELECT 1
              FROM Warehouse.StockItemStockGroups AS SISG
              INNER JOIN Warehouse.StockGroups AS SG
                  ON SISG.StockGroupID = SG.StockGroupID
              WHERE SISG.StockItemID = POL.StockItemID
                AND SG.StockGroupName LIKE N'%' + @StockGroupName + N'%'
          )
      )
    GROUP BY S.SupplierName, YEAR(PO.OrderDate), MONTH(PO.OrderDate)
    ORDER BY S.SupplierName, OrderYear DESC, OrderMonth DESC;
END;
GO
