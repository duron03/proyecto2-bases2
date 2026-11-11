USE [WideWorldImporters];
GO

CREATE OR ALTER PROCEDURE dbo.usp_Estadisticas_Reporte10
    @Year int = NULL,
    @Month int = NULL,
    @CustomerCategoryName nvarchar(50) = NULL,
    @StockGroupName nvarchar(100) = NULL,
    @StockItemName nvarchar(100) = NULL,
    @SucursalID int = NULL
AS
BEGIN
    SET NOCOUNT ON;
    EXEC Seguridad.usp_ValidarAlcanceReporte @SucursalID OUTPUT;

    ;WITH Facturas AS
    (
        SELECT DISTINCT
            I.SucursalID,
            I.InvoiceID,
            Ciu.CityName AS DeliveryCity,
            Prov.StateProvinceName AS DeliveryState,
            DM.DeliveryMethodName
        FROM Corporativo.v_Invoices AS I
        INNER JOIN Corporativo.v_InvoiceLines AS IL
            ON I.SucursalID = IL.SucursalID AND I.InvoiceID = IL.InvoiceID
        INNER JOIN Sales.Customers AS C ON I.CustomerID = C.CustomerID
        INNER JOIN Privado.Clientes AS PC ON C.CustomerID = PC.CustomerID
        INNER JOIN Application.Cities AS Ciu ON PC.DeliveryCityID = Ciu.CityID
        INNER JOIN Application.StateProvinces AS Prov
            ON Ciu.StateProvinceID = Prov.StateProvinceID
        INNER JOIN Application.DeliveryMethods AS DM
            ON I.DeliveryMethodID = DM.DeliveryMethodID
        INNER JOIN Sales.CustomerCategories AS CC
            ON C.CustomerCategoryID = CC.CustomerCategoryID
        INNER JOIN Warehouse.StockItems AS SI ON IL.StockItemID = SI.StockItemID
        WHERE (@SucursalID IS NULL OR I.SucursalID = @SucursalID)
          AND (@Year IS NULL OR YEAR(I.InvoiceDate) = @Year)
          AND (@Month IS NULL OR MONTH(I.InvoiceDate) = @Month)
          AND (@CustomerCategoryName IS NULL
               OR CC.CustomerCategoryName LIKE N'%' + @CustomerCategoryName + N'%')
          AND (@StockItemName IS NULL OR SI.StockItemName LIKE N'%' + @StockItemName + N'%')
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
    )
    SELECT DeliveryCity, DeliveryState, DeliveryMethodName,
        COUNT_BIG(*) AS SalesCount
    FROM Facturas
    GROUP BY DeliveryCity, DeliveryState, DeliveryMethodName
    ORDER BY SalesCount DESC, DeliveryCity;
END;
GO
