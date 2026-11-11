USE [WideWorldImporters];
GO

CREATE OR ALTER PROCEDURE dbo.usp_Estadisticas_Reporte3
    @Year int = NULL,
    @StockItemName nvarchar(100) = NULL,
    @SucursalID int = NULL
AS
BEGIN
    SET NOCOUNT ON;
    EXEC Seguridad.usp_ValidarAlcanceReporte @SucursalID OUTPUT;

    ;WITH Ganancias AS
    (
        SELECT
            YEAR(I.InvoiceDate) AS InvoiceYear,
            SI.StockItemName,
            SUM(IL.LineProfit) AS TotalProfit
        FROM Corporativo.v_Invoices AS I
        INNER JOIN Corporativo.v_InvoiceLines AS IL
            ON I.SucursalID = IL.SucursalID AND I.InvoiceID = IL.InvoiceID
        INNER JOIN Warehouse.StockItems AS SI ON IL.StockItemID = SI.StockItemID
        WHERE (@SucursalID IS NULL OR I.SucursalID = @SucursalID)
          AND (@Year IS NULL OR YEAR(I.InvoiceDate) = @Year)
          AND (@StockItemName IS NULL OR SI.StockItemName LIKE N'%' + @StockItemName + N'%')
        GROUP BY YEAR(I.InvoiceDate), SI.StockItemName
    ),
    Ranking AS
    (
        SELECT InvoiceYear, StockItemName, TotalProfit,
            DENSE_RANK() OVER
                (PARTITION BY InvoiceYear ORDER BY TotalProfit DESC) AS ProfitRank
        FROM Ganancias
    )
    SELECT InvoiceYear, StockItemName, TotalProfit, ProfitRank
    FROM Ranking
    WHERE ProfitRank <= 5
    ORDER BY InvoiceYear DESC, ProfitRank, StockItemName;
END;
GO
