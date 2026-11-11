:on error exit
SET NOCOUNT ON;

USE [WideWorldImporters];
GO

CREATE OR ALTER PROCEDURE Corporativo.usp_ObtenerResumenVentas
    @SucursalID int = NULL,
    @Year int = NULL,
    @Month int = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS
    (
        SELECT 1 FROM Seguridad.Usuarios
        WHERE SqlLogin = ORIGINAL_LOGIN()
          AND active = 1
          AND rol = N'CORPORATIVO'
    )
        THROW 50403, 'Solo el usuario corporativo puede consultar el resumen.', 1;

    IF @SucursalID IS NOT NULL AND @SucursalID NOT IN (1, 2)
        THROW 50403, 'La sucursal solicitada no es valida.', 1;

    IF NOT EXISTS
    (
        SELECT 1 FROM Control.EstadoMaterializacion
        WHERE Id = 1 AND UltimoExitoUtc IS NOT NULL
    )
        THROW 50501, 'El resumen aun no ha sido inicializado.', 1;

    SELECT
        Anio,
        Mes,
        SUM(CantidadFacturas) AS CantidadFacturas,
        SUM(CantidadUnidades) AS CantidadUnidades,
        SUM(MontoSinImpuesto) AS MontoSinImpuesto,
        SUM(Impuestos) AS Impuestos,
        SUM(MontoTotal) AS MontoTotal,
        SUM(Utilidad) AS Utilidad
    FROM Corporativo.ResumenVentasMensuales
    WHERE (@SucursalID IS NULL OR SucursalID = @SucursalID)
      AND (@Year IS NULL OR Anio = @Year)
      AND (@Month IS NULL OR Mes = @Month)
    GROUP BY Anio, Mes
    ORDER BY Anio DESC, Mes DESC;
END;
GO

CREATE OR ALTER PROCEDURE Corporativo.usp_ObtenerCatalogosReportes
    @SucursalID int = NULL
AS
BEGIN
    SET NOCOUNT ON;
    EXEC Seguridad.usp_ValidarAlcanceReporte @SucursalID OUTPUT;

    SELECT DISTINCT [Value], CONVERT(nvarchar(10), [Value]) AS [Label]
    FROM
    (
        SELECT YEAR(InvoiceDate) AS [Value]
        FROM Corporativo.v_Invoices
        WHERE @SucursalID IS NULL OR SucursalID = @SucursalID
        UNION
        SELECT YEAR(OrderDate) AS [Value]
        FROM Corporativo.v_PurchaseOrders
        WHERE @SucursalID IS NULL OR SucursalID = @SucursalID
    ) AS Anios
    ORDER BY [Value] DESC;

    SELECT [Value], [Label]
    FROM
    (VALUES
        (1, N'Enero'), (2, N'Febrero'), (3, N'Marzo'),
        (4, N'Abril'), (5, N'Mayo'), (6, N'Junio'),
        (7, N'Julio'), (8, N'Agosto'), (9, N'Septiembre'),
        (10, N'Octubre'), (11, N'Noviembre'), (12, N'Diciembre')
    ) AS Meses([Value], [Label])
    ORDER BY [Value];
END;
GO
