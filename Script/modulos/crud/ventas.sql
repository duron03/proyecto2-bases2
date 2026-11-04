USE [WideWorldImporters];
GO

-- Sinónimos utilizados por el CRUD de ventas.
IF OBJECT_ID('dbo.src_Factura', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_Factura FOR Sales.Invoices;');
GO

IF OBJECT_ID('dbo.src_DetalleFactura', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_DetalleFactura FOR Sales.InvoiceLines;');
GO

IF OBJECT_ID('dbo.src_Producto', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_Producto FOR Warehouse.StockItems;');
GO

IF OBJECT_ID('dbo.src_Existencia', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_Existencia FOR Warehouse.StockItemHoldings;');
GO

-- Reemplaza las líneas de una factura y calcula sus valores derivados.
CREATE OR ALTER PROCEDURE dbo.usp_Ventas_GuardarDetalles
    @InvoiceID int,
    @InvoiceLines nvarchar(max),
    @LastEditedBy int
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @InvoiceLines IS NULL OR ISJSON(@InvoiceLines) = 0
            THROW 50303, 'Debe enviar el detalle de la factura.', 1;

        DECLARE @Lines TABLE
        (
            StockItemID int,
            Quantity int,
            UnitPrice decimal(18, 2),
            TaxRate decimal(18, 3)
        );

        INSERT INTO @Lines
        (
            StockItemID,
            Quantity,
            UnitPrice,
            TaxRate
        )
        SELECT
            StockItemID,
            Quantity,
            UnitPrice,
            TaxRate
        FROM OPENJSON(@InvoiceLines)
        WITH
        (
            StockItemID int,
            Quantity int,
            UnitPrice decimal(18, 2),
            TaxRate decimal(18, 3)
        );

        IF NOT EXISTS (SELECT 1 FROM @Lines)
            THROW 50303, 'La factura debe tener al menos una línea.', 1;

        IF EXISTS
        (
            SELECT 1
            FROM @Lines
            WHERE StockItemID IS NULL
                OR Quantity IS NULL
                OR Quantity <= 0
                OR UnitPrice IS NULL
                OR UnitPrice < 0
                OR TaxRate IS NULL
                OR TaxRate < 0
        )
            THROW 50304, 'Revise el producto, cantidad, precio e impuesto de cada línea.', 1;

        IF EXISTS
        (
            SELECT 1
            FROM @Lines AS L
            LEFT JOIN dbo.src_Producto AS SI
                ON L.StockItemID = SI.StockItemID
            LEFT JOIN dbo.src_Existencia AS H
                ON L.StockItemID = H.StockItemID
            WHERE SI.StockItemID IS NULL
                OR H.StockItemID IS NULL
        )
            THROW 50304, 'Una línea contiene un producto inválido.', 1;

        DELETE FROM dbo.src_DetalleFactura
        WHERE InvoiceID = @InvoiceID;

        INSERT INTO dbo.src_DetalleFactura
        (
            InvoiceLineID,
            InvoiceID,
            StockItemID,
            Description,
            PackageTypeID,
            Quantity,
            UnitPrice,
            TaxRate,
            TaxAmount,
            LineProfit,
            ExtendedPrice,
            LastEditedBy
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
            CAST(L.Quantity * L.UnitPrice * L.TaxRate / 100 AS decimal(18, 2)),
            CAST(L.Quantity * (L.UnitPrice - H.LastCostPrice) AS decimal(18, 2)),
            CAST(
                (L.Quantity * L.UnitPrice)
                + (L.Quantity * L.UnitPrice * L.TaxRate / 100)
                AS decimal(18, 2)
            ),
            @LastEditedBy
        FROM @Lines AS L
        INNER JOIN dbo.src_Producto AS SI
            ON L.StockItemID = SI.StockItemID
        INNER JOIN dbo.src_Existencia AS H
            ON L.StockItemID = H.StockItemID;

        DECLARE @TotalDryItems int;
        DECLARE @TotalChillerItems int;

        SELECT
            @TotalDryItems = SUM(CASE WHEN SI.IsChillerStock = 0 THEN 1 ELSE 0 END),
            @TotalChillerItems = SUM(CASE WHEN SI.IsChillerStock = 1 THEN 1 ELSE 0 END)
        FROM @Lines AS L
        INNER JOIN dbo.src_Producto AS SI
            ON L.StockItemID = SI.StockItemID;

        UPDATE dbo.src_Factura
        SET TotalDryItems = @TotalDryItems,
            TotalChillerItems = @TotalChillerItems
        WHERE InvoiceID = @InvoiceID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

-- Crea el encabezado de una venta.
CREATE OR ALTER PROCEDURE dbo.usp_Ventas_Crear
    @CustomerID int,
    @BillToCustomerID int,
    @DeliveryMethodID int,
    @ContactPersonID int,
    @AccountsPersonID int,
    @SalespersonPersonID int,
    @PackedByPersonID int,
    @InvoiceDate date,
    @LastEditedBy int,
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

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @NewInvoiceID int = NEXT VALUE FOR Sequences.InvoiceID;

        INSERT INTO dbo.src_Factura
        (
            InvoiceID,
            CustomerID,
            BillToCustomerID,
            OrderID,
            DeliveryMethodID,
            ContactPersonID,
            AccountsPersonID,
            SalespersonPersonID,
            PackedByPersonID,
            InvoiceDate,
            CustomerPurchaseOrderNumber,
            IsCreditNote,
            CreditNoteReason,
            Comments,
            DeliveryInstructions,
            InternalComments,
            TotalDryItems,
            TotalChillerItems,
            DeliveryRun,
            RunPosition,
            ReturnedDeliveryData,
            LastEditedBy
        )
        VALUES
        (
            @NewInvoiceID,
            @CustomerID,
            @BillToCustomerID,
            @OrderID,
            @DeliveryMethodID,
            @ContactPersonID,
            @AccountsPersonID,
            @SalespersonPersonID,
            @PackedByPersonID,
            @InvoiceDate,
            @CustomerPurchaseOrderNumber,
            @IsCreditNote,
            @CreditNoteReason,
            @Comments,
            @DeliveryInstructions,
            @InternalComments,
            @TotalDryItems,
            @TotalChillerItems,
            @DeliveryRun,
            @RunPosition,
            @ReturnedDeliveryData,
            @LastEditedBy
        );

        EXEC dbo.usp_Ventas_GuardarDetalles
            @InvoiceID = @NewInvoiceID,
            @InvoiceLines = @InvoiceLines,
            @LastEditedBy = @LastEditedBy;

        SELECT @NewInvoiceID AS InvoiceID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

-- Actualiza todos los datos editables del encabezado de una venta.
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
    @LastEditedBy int,
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

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE dbo.src_Factura
        SET CustomerID = @CustomerID,
            BillToCustomerID = @BillToCustomerID,
            OrderID = ISNULL(@OrderID, OrderID),
            DeliveryMethodID = @DeliveryMethodID,
            ContactPersonID = @ContactPersonID,
            AccountsPersonID = @AccountsPersonID,
            SalespersonPersonID = @SalespersonPersonID,
            PackedByPersonID = @PackedByPersonID,
            InvoiceDate = @InvoiceDate,
            CustomerPurchaseOrderNumber = @CustomerPurchaseOrderNumber,
            IsCreditNote = @IsCreditNote,
            CreditNoteReason = ISNULL(@CreditNoteReason, CreditNoteReason),
            Comments = @Comments,
            DeliveryInstructions = @DeliveryInstructions,
            InternalComments = ISNULL(@InternalComments, InternalComments),
            TotalDryItems = ISNULL(@TotalDryItems, TotalDryItems),
            TotalChillerItems = ISNULL(@TotalChillerItems, TotalChillerItems),
            DeliveryRun = ISNULL(@DeliveryRun, DeliveryRun),
            RunPosition = ISNULL(@RunPosition, RunPosition),
            ReturnedDeliveryData = ISNULL(@ReturnedDeliveryData, ReturnedDeliveryData),
            LastEditedBy = @LastEditedBy,
            LastEditedWhen = SYSDATETIME()
        WHERE InvoiceID = @InvoiceID;

        IF @@ROWCOUNT = 0
            THROW 50301, 'La venta no existe.', 1;

        IF @InvoiceLines IS NOT NULL
        BEGIN
            EXEC dbo.usp_Ventas_GuardarDetalles
                @InvoiceID = @InvoiceID,
                @InvoiceLines = @InvoiceLines,
                @LastEditedBy = @LastEditedBy;
        END;

        SELECT @InvoiceID AS InvoiceID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

-- Agrega una línea al detalle de la venta.
CREATE OR ALTER PROCEDURE dbo.usp_Ventas_AgregarDetalle
    @InvoiceID int,
    @StockItemID int,
    @Description nvarchar(100),
    @PackageTypeID int,
    @Quantity int,
    @UnitPrice decimal(18, 2),
    @TaxRate decimal(18, 3),
    @TaxAmount decimal(18, 2),
    @LineProfit decimal(18, 2),
    @ExtendedPrice decimal(18, 2),
    @LastEditedBy int
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @NewInvoiceLineID int = NEXT VALUE FOR Sequences.InvoiceLineID;

        INSERT INTO dbo.src_DetalleFactura
        (
            InvoiceLineID,
            InvoiceID,
            StockItemID,
            Description,
            PackageTypeID,
            Quantity,
            UnitPrice,
            TaxRate,
            TaxAmount,
            LineProfit,
            ExtendedPrice,
            LastEditedBy
        )
        VALUES
        (
            @NewInvoiceLineID,
            @InvoiceID,
            @StockItemID,
            @Description,
            @PackageTypeID,
            @Quantity,
            @UnitPrice,
            @TaxRate,
            @TaxAmount,
            @LineProfit,
            @ExtendedPrice,
            @LastEditedBy
        );

        SELECT @NewInvoiceLineID AS InvoiceLineID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

-- Actualiza una línea del detalle de la venta.
CREATE OR ALTER PROCEDURE dbo.usp_Ventas_ActualizarDetalle
    @InvoiceLineID int,
    @InvoiceID int,
    @StockItemID int,
    @Description nvarchar(100),
    @PackageTypeID int,
    @Quantity int,
    @UnitPrice decimal(18, 2),
    @TaxRate decimal(18, 3),
    @TaxAmount decimal(18, 2),
    @LineProfit decimal(18, 2),
    @ExtendedPrice decimal(18, 2),
    @LastEditedBy int
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE dbo.src_DetalleFactura
        SET InvoiceID = @InvoiceID,
            StockItemID = @StockItemID,
            Description = @Description,
            PackageTypeID = @PackageTypeID,
            Quantity = @Quantity,
            UnitPrice = @UnitPrice,
            TaxRate = @TaxRate,
            TaxAmount = @TaxAmount,
            LineProfit = @LineProfit,
            ExtendedPrice = @ExtendedPrice,
            LastEditedBy = @LastEditedBy,
            LastEditedWhen = SYSDATETIME()
        WHERE InvoiceLineID = @InvoiceLineID;

        IF @@ROWCOUNT = 0
            THROW 50302, 'La línea de venta no existe.', 1;

        SELECT @InvoiceLineID AS InvoiceLineID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

-- Elimina una línea de la venta.
CREATE OR ALTER PROCEDURE dbo.usp_Ventas_EliminarDetalle
    @InvoiceLineID int
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM dbo.src_DetalleFactura
        WHERE InvoiceLineID = @InvoiceLineID;

        IF @@ROWCOUNT = 0
            THROW 50302, 'La línea de venta no existe.', 1;

        SELECT @InvoiceLineID AS InvoiceLineID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

-- Elimina primero las líneas y después el encabezado de la venta.
CREATE OR ALTER PROCEDURE dbo.usp_Ventas_Eliminar
    @InvoiceID int
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM dbo.src_DetalleFactura
        WHERE InvoiceID = @InvoiceID;

        DELETE FROM dbo.src_Factura
        WHERE InvoiceID = @InvoiceID;

        IF @@ROWCOUNT = 0
            THROW 50301, 'La venta no existe.', 1;

        SELECT @InvoiceID AS InvoiceID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO
