:on error exit
SET NOCOUNT ON;

USE [WideWorldImporters];
GO

IF SCHEMA_ID(N'Corporativo') IS NULL
    EXEC(N'CREATE SCHEMA [Corporativo] AUTHORIZATION [dbo];');
GO

CREATE OR ALTER VIEW Corporativo.v_Invoices
AS
SELECT
    CONVERT(int, 1) AS SucursalID,
    InvoiceID, CustomerID, BillToCustomerID, OrderID, DeliveryMethodID,
    ContactPersonID, AccountsPersonID, SalespersonPersonID, PackedByPersonID,
    InvoiceDate, CustomerPurchaseOrderNumber, IsCreditNote, CreditNoteReason,
    Comments, DeliveryInstructions, InternalComments, TotalDryItems,
    TotalChillerItems, DeliveryRun, RunPosition, ReturnedDeliveryData,
    LastEditedBy, LastEditedWhen, VersionVenta
FROM sj.Invoices
UNION ALL
SELECT
    CONVERT(int, 2) AS SucursalID,
    InvoiceID, CustomerID, BillToCustomerID, OrderID, DeliveryMethodID,
    ContactPersonID, AccountsPersonID, SalespersonPersonID, PackedByPersonID,
    InvoiceDate, CustomerPurchaseOrderNumber, IsCreditNote, CreditNoteReason,
    Comments, DeliveryInstructions, InternalComments, TotalDryItems,
    TotalChillerItems, DeliveryRun, RunPosition, ReturnedDeliveryData,
    LastEditedBy, LastEditedWhen, VersionVenta
FROM limon.Invoices;
GO

CREATE OR ALTER VIEW Corporativo.v_InvoiceLines
AS
SELECT
    CONVERT(int, 1) AS SucursalID,
    InvoiceLineID, InvoiceID, StockItemID, Description, PackageTypeID,
    Quantity, UnitPrice, TaxRate, TaxAmount, LineProfit, ExtendedPrice,
    LastEditedBy, LastEditedWhen
FROM sj.InvoiceLines
UNION ALL
SELECT
    CONVERT(int, 2) AS SucursalID,
    InvoiceLineID, InvoiceID, StockItemID, Description, PackageTypeID,
    Quantity, UnitPrice, TaxRate, TaxAmount, LineProfit, ExtendedPrice,
    LastEditedBy, LastEditedWhen
FROM limon.InvoiceLines;
GO

CREATE OR ALTER VIEW Corporativo.v_CustomerTransactions
AS
SELECT
    CONVERT(int, 1) AS SucursalID,
    CustomerTransactionID, CustomerID, TransactionTypeID, InvoiceID,
    PaymentMethodID, TransactionDate, AmountExcludingTax, TaxAmount,
    TransactionAmount, OutstandingBalance, FinalizationDate,
    LastEditedBy, LastEditedWhen
FROM sj.CustomerTransactions
UNION ALL
SELECT
    CONVERT(int, 2) AS SucursalID,
    CustomerTransactionID, CustomerID, TransactionTypeID, InvoiceID,
    PaymentMethodID, TransactionDate, AmountExcludingTax, TaxAmount,
    TransactionAmount, OutstandingBalance, FinalizationDate,
    LastEditedBy, LastEditedWhen
FROM limon.CustomerTransactions;
GO

CREATE OR ALTER VIEW Corporativo.v_PurchaseOrders
AS
SELECT
    CONVERT(int, 1) AS SucursalID,
    PurchaseOrderID, SupplierID, OrderDate, DeliveryMethodID,
    ContactPersonID, ExpectedDeliveryDate, IsOrderFinalized,
    LastEditedBy, LastEditedWhen
FROM sj.PurchaseOrders
UNION ALL
SELECT
    CONVERT(int, 2) AS SucursalID,
    PurchaseOrderID, SupplierID, OrderDate, DeliveryMethodID,
    ContactPersonID, ExpectedDeliveryDate, IsOrderFinalized,
    LastEditedBy, LastEditedWhen
FROM limon.PurchaseOrders;
GO

CREATE OR ALTER VIEW Corporativo.v_PurchaseOrderLines
AS
SELECT
    CONVERT(int, 1) AS SucursalID,
    PurchaseOrderLineID, PurchaseOrderID, StockItemID, OrderedOuters,
    Description, ReceivedOuters, PackageTypeID, ExpectedUnitPricePerOuter,
    LastReceiptDate, IsOrderLineFinalized, LastEditedBy, LastEditedWhen
FROM sj.PurchaseOrderLines
UNION ALL
SELECT
    CONVERT(int, 2) AS SucursalID,
    PurchaseOrderLineID, PurchaseOrderID, StockItemID, OrderedOuters,
    Description, ReceivedOuters, PackageTypeID, ExpectedUnitPricePerOuter,
    LastReceiptDate, IsOrderLineFinalized, LastEditedBy, LastEditedWhen
FROM limon.PurchaseOrderLines;
GO

CREATE OR ALTER VIEW Corporativo.v_SupplierTransactions
AS
SELECT
    CONVERT(int, 1) AS SucursalID,
    SupplierTransactionID, SupplierID, TransactionTypeID, PurchaseOrderID,
    PaymentMethodID, SupplierInvoiceNumber, TransactionDate,
    AmountExcludingTax, TaxAmount, TransactionAmount, OutstandingBalance,
    FinalizationDate, LastEditedBy, LastEditedWhen
FROM sj.SupplierTransactions
UNION ALL
SELECT
    CONVERT(int, 2) AS SucursalID,
    SupplierTransactionID, SupplierID, TransactionTypeID, PurchaseOrderID,
    PaymentMethodID, SupplierInvoiceNumber, TransactionDate,
    AmountExcludingTax, TaxAmount, TransactionAmount, OutstandingBalance,
    FinalizationDate, LastEditedBy, LastEditedWhen
FROM limon.SupplierTransactions;
GO

CREATE OR ALTER VIEW Corporativo.v_StockItemHoldings
AS
SELECT
    CONVERT(int, 1) AS SucursalID,
    StockItemID, QuantityOnHand, BinLocation, LastStocktakeQuantity,
    LastCostPrice, ReorderLevel, TargetStockLevel,
    LastEditedBy, LastEditedWhen, VersionExistencias
FROM sj.StockItemHoldings
UNION ALL
SELECT
    CONVERT(int, 2) AS SucursalID,
    StockItemID, QuantityOnHand, BinLocation, LastStocktakeQuantity,
    LastCostPrice, ReorderLevel, TargetStockLevel,
    LastEditedBy, LastEditedWhen, VersionExistencias
FROM limon.StockItemHoldings;
GO

