USE [WideWorldImporters];
GO

-- Sinónimos utilizados por el módulo de ventas.
IF OBJECT_ID('dbo.src_Factura', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_Factura FOR Sales.Invoices;');
GO

IF OBJECT_ID('dbo.src_DetalleFactura', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_DetalleFactura FOR Sales.InvoiceLines;');
GO

IF OBJECT_ID('dbo.src_Cliente', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_Cliente FOR Sales.Customers;');
GO

IF OBJECT_ID('dbo.src_MetodoEntrega', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_MetodoEntrega FOR Application.DeliveryMethods;');
GO

IF OBJECT_ID('dbo.src_Persona', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_Persona FOR Application.People;');
GO

IF OBJECT_ID('dbo.src_Producto', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_Producto FOR Warehouse.StockItems;');
GO

-- Lista las ventas. Los filtros son opcionales y se pueden combinar.
CREATE OR ALTER PROCEDURE dbo.usp_Ventas_Listar
    @CustomerName nvarchar(100) = NULL,
    @InvoiceDateFrom date = NULL,
    @InvoiceDateTo date = NULL,
    @MinimumInvoiceAmount decimal(18, 2) = NULL,
    @MaximumInvoiceAmount decimal(18, 2) = NULL,
    @DeliveryMethodID int = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT
            I.InvoiceID,
            I.InvoiceDate,
            C.CustomerID,
            C.CustomerName,
            DM.DeliveryMethodID,
            DM.DeliveryMethodName,
            SUM(IL.ExtendedPrice) AS InvoiceAmount
        FROM dbo.src_Factura AS I
        INNER JOIN dbo.src_Cliente AS C
            ON I.CustomerID = C.CustomerID
        INNER JOIN dbo.src_MetodoEntrega AS DM
            ON I.DeliveryMethodID = DM.DeliveryMethodID
        INNER JOIN dbo.src_DetalleFactura AS IL
            ON I.InvoiceID = IL.InvoiceID
        WHERE (@CustomerName IS NULL
            OR C.CustomerName LIKE '%' + @CustomerName + '%')
            AND (@InvoiceDateFrom IS NULL OR I.InvoiceDate >= @InvoiceDateFrom)
            AND (@InvoiceDateTo IS NULL OR I.InvoiceDate <= @InvoiceDateTo)
            AND (@DeliveryMethodID IS NULL
            OR I.DeliveryMethodID = @DeliveryMethodID)
        GROUP BY
            I.InvoiceID,
            I.InvoiceDate,
            C.CustomerID,
            C.CustomerName,
            DM.DeliveryMethodID,
            DM.DeliveryMethodName
        HAVING (@MinimumInvoiceAmount IS NULL
            OR SUM(IL.ExtendedPrice) >= @MinimumInvoiceAmount)
            AND (@MaximumInvoiceAmount IS NULL
            OR SUM(IL.ExtendedPrice) <= @MaximumInvoiceAmount)
        ORDER BY C.CustomerName ASC;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

-- Muestra una factura, devuelve primero el encabezado y después el detalle.
CREATE OR ALTER PROCEDURE dbo.usp_Ventas_ObtenerDetalle
    @InvoiceID int
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Encabezado de la factura.
        SELECT
            I.InvoiceID,
            C.CustomerID,
            C.CustomerName,
            C.WebsiteURL AS CustomerWebsiteURL,
            I.BillToCustomerID,
            BC.CustomerName AS BillToCustomerName,
            I.DeliveryMethodID,
            DM.DeliveryMethodName,
            I.CustomerPurchaseOrderNumber,
            I.ContactPersonID,
            CP.FullName AS ContactPerson,
            I.AccountsPersonID,
            AP.FullName AS AccountsPerson,
            I.SalespersonPersonID,
            SP.FullName AS SalesPerson,
            I.PackedByPersonID,
            PP.FullName AS PackedByPerson,
            CONVERT(char(10), I.InvoiceDate, 23) AS InvoiceDate,
            I.IsCreditNote,
            I.Comments,
            I.DeliveryInstructions,
            I.LastEditedBy
        FROM dbo.src_Factura AS I
        INNER JOIN dbo.src_Cliente AS C
            ON I.CustomerID = C.CustomerID
        INNER JOIN dbo.src_Cliente AS BC
            ON I.BillToCustomerID = BC.CustomerID
        INNER JOIN dbo.src_MetodoEntrega AS DM
            ON I.DeliveryMethodID = DM.DeliveryMethodID
        INNER JOIN dbo.src_Persona AS CP
            ON I.ContactPersonID = CP.PersonID
        INNER JOIN dbo.src_Persona AS AP
            ON I.AccountsPersonID = AP.PersonID
        INNER JOIN dbo.src_Persona AS SP
            ON I.SalespersonPersonID = SP.PersonID
        INNER JOIN dbo.src_Persona AS PP
            ON I.PackedByPersonID = PP.PersonID
        WHERE I.InvoiceID = @InvoiceID;

        -- Detalle de la factura.
        SELECT
            IL.InvoiceLineID,
            SI.StockItemID,
            SI.StockItemName,
            IL.Quantity,
            IL.UnitPrice,
            IL.TaxRate,
            IL.TaxAmount,
            IL.ExtendedPrice
        FROM dbo.src_DetalleFactura AS IL
        INNER JOIN dbo.src_Producto AS SI
            ON IL.StockItemID = SI.StockItemID
        WHERE IL.InvoiceID = @InvoiceID
        ORDER BY IL.InvoiceLineID ASC;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

-- Devuelve los catálogos utilizados en el formulario de ventas.
CREATE OR ALTER PROCEDURE dbo.usp_Ventas_ObtenerCatalogos
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT
            CustomerID AS [Value],
            CustomerName AS [Label]
        FROM dbo.src_Cliente
        ORDER BY CustomerName ASC;

        SELECT
            PersonID AS [Value],
            FullName AS [Label]
        FROM dbo.src_Persona
        ORDER BY FullName ASC;

        SELECT
            DeliveryMethodID AS [Value],
            DeliveryMethodName AS [Label]
        FROM dbo.src_MetodoEntrega
        ORDER BY DeliveryMethodName ASC;

        SELECT
            StockItemID AS [Value],
            StockItemName AS [Label],
            UnitPrice,
            TaxRate
        FROM dbo.src_Producto
        ORDER BY StockItemName ASC;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO
