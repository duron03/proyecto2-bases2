USE [WideWorldImporters];
GO

-- Sinónimos utilizados por el reporte 3.
IF OBJECT_ID('dbo.src_Factura', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_Factura FOR Sales.Invoices;');
GO

IF OBJECT_ID('dbo.src_DetalleFactura', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_DetalleFactura FOR Sales.InvoiceLines;');
GO

IF OBJECT_ID('dbo.src_Producto', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_Producto FOR Warehouse.StockItems;');
GO

-- Muestra el Top 5 de productos que generan más ganancia por año.
CREATE OR ALTER PROCEDURE dbo.usp_Estadisticas_Reporte3
    @Year int = NULL,
    @StockItemName nvarchar(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        WITH CTE_Ganancias AS (
            SELECT
                YEAR(I.InvoiceDate) AS InvoiceYear,
                SI.StockItemName,
                SUM(IL.LineProfit) AS TotalProfit
            FROM dbo.src_Factura AS I
            INNER JOIN dbo.src_DetalleFactura AS IL
                ON I.InvoiceID = IL.InvoiceID
            INNER JOIN dbo.src_Producto AS SI
                ON IL.StockItemID = SI.StockItemID
            WHERE
                (
                    @Year IS NULL
                    OR YEAR(I.InvoiceDate) = @Year
                )
                AND
                (
                    @StockItemName IS NULL
                    OR SI.StockItemName LIKE '%' + @StockItemName + '%'
                )
            GROUP BY
                YEAR(I.InvoiceDate),
                SI.StockItemName
        ),
        CTE_Ranking AS (
            SELECT
                InvoiceYear,
                StockItemName,
                TotalProfit,
                DENSE_RANK() OVER (PARTITION BY InvoiceYear ORDER BY TotalProfit DESC) AS ProfitRank
            FROM CTE_Ganancias
        )
        SELECT
            InvoiceYear,
            StockItemName,
            TotalProfit,
            ProfitRank
        FROM CTE_Ranking
        WHERE ProfitRank <= 5
        ORDER BY
            InvoiceYear DESC,
            ProfitRank ASC;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO