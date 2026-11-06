:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

USE [WideWorldImporters];
GO

DECLARE @NodeCode varchar(2) = '$(NodeCode)';
DECLARE @Action varchar(8) = '$(Action)';
DECLARE @InvoiceID int = CASE @NodeCode WHEN 'SJ' THEN 1499999998 ELSE 1999999998 END;
DECLARE @InvoiceLineID int = @InvoiceID;

IF @NodeCode NOT IN ('SJ', 'LI')
    THROW 51360, N'NodeCode debe ser SJ o LI.', 1;

IF @Action NOT IN ('INSERT', 'UPDATE', 'DELETE')
    THROW 51361, N'Action debe ser INSERT, UPDATE o DELETE.', 1;

IF NOT EXISTS (SELECT 1 FROM Control.Nodo WHERE Id = 1 AND Codigo = @NodeCode)
    THROW 51362, N'La identidad de la sucursal no coincide.', 1;

IF @Action = 'INSERT'
BEGIN
    IF EXISTS (SELECT 1 FROM Sales.Invoices WHERE InvoiceID = @InvoiceID)
        THROW 51363, N'El fixture ya existe.', 1;

    DECLARE @CustomerID int = (SELECT MIN(CustomerID) FROM Sales.Customers WHERE Activo = 1);
    DECLARE @DeliveryMethodID int = (SELECT MIN(DeliveryMethodID) FROM Application.DeliveryMethods);
    DECLARE @PersonID int = (SELECT MIN(PersonID) FROM Application.People);
    DECLARE @StockItemID int = (SELECT MIN(StockItemID) FROM Warehouse.StockItems WHERE Activo = 1);
    DECLARE @PackageTypeID int = (SELECT MIN(PackageTypeID) FROM Warehouse.PackageTypes);

    BEGIN TRANSACTION;

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
        @InvoiceID, @CustomerID, @CustomerID, NULL, @DeliveryMethodID,
        @PersonID, @PersonID, @PersonID, @PersonID,
        CONVERT(date, SYSUTCDATETIME()), N'P2-T05-' + @NodeCode, 0,
        NULL, NULL, NULL, NULL,
        1, 0, NULL, NULL,
        NULL, @PersonID, SYSUTCDATETIME(), 1
    );

    INSERT INTO Sales.InvoiceLines
    (
        InvoiceLineID, InvoiceID, StockItemID, Description, PackageTypeID,
        Quantity, UnitPrice, TaxRate, TaxAmount, LineProfit, ExtendedPrice,
        LastEditedBy, LastEditedWhen
    )
    VALUES
    (
        @InvoiceLineID, @InvoiceID, @StockItemID, N'Fixture tecnico T05', @PackageTypeID,
        1, 1.00, 0.000, 0.00, 0.00, 1.00,
        @PersonID, SYSUTCDATETIME()
    );

    COMMIT TRANSACTION;
END;

IF @Action = 'UPDATE'
BEGIN
    UPDATE Sales.Invoices
    SET Comments = N'P2_REPLICA_' + @NodeCode + N'_UPDATE',
        VersionVenta = VersionVenta + 1,
        LastEditedWhen = SYSUTCDATETIME()
    WHERE InvoiceID = @InvoiceID
      AND VersionVenta = 1;

    IF @@ROWCOUNT <> 1
        THROW 51364, N'No se encontro el fixture en version 1.', 1;
END;

IF @Action = 'DELETE'
BEGIN
    BEGIN TRANSACTION;
    DELETE FROM Sales.InvoiceLines WHERE InvoiceLineID = @InvoiceLineID;
    DELETE FROM Sales.Invoices WHERE InvoiceID = @InvoiceID;

    IF @@ROWCOUNT <> 1
        THROW 51365, N'No se encontro el fixture para borrar.', 1;

    COMMIT TRANSACTION;
END;

SELECT
    @@SERVERNAME AS ServerName,
    @NodeCode AS NodeCode,
    @Action AS ActionName,
    @InvoiceID AS InvoiceID,
    N'FIXTURE_APPLIED' AS Result;
