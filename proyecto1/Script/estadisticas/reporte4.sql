USE [WideWorldImporters];
GO

CREATE OR ALTER PROCEDURE dbo.usp_Estadisticas_Reporte4
    @Year int = NULL,
    @CustomerName nvarchar(100) = NULL,
    @SucursalID int = NULL
AS
BEGIN
    SET NOCOUNT ON;
    EXEC Seguridad.usp_ValidarAlcanceReporte @SucursalID OUTPUT;

    ;WITH TotalesFactura AS
    (
        SELECT
            I.SucursalID,
            I.InvoiceID,
            YEAR(I.InvoiceDate) AS InvoiceYear,
            C.CustomerName,
            SUM(IL.ExtendedPrice) AS InvoiceAmount
        FROM Corporativo.v_Invoices AS I
        INNER JOIN Corporativo.v_InvoiceLines AS IL
            ON I.SucursalID = IL.SucursalID AND I.InvoiceID = IL.InvoiceID
        INNER JOIN Sales.Customers AS C ON I.CustomerID = C.CustomerID
        WHERE (@SucursalID IS NULL OR I.SucursalID = @SucursalID)
          AND (@Year IS NULL OR YEAR(I.InvoiceDate) = @Year)
          AND (@CustomerName IS NULL OR C.CustomerName LIKE N'%' + @CustomerName + N'%')
        GROUP BY I.SucursalID, I.InvoiceID, YEAR(I.InvoiceDate), C.CustomerName
    ),
    Facturas AS
    (
        SELECT InvoiceYear, CustomerName,
            COUNT_BIG(*) AS InvoiceCount,
            SUM(InvoiceAmount) AS TotalAmount
        FROM TotalesFactura
        GROUP BY InvoiceYear, CustomerName
    ),
    Ranking AS
    (
        SELECT InvoiceYear, CustomerName, InvoiceCount, TotalAmount,
            DENSE_RANK() OVER
                (PARTITION BY InvoiceYear ORDER BY InvoiceCount DESC) AS ClientRank
        FROM Facturas
    )
    SELECT InvoiceYear, CustomerName, InvoiceCount, TotalAmount, ClientRank
    FROM Ranking
    WHERE ClientRank <= 5
    ORDER BY InvoiceYear DESC, ClientRank, CustomerName;
END;
GO
