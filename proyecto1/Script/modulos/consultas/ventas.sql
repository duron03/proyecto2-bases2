USE [WideWorldImporters];
GO

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

    SELECT
        I.InvoiceID,
        I.InvoiceDate,
        C.CustomerID,
        C.CustomerName,
        DM.DeliveryMethodID,
        DM.DeliveryMethodName,
        SUM(IL.ExtendedPrice) AS InvoiceAmount,
        I.VersionVenta
    FROM dbo.src_Factura AS I
    INNER JOIN dbo.src_Cliente AS C
        ON I.CustomerID = C.CustomerID
    INNER JOIN dbo.src_MetodoEntrega AS DM
        ON I.DeliveryMethodID = DM.DeliveryMethodID
    INNER JOIN dbo.src_DetalleFactura AS IL
        ON I.InvoiceID = IL.InvoiceID
    WHERE (@CustomerName IS NULL OR C.CustomerName LIKE N'%' + @CustomerName + N'%')
      AND (@InvoiceDateFrom IS NULL OR I.InvoiceDate >= @InvoiceDateFrom)
      AND (@InvoiceDateTo IS NULL OR I.InvoiceDate <= @InvoiceDateTo)
      AND (@DeliveryMethodID IS NULL OR I.DeliveryMethodID = @DeliveryMethodID)
    GROUP BY
        I.InvoiceID, I.InvoiceDate, C.CustomerID, C.CustomerName,
        DM.DeliveryMethodID, DM.DeliveryMethodName, I.VersionVenta
    HAVING (@MinimumInvoiceAmount IS NULL OR SUM(IL.ExtendedPrice) >= @MinimumInvoiceAmount)
       AND (@MaximumInvoiceAmount IS NULL OR SUM(IL.ExtendedPrice) <= @MaximumInvoiceAmount)
    ORDER BY C.CustomerName, I.InvoiceDate DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Ventas_ObtenerDetalle
    @InvoiceID int
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        I.InvoiceID,
        C.CustomerID,
        C.CustomerName,
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
        I.OrderID,
        I.IsCreditNote,
        I.CreditNoteReason,
        I.Comments,
        I.DeliveryInstructions,
        I.InternalComments,
        I.DeliveryRun,
        I.RunPosition,
        I.ReturnedDeliveryData,
        I.LastEditedBy,
        I.VersionVenta
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
    ORDER BY IL.InvoiceLineID;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Ventas_ObtenerCatalogos
    @InvoiceID int = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @InvoiceID IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM dbo.src_Factura WHERE InvoiceID = @InvoiceID)
        THROW 50301, 'La factura indicada no existe en esta sucursal.', 1;

    SELECT CustomerID AS [Value], CustomerName AS [Label]
    FROM dbo.src_Cliente AS C
    WHERE C.Activo = 1
       OR EXISTS
       (
           SELECT 1
           FROM dbo.src_Factura AS I
           WHERE I.InvoiceID = @InvoiceID
             AND I.CustomerID = C.CustomerID
       )
    ORDER BY CustomerName;

    SELECT PersonID AS [Value], FullName AS [Label]
    FROM dbo.src_Persona
    ORDER BY FullName;

    SELECT DeliveryMethodID AS [Value], DeliveryMethodName AS [Label]
    FROM dbo.src_MetodoEntrega
    ORDER BY DeliveryMethodName;

    SELECT StockItemID AS [Value], StockItemName AS [Label], UnitPrice, TaxRate
    FROM dbo.src_Producto AS SI
    WHERE SI.Activo = 1
       OR EXISTS
       (
           SELECT 1
           FROM dbo.src_DetalleFactura AS IL
           WHERE IL.InvoiceID = @InvoiceID
             AND IL.StockItemID = SI.StockItemID
       )
    ORDER BY StockItemName;
END;
GO
