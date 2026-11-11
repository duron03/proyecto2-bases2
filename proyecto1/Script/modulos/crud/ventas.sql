USE [WideWorldImporters];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- Procedimiento interno. Las rutas de la API no reciben permiso directo sobre el.
CREATE OR ALTER PROCEDURE dbo.usp_Ventas_GuardarDetalles
    @InvoiceID int,
    @InvoiceLines nvarchar(max),
    @LastEditedBy int,
    @EsCreacion bit = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @InvoiceLines IS NULL OR ISJSON(@InvoiceLines) <> 1
        THROW 50303, 'Los detalles de la venta no tienen un formato valido.', 1;

    DECLARE @Lines TABLE
    (
        LineNumber int NOT NULL,
        StockItemID int NULL,
        Quantity int NULL,
        UnitPrice decimal(18, 2) NULL,
        TaxRate decimal(18, 3) NULL
    );

    INSERT INTO @Lines (LineNumber, StockItemID, Quantity, UnitPrice, TaxRate)
    SELECT
        CONVERT(int, J.[key]),
        D.StockItemID,
        D.Quantity,
        D.UnitPrice,
        D.TaxRate
    FROM OPENJSON(@InvoiceLines) AS J
    CROSS APPLY OPENJSON(J.[value])
    WITH
    (
        StockItemID int '$.StockItemID',
        Quantity int '$.Quantity',
        UnitPrice decimal(18, 2) '$.UnitPrice',
        TaxRate decimal(18, 3) '$.TaxRate'
    ) AS D;

    IF NOT EXISTS (SELECT 1 FROM @Lines)
        THROW 50303, 'La venta debe contener al menos un detalle.', 1;

    IF EXISTS
    (
        SELECT 1
        FROM @Lines
        WHERE StockItemID IS NULL OR Quantity IS NULL OR Quantity <= 0
           OR UnitPrice IS NULL OR UnitPrice < 0
           OR TaxRate IS NULL OR TaxRate < 0
    )
        THROW 50304, 'Uno o mas detalles contienen valores invalidos.', 1;

    IF EXISTS
    (
        SELECT 1
        FROM @Lines AS L
        LEFT JOIN Warehouse.StockItems AS SI
            ON L.StockItemID = SI.StockItemID
        WHERE SI.StockItemID IS NULL
    )
        THROW 50201, 'Uno de los productos no existe.', 1;

    IF EXISTS
    (
        SELECT 1
        FROM @Lines AS L
        LEFT JOIN Warehouse.StockItemHoldings AS H
            ON L.StockItemID = H.StockItemID
        WHERE H.StockItemID IS NULL
    )
        THROW 50202, 'Configure las existencias de este producto en su sucursal.', 1;

    IF @EsCreacion = 1
       AND EXISTS
       (
           SELECT 1
           FROM @Lines AS L
           INNER JOIN Warehouse.StockItems AS SI
               ON L.StockItemID = SI.StockItemID
           WHERE SI.Activo = 0
       )
        THROW 50402, 'No se puede agregar un producto inactivo a una venta nueva.', 1;

    IF @EsCreacion = 0
    BEGIN
        ;WITH Nuevas AS
        (
            SELECT StockItemID, SUM(Quantity) AS Cantidad
            FROM @Lines
            GROUP BY StockItemID
        ),
        Anteriores AS
        (
            SELECT StockItemID, SUM(Quantity) AS Cantidad
            FROM Sales.InvoiceLines
            WHERE InvoiceID = @InvoiceID
            GROUP BY StockItemID
        )
        SELECT 1 AS Dato
        INTO #IncrementosInactivos
        FROM Warehouse.StockItems AS SI
        LEFT JOIN Nuevas AS N ON SI.StockItemID = N.StockItemID
        LEFT JOIN Anteriores AS A ON SI.StockItemID = A.StockItemID
        WHERE SI.Activo = 0
          AND COALESCE(N.Cantidad, 0) > COALESCE(A.Cantidad, 0);

        IF EXISTS (SELECT 1 FROM #IncrementosInactivos)
        BEGIN
            DROP TABLE #IncrementosInactivos;
            THROW 50402, 'No se puede agregar ni aumentar un producto inactivo.', 1;
        END;

        DROP TABLE #IncrementosInactivos;
    END;

    DELETE FROM Sales.InvoiceLines
    WHERE InvoiceID = @InvoiceID;

    INSERT INTO Sales.InvoiceLines
    (
        InvoiceLineID, InvoiceID, StockItemID, Description,
        PackageTypeID, Quantity, UnitPrice, TaxRate,
        TaxAmount, LineProfit, ExtendedPrice,
        LastEditedBy, LastEditedWhen
    )
    SELECT
        NEXT VALUE FOR Sequences.InvoiceLineID,
        @InvoiceID,
        L.StockItemID,
        SI.StockItemName,
        SI.UnitPackageID,
        L.Quantity,
        L.UnitPrice,
        L.TaxRate,
        CONVERT(decimal(18, 2), ROUND(L.Quantity * L.UnitPrice * L.TaxRate / 100.0, 2)),
        CONVERT(decimal(18, 2), L.Quantity * (L.UnitPrice - H.LastCostPrice)),
        CONVERT(decimal(18, 2),
            L.Quantity * L.UnitPrice
            + ROUND(L.Quantity * L.UnitPrice * L.TaxRate / 100.0, 2)),
        @LastEditedBy,
        SYSUTCDATETIME()
    FROM @Lines AS L
    INNER JOIN Warehouse.StockItems AS SI
        ON L.StockItemID = SI.StockItemID
    INNER JOIN Warehouse.StockItemHoldings AS H
        ON L.StockItemID = H.StockItemID;

    UPDATE Sales.Invoices
    SET TotalDryItems =
        (
            SELECT COUNT(*)
            FROM @Lines AS L
            INNER JOIN Warehouse.StockItems AS SI ON L.StockItemID = SI.StockItemID
            WHERE SI.IsChillerStock = 0
        ),
        TotalChillerItems =
        (
            SELECT COUNT(*)
            FROM @Lines AS L
            INNER JOIN Warehouse.StockItems AS SI ON L.StockItemID = SI.StockItemID
            WHERE SI.IsChillerStock = 1
        ),
        LastEditedBy = @LastEditedBy,
        LastEditedWhen = SYSUTCDATETIME()
    WHERE InvoiceID = @InvoiceID;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Ventas_Crear
    @CustomerID int,
    @BillToCustomerID int,
    @DeliveryMethodID int,
    @ContactPersonID int,
    @AccountsPersonID int,
    @SalespersonPersonID int,
    @PackedByPersonID int,
    @InvoiceDate date,
    @LastEditedBy int = NULL,
    @OrderID int = NULL,
    @CustomerPurchaseOrderNumber nvarchar(20) = NULL,
    @IsCreditNote bit = 0,
    @CreditNoteReason nvarchar(max) = NULL,
    @Comments nvarchar(max) = NULL,
    @DeliveryInstructions nvarchar(max) = NULL,
    @InternalComments nvarchar(max) = NULL,
    @TotalDryItems int = 0,
    @TotalChillerItems int = 0,
    @DeliveryRun nvarchar(5) = NULL,
    @RunPosition nvarchar(5) = NULL,
    @ReturnedDeliveryData nvarchar(max) = NULL,
    @InvoiceLines nvarchar(max) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Actor int;
    DECLARE @SucursalUsuario int;
    DECLARE @SucursalNodo int;

    SELECT @Actor = PersonID, @SucursalUsuario = SucursalID
    FROM Seguridad.IdentidadesLocales
    WHERE SqlLogin = ORIGINAL_LOGIN() AND active = 1;

    SELECT @SucursalNodo = SucursalID FROM Control.Nodo WHERE Id = 1;

    IF @Actor IS NULL OR @SucursalUsuario <> @SucursalNodo
        THROW 50403, 'El usuario no puede crear ventas en esta sucursal.', 1;

    IF NOT EXISTS
    (
        SELECT 1 FROM Sales.Customers
        WHERE CustomerID = @CustomerID AND Activo = 1
    )
        THROW 50402, 'El cliente esta inactivo o no existe.', 1;

    IF NOT EXISTS
    (
        SELECT 1 FROM Sales.Customers
        WHERE CustomerID = @BillToCustomerID AND Activo = 1
    )
        THROW 50402, 'El cliente de facturacion esta inactivo o no existe.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @NewInvoiceID int = NEXT VALUE FOR Sequences.InvoiceID;

        INSERT INTO Sales.Invoices
        (
            InvoiceID, CustomerID, BillToCustomerID, OrderID, DeliveryMethodID,
            ContactPersonID, AccountsPersonID, SalespersonPersonID, PackedByPersonID,
            InvoiceDate, CustomerPurchaseOrderNumber, IsCreditNote,
            CreditNoteReason, Comments, DeliveryInstructions, InternalComments,
            TotalDryItems, TotalChillerItems, DeliveryRun, RunPosition,
            ReturnedDeliveryData, LastEditedBy, LastEditedWhen, VersionVenta
        )
        VALUES
        (
            @NewInvoiceID, @CustomerID, @BillToCustomerID, @OrderID, @DeliveryMethodID,
            @ContactPersonID, @AccountsPersonID, @SalespersonPersonID, @PackedByPersonID,
            @InvoiceDate, @CustomerPurchaseOrderNumber, @IsCreditNote,
            @CreditNoteReason, @Comments, @DeliveryInstructions, @InternalComments,
            0, 0, @DeliveryRun, @RunPosition,
            @ReturnedDeliveryData, @Actor, SYSUTCDATETIME(), 1
        );

        EXEC dbo.usp_Ventas_GuardarDetalles
            @InvoiceID = @NewInvoiceID,
            @InvoiceLines = @InvoiceLines,
            @LastEditedBy = @Actor,
            @EsCreacion = 1;

        COMMIT TRANSACTION;
        SELECT @NewInvoiceID AS InvoiceID, 1 AS VersionVenta;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Ventas_Actualizar
    @InvoiceID int,
    @CustomerID int,
    @BillToCustomerID int,
    @DeliveryMethodID int,
    @ContactPersonID int,
    @AccountsPersonID int,
    @SalespersonPersonID int,
    @PackedByPersonID int,
    @InvoiceDate date,
    @VersionEsperada int,
    @LastEditedBy int = NULL,
    @OrderID int = NULL,
    @CustomerPurchaseOrderNumber nvarchar(20) = NULL,
    @IsCreditNote bit = 0,
    @CreditNoteReason nvarchar(max) = NULL,
    @Comments nvarchar(max) = NULL,
    @DeliveryInstructions nvarchar(max) = NULL,
    @InternalComments nvarchar(max) = NULL,
    @TotalDryItems int = NULL,
    @TotalChillerItems int = NULL,
    @DeliveryRun nvarchar(5) = NULL,
    @RunPosition nvarchar(5) = NULL,
    @ReturnedDeliveryData nvarchar(max) = NULL,
    @InvoiceLines nvarchar(max) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Actor int;
    DECLARE @SucursalUsuario int;
    DECLARE @SucursalNodo int;
    DECLARE @CustomerActual int;
    DECLARE @BillToActual int;

    SELECT @Actor = PersonID, @SucursalUsuario = SucursalID
    FROM Seguridad.IdentidadesLocales
    WHERE SqlLogin = ORIGINAL_LOGIN() AND active = 1;

    SELECT @SucursalNodo = SucursalID FROM Control.Nodo WHERE Id = 1;

    IF @Actor IS NULL OR @SucursalUsuario <> @SucursalNodo
        THROW 50403, 'El usuario no puede modificar ventas en esta sucursal.', 1;

    SELECT @CustomerActual = CustomerID, @BillToActual = BillToCustomerID
    FROM Sales.Invoices
    WHERE InvoiceID = @InvoiceID;

    IF @CustomerActual IS NULL
        THROW 50301, 'La venta no existe.', 1;

    IF @CustomerID <> @CustomerActual
       AND NOT EXISTS
       (
           SELECT 1 FROM Sales.Customers
           WHERE CustomerID = @CustomerID AND Activo = 1
       )
        THROW 50402, 'El cliente seleccionado esta inactivo.', 1;

    IF @BillToCustomerID <> @BillToActual
       AND NOT EXISTS
       (
           SELECT 1 FROM Sales.Customers
           WHERE CustomerID = @BillToCustomerID AND Activo = 1
       )
        THROW 50402, 'El cliente de facturacion esta inactivo.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE Sales.Invoices
        SET CustomerID = @CustomerID,
            BillToCustomerID = @BillToCustomerID,
            OrderID = @OrderID,
            DeliveryMethodID = @DeliveryMethodID,
            ContactPersonID = @ContactPersonID,
            AccountsPersonID = @AccountsPersonID,
            SalespersonPersonID = @SalespersonPersonID,
            PackedByPersonID = @PackedByPersonID,
            InvoiceDate = @InvoiceDate,
            CustomerPurchaseOrderNumber = @CustomerPurchaseOrderNumber,
            IsCreditNote = @IsCreditNote,
            CreditNoteReason = @CreditNoteReason,
            Comments = @Comments,
            DeliveryInstructions = @DeliveryInstructions,
            InternalComments = @InternalComments,
            DeliveryRun = @DeliveryRun,
            RunPosition = @RunPosition,
            ReturnedDeliveryData = @ReturnedDeliveryData,
            LastEditedBy = @Actor,
            LastEditedWhen = SYSUTCDATETIME(),
            VersionVenta = VersionVenta + 1
        WHERE InvoiceID = @InvoiceID
          AND VersionVenta = @VersionEsperada;

        IF @@ROWCOUNT = 0
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM Sales.Invoices WHERE InvoiceID = @InvoiceID)
                THROW 50301, 'La venta no existe.', 1;
            THROW 50401, 'La venta fue modificada por otra sesion.', 1;
        END;

        EXEC dbo.usp_Ventas_GuardarDetalles
            @InvoiceID = @InvoiceID,
            @InvoiceLines = @InvoiceLines,
            @LastEditedBy = @Actor,
            @EsCreacion = 0;

        COMMIT TRANSACTION;
        SELECT @InvoiceID AS InvoiceID, @VersionEsperada + 1 AS VersionVenta;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Ventas_Eliminar
    @InvoiceID int,
    @VersionEsperada int
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Actor int;
    DECLARE @SucursalUsuario int;
    DECLARE @SucursalNodo int;

    SELECT @Actor = PersonID, @SucursalUsuario = SucursalID
    FROM Seguridad.IdentidadesLocales
    WHERE SqlLogin = ORIGINAL_LOGIN() AND active = 1;

    SELECT @SucursalNodo = SucursalID FROM Control.Nodo WHERE Id = 1;

    IF @Actor IS NULL OR @SucursalUsuario <> @SucursalNodo
        THROW 50403, 'El usuario no puede eliminar ventas en esta sucursal.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @VersionActual int;
        SELECT @VersionActual = VersionVenta
        FROM Sales.Invoices WITH (UPDLOCK, HOLDLOCK)
        WHERE InvoiceID = @InvoiceID;

        IF @VersionActual IS NULL
            THROW 50301, 'La venta no existe.', 1;

        IF @VersionActual <> @VersionEsperada
            THROW 50401, 'La venta fue modificada por otra sesion.', 1;

        DELETE FROM Sales.InvoiceLines WHERE InvoiceID = @InvoiceID;
        DELETE FROM Sales.Invoices WHERE InvoiceID = @InvoiceID;

        COMMIT TRANSACTION;
        SELECT @InvoiceID AS InvoiceID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
