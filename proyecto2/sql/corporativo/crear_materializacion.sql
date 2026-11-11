:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;

USE [WideWorldImporters];
GO

IF OBJECT_ID(N'Corporativo.ResumenVentasMensuales', N'U') IS NULL
BEGIN
    CREATE TABLE Corporativo.ResumenVentasMensuales
    (
        SucursalID int NOT NULL,
        Anio int NOT NULL,
        Mes int NOT NULL,
        CantidadFacturas bigint NOT NULL,
        CantidadUnidades bigint NOT NULL,
        MontoSinImpuesto decimal(38, 2) NOT NULL,
        Impuestos decimal(38, 2) NOT NULL,
        MontoTotal decimal(38, 2) NOT NULL,
        Utilidad decimal(38, 2) NOT NULL,
        CONSTRAINT PK_ResumenVentasMensuales PRIMARY KEY (SucursalID, Anio, Mes),
        CONSTRAINT CK_ResumenVentas_Sucursal CHECK (SucursalID IN (1, 2)),
        CONSTRAINT CK_ResumenVentas_Mes CHECK (Mes BETWEEN 1 AND 12)
    );
END;

IF OBJECT_ID(N'Control.EstadoMaterializacion', N'U') IS NULL
BEGIN
    CREATE TABLE Control.EstadoMaterializacion
    (
        Id tinyint NOT NULL,
        UltimoIntentoUtc datetime2(7) NULL,
        UltimoExitoUtc datetime2(7) NULL,
        EstadoUltimoIntento varchar(20) NOT NULL,
        UltimoError nvarchar(1000) NULL,
        LatidoSJUsadoUtc datetime2(7) NULL,
        LatidoLIUsadoUtc datetime2(7) NULL,
        CONSTRAINT PK_EstadoMaterializacion PRIMARY KEY (Id),
        CONSTRAINT CK_EstadoMaterializacion_Id CHECK (Id = 1),
        CONSTRAINT CK_EstadoMaterializacion_Estado CHECK
        (
            EstadoUltimoIntento IN
                ('sin_inicializar', 'en_curso', 'correcto', 'fallido')
        )
    );

    INSERT INTO Control.EstadoMaterializacion
        (Id, EstadoUltimoIntento)
    VALUES
        (1, 'sin_inicializar');
END;
GO

CREATE OR ALTER PROCEDURE Corporativo.usp_ActualizarResumenVentas
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @ResultadoBloqueo int;
    DECLARE @Ahora datetime2(7) = SYSUTCDATETIME();
    DECLARE @LatidoSJ datetime2(7);
    DECLARE @LatidoLI datetime2(7);

    EXEC @ResultadoBloqueo = sys.sp_getapplock
        @Resource = N'P2_ResumenVentasMensuales',
        @LockMode = N'Exclusive',
        @LockOwner = N'Session',
        @LockTimeout = 0;

    IF @ResultadoBloqueo < 0
    BEGIN
        SELECT N'en_curso' AS Estado;
        RETURN;
    END;

    UPDATE Control.EstadoMaterializacion
    SET UltimoIntentoUtc = @Ahora,
        EstadoUltimoIntento = 'en_curso',
        UltimoError = NULL
    WHERE Id = 1;

    BEGIN TRY
        IF EXISTS
        (
            SELECT 1
            FROM (VALUES (1), (2)) AS S(SucursalID)
            LEFT JOIN Control.EstadoInicializacion AS E
                ON S.SucursalID = E.SucursalID
            WHERE COALESCE(E.DatosValidados, 0) = 0
        )
            THROW 50501, 'Las dos sucursales deben estar inicializadas antes del primer resumen.', 1;

        SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
        BEGIN TRANSACTION;

        SELECT @LatidoSJ = FechaUtc FROM sj.LatidoSucursal WHERE SucursalID = 1;
        SELECT @LatidoLI = FechaUtc FROM limon.LatidoSucursal WHERE SucursalID = 2;

        IF @LatidoSJ IS NULL OR @LatidoLI IS NULL
            THROW 50502, 'No existen latidos replicados de las dos sucursales.', 1;

        DELETE FROM Corporativo.ResumenVentasMensuales;

        INSERT INTO Corporativo.ResumenVentasMensuales
        (
            SucursalID, Anio, Mes, CantidadFacturas, CantidadUnidades,
            MontoSinImpuesto, Impuestos, MontoTotal, Utilidad
        )
        SELECT
            I.SucursalID,
            YEAR(I.InvoiceDate),
            MONTH(I.InvoiceDate),
            COUNT_BIG(DISTINCT I.InvoiceID),
            SUM(CONVERT(bigint, IL.Quantity)),
            SUM(CONVERT(decimal(38, 2), IL.ExtendedPrice - IL.TaxAmount)),
            SUM(CONVERT(decimal(38, 2), IL.TaxAmount)),
            SUM(CONVERT(decimal(38, 2), IL.ExtendedPrice)),
            SUM(CONVERT(decimal(38, 2), IL.LineProfit))
        FROM Corporativo.v_Invoices AS I
        INNER JOIN Corporativo.v_InvoiceLines AS IL
            ON I.SucursalID = IL.SucursalID
           AND I.InvoiceID = IL.InvoiceID
        GROUP BY I.SucursalID, YEAR(I.InvoiceDate), MONTH(I.InvoiceDate);

        SET @Ahora = SYSUTCDATETIME();

        UPDATE Control.EstadoMaterializacion
        SET UltimoIntentoUtc = @Ahora,
            UltimoExitoUtc = @Ahora,
            EstadoUltimoIntento = 'correcto',
            UltimoError = NULL,
            LatidoSJUsadoUtc = @LatidoSJ,
            LatidoLIUsadoUtc = @LatidoLI
        WHERE Id = 1;

        COMMIT TRANSACTION;
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

        EXEC sys.sp_releaseapplock
            @Resource = N'P2_ResumenVentasMensuales',
            @LockOwner = N'Session';

        SELECT N'correcto' AS Estado, @Ahora AS UltimoExitoUtc;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

        DECLARE @Error nvarchar(1000) = LEFT(ERROR_MESSAGE(), 1000);

        UPDATE Control.EstadoMaterializacion
        SET UltimoIntentoUtc = SYSUTCDATETIME(),
            EstadoUltimoIntento = 'fallido',
            UltimoError = @Error
        WHERE Id = 1;

        EXEC sys.sp_releaseapplock
            @Resource = N'P2_ResumenVentasMensuales',
            @LockOwner = N'Session';

        THROW;
    END CATCH;
END;
GO

