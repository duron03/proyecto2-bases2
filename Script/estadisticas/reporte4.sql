USE [WideWorldImporters];
GO

-- Sinónimos utilizados por el reporte 4.
IF OBJECT_ID('dbo.src_Factura', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_Factura FOR Sales.Invoices;');
GO

IF OBJECT_ID('dbo.src_DetalleFactura', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_DetalleFactura FOR Sales.InvoiceLines;');
GO

IF OBJECT_ID('dbo.src_Cliente', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_Cliente FOR Sales.Customers;');
GO

-- Muestra el Top 5 de clientes con mayor cantidad de facturas por año, incluyendo monto total.
CREATE OR ALTER PROCEDURE dbo.usp_Estadisticas_Reporte4
    @Year int = NULL,
    @CustomerName nvarchar(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        WITH CTE_Facturas AS (
            SELECT
                YEAR(I.InvoiceDate) AS InvoiceYear,
                C.CustomerName,
                COUNT(DISTINCT I.InvoiceID) AS InvoiceCount,
                SUM(IL.ExtendedPrice) AS TotalAmount
            FROM dbo.src_Factura AS I
            INNER JOIN dbo.src_Cliente AS C
                ON I.CustomerID = C.CustomerID
            INNER JOIN dbo.src_DetalleFactura AS IL
                ON I.InvoiceID = IL.InvoiceID
            WHERE
                (
                    @Year IS NULL
                    OR YEAR(I.InvoiceDate) = @Year
                )
                AND
                (
                    @CustomerName IS NULL
                    OR C.CustomerName LIKE '%' + @CustomerName + '%'
                )
            GROUP BY
                YEAR(I.InvoiceDate),
                C.CustomerName
        ),
        CTE_Ranking AS (
            SELECT
                InvoiceYear,
                CustomerName,
                InvoiceCount,
                TotalAmount,
                DENSE_RANK() OVER (PARTITION BY InvoiceYear ORDER BY InvoiceCount DESC) AS ClientRank
            FROM CTE_Facturas
        )
        SELECT
            InvoiceYear,
            CustomerName,
            InvoiceCount,
            TotalAmount,
            ClientRank
        FROM CTE_Ranking
        WHERE ClientRank <= 5
        ORDER BY
            InvoiceYear DESC,
            ClientRank ASC;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO