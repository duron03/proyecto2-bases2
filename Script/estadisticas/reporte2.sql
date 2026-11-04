USE [WideWorldImporters];
GO

-- Sinónimos utilizados por el reporte 2.
IF OBJECT_ID('dbo.src_Factura', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_Factura FOR Sales.Invoices;');
GO

IF OBJECT_ID('dbo.src_Cliente', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_Cliente FOR Sales.Customers;');
GO

IF OBJECT_ID('dbo.src_CategoriaCliente', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_CategoriaCliente FOR Sales.CustomerCategories;');
GO

IF OBJECT_ID('dbo.src_TransaccionCliente', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_TransaccionCliente FOR Sales.CustomerTransactions;');
GO

-- Muestra las compras máximas, mínimas y promedio por cliente y categoría.
CREATE OR ALTER PROCEDURE dbo.usp_Estadisticas_Reporte2
    @CustomerName NVARCHAR(100) = NULL,
    @CustomerCategoryName NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT
            CASE
                WHEN GROUPING(C.CustomerName) = 1
                    THEN 'TOTAL PER CUSTOMER'
                ELSE C.CustomerName
            END AS CustomerName,
            CASE
                WHEN GROUPING(C.CustomerName) <> 1
                    THEN
                        CASE
                            WHEN GROUPING(CC.CustomerCategoryName) = 1
                                THEN CONCAT('TOTAL', ' - ', UPPER(C.CustomerName))
                            ELSE CC.CustomerCategoryName
                        END
                ELSE ' '
            END AS CustomerCategoryName,
            MAX(CT.TransactionAmount) AS MaxAmount,
            MIN(CT.TransactionAmount) AS MinAmount,
            AVG(CT.TransactionAmount) AS AvgPurchase
        FROM dbo.src_Factura AS I
        INNER JOIN dbo.src_Cliente AS C
            ON I.CustomerID = C.CustomerID
        INNER JOIN dbo.src_CategoriaCliente AS CC
            ON C.CustomerCategoryID = CC.CustomerCategoryID
        INNER JOIN dbo.src_TransaccionCliente AS CT
            ON I.InvoiceID = CT.InvoiceID
        WHERE
            (
                @CustomerName IS NULL
                OR C.CustomerName LIKE '%' + @CustomerName + '%'
            )
            AND
            (
                @CustomerCategoryName IS NULL
                OR CC.CustomerCategoryName LIKE '%' + @CustomerCategoryName + '%'
            )
        GROUP BY ROLLUP
        (
            C.CustomerName,
            CC.CustomerCategoryName
        );

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO
