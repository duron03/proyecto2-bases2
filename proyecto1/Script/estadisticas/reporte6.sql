USE [WideWorldImporters];
GO

-- Matriz historica fija de 2013 a 2016, igual que en el proyecto anterior.
CREATE OR ALTER PROCEDURE dbo.usp_Estadisticas_Reporte6
    @StockGroupName nvarchar(100) = NULL,
    @SucursalID int = NULL
AS
BEGIN
    SET NOCOUNT ON;
    EXEC Seguridad.usp_ValidarAlcanceReporte @SucursalID OUTPUT;

    ;WITH Base AS
    (
        SELECT
            COALESCE(SG.StockGroupName, N'No Category') AS StockGroupName,
            YEAR(I.InvoiceDate) AS InvoiceYear,
            IL.ExtendedPrice
        FROM Corporativo.v_Invoices AS I
        INNER JOIN Corporativo.v_InvoiceLines AS IL
            ON I.SucursalID = IL.SucursalID AND I.InvoiceID = IL.InvoiceID
        INNER JOIN Warehouse.StockItems AS SI ON IL.StockItemID = SI.StockItemID
        LEFT JOIN Warehouse.StockItemStockGroups AS SISG
            ON SI.StockItemID = SISG.StockItemID
        LEFT JOIN Warehouse.StockGroups AS SG ON SISG.StockGroupID = SG.StockGroupID
        WHERE (@SucursalID IS NULL OR I.SucursalID = @SucursalID)
          AND (@StockGroupName IS NULL OR SG.StockGroupName LIKE N'%' + @StockGroupName + N'%')
    )
    SELECT
        StockGroupName,
        COALESCE([2013], 0) AS Sales_2013,
        COALESCE([2014], 0) AS Sales_2014,
        COALESCE([2015], 0) AS Sales_2015,
        COALESCE([2016], 0) AS Sales_2016,
        COALESCE([2013], 0) + COALESCE([2014], 0)
            + COALESCE([2015], 0) + COALESCE([2016], 0) AS GrandTotal
    FROM Base
    PIVOT
    (
        SUM(ExtendedPrice) FOR InvoiceYear IN ([2013], [2014], [2015], [2016])
    ) AS Matriz
    ORDER BY GrandTotal DESC, StockGroupName;
END;
GO
