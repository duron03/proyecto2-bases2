USE [WideWorldImporters];
GO

CREATE OR ALTER PROCEDURE dbo.usp_Estadisticas_Reporte5
    @Year int = NULL,
    @SupplierName nvarchar(100) = NULL,
    @SucursalID int = NULL
AS
BEGIN
    SET NOCOUNT ON;
    EXEC Seguridad.usp_ValidarAlcanceReporte @SucursalID OUTPUT;

    ;WITH Ordenes AS
    (
        SELECT YEAR(PO.OrderDate) AS OrderYear, S.SupplierName,
            COUNT_BIG(*) AS OrderCount
        FROM Corporativo.v_PurchaseOrders AS PO
        INNER JOIN Purchasing.Suppliers AS S ON PO.SupplierID = S.SupplierID
        WHERE (@SucursalID IS NULL OR PO.SucursalID = @SucursalID)
          AND (@Year IS NULL OR YEAR(PO.OrderDate) = @Year)
          AND (@SupplierName IS NULL OR S.SupplierName LIKE N'%' + @SupplierName + N'%')
        GROUP BY YEAR(PO.OrderDate), S.SupplierName
    ),
    Ranking AS
    (
        SELECT OrderYear, SupplierName, OrderCount,
            DENSE_RANK() OVER
                (PARTITION BY OrderYear ORDER BY OrderCount DESC) AS SupplierRank
        FROM Ordenes
    )
    SELECT OrderYear, SupplierName, OrderCount, SupplierRank
    FROM Ranking
    WHERE SupplierRank <= 5
    ORDER BY OrderYear DESC, SupplierRank, SupplierName;
END;
GO
