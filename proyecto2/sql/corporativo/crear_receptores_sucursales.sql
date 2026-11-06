:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;

USE [WideWorldImporters];
GO

IF SCHEMA_ID(N'sj') IS NULL EXEC(N'CREATE SCHEMA [sj] AUTHORIZATION [dbo];');
IF SCHEMA_ID(N'limon') IS NULL EXEC(N'CREATE SCHEMA [limon] AUTHORIZATION [dbo];');
GO

IF OBJECT_ID(N'sj.Orders', N'U') IS NULL
BEGIN
    CREATE TABLE sj.Orders
    (
        OrderID int NOT NULL,
        CustomerID int NOT NULL,
        OrderDate date NOT NULL,
        LastEditedBy int NOT NULL,
        LastEditedWhen datetime2(7) NOT NULL,
        CONSTRAINT PK_sj_Orders PRIMARY KEY (OrderID)
    );
END;

IF OBJECT_ID(N'sj.PurchaseOrders', N'U') IS NULL
BEGIN
    CREATE TABLE sj.PurchaseOrders
    (
        PurchaseOrderID int NOT NULL,
        SupplierID int NOT NULL,
        OrderDate date NOT NULL,
        DeliveryMethodID int NOT NULL,
        ContactPersonID int NOT NULL,
        ExpectedDeliveryDate date NULL,
        IsOrderFinalized bit NOT NULL,
        LastEditedBy int NOT NULL,
        LastEditedWhen datetime2(7) NOT NULL,
        CONSTRAINT PK_sj_PurchaseOrders PRIMARY KEY (PurchaseOrderID)
    );
END;

IF OBJECT_ID(N'sj.Invoices', N'U') IS NULL
BEGIN
    CREATE TABLE sj.Invoices
    (
        InvoiceID int NOT NULL,
        CustomerID int NOT NULL,
        BillToCustomerID int NOT NULL,
        OrderID int NULL,
        DeliveryMethodID int NOT NULL,
        ContactPersonID int NOT NULL,
        AccountsPersonID int NOT NULL,
        SalespersonPersonID int NOT NULL,
        PackedByPersonID int NOT NULL,
        InvoiceDate date NOT NULL,
        CustomerPurchaseOrderNumber nvarchar(20) NULL,
        IsCreditNote bit NOT NULL,
        CreditNoteReason nvarchar(max) NULL,
        Comments nvarchar(max) NULL,
        DeliveryInstructions nvarchar(max) NULL,
        InternalComments nvarchar(max) NULL,
        TotalDryItems int NOT NULL,
        TotalChillerItems int NOT NULL,
        DeliveryRun nvarchar(5) NULL,
        RunPosition nvarchar(5) NULL,
        ReturnedDeliveryData nvarchar(max) NULL,
        LastEditedBy int NOT NULL,
        LastEditedWhen datetime2(7) NOT NULL,
        VersionVenta int NOT NULL,
        CONSTRAINT PK_sj_Invoices PRIMARY KEY (InvoiceID)
    );

    CREATE INDEX IX_sj_Invoices_CustomerDate ON sj.Invoices(CustomerID, InvoiceDate);
END;

IF OBJECT_ID(N'sj.InvoiceLines', N'U') IS NULL
BEGIN
    CREATE TABLE sj.InvoiceLines
    (
        InvoiceLineID int NOT NULL,
        InvoiceID int NOT NULL,
        StockItemID int NOT NULL,
        Description nvarchar(100) NOT NULL,
        PackageTypeID int NOT NULL,
        Quantity int NOT NULL,
        UnitPrice decimal(18,2) NULL,
        TaxRate decimal(18,3) NOT NULL,
        TaxAmount decimal(18,2) NOT NULL,
        LineProfit decimal(18,2) NOT NULL,
        ExtendedPrice decimal(18,2) NOT NULL,
        LastEditedBy int NOT NULL,
        LastEditedWhen datetime2(7) NOT NULL,
        CONSTRAINT PK_sj_InvoiceLines PRIMARY KEY (InvoiceLineID)
    );

    CREATE INDEX IX_sj_InvoiceLines_InvoiceID ON sj.InvoiceLines(InvoiceID);
END;

IF OBJECT_ID(N'sj.CustomerTransactions', N'U') IS NULL
BEGIN
    CREATE TABLE sj.CustomerTransactions
    (
        CustomerTransactionID int NOT NULL,
        CustomerID int NOT NULL,
        TransactionTypeID int NOT NULL,
        InvoiceID int NULL,
        PaymentMethodID int NULL,
        TransactionDate date NOT NULL,
        AmountExcludingTax decimal(18,2) NOT NULL,
        TaxAmount decimal(18,2) NOT NULL,
        TransactionAmount decimal(18,2) NOT NULL,
        OutstandingBalance decimal(18,2) NOT NULL,
        FinalizationDate date NULL,
        LastEditedBy int NOT NULL,
        LastEditedWhen datetime2(7) NOT NULL,
        CONSTRAINT PK_sj_CustomerTransactions PRIMARY KEY (CustomerTransactionID)
    );
END;

IF OBJECT_ID(N'sj.PurchaseOrderLines', N'U') IS NULL
BEGIN
    CREATE TABLE sj.PurchaseOrderLines
    (
        PurchaseOrderLineID int NOT NULL,
        PurchaseOrderID int NOT NULL,
        StockItemID int NOT NULL,
        OrderedOuters int NOT NULL,
        Description nvarchar(100) NOT NULL,
        ReceivedOuters int NOT NULL,
        PackageTypeID int NOT NULL,
        ExpectedUnitPricePerOuter decimal(18,2) NULL,
        LastReceiptDate date NULL,
        IsOrderLineFinalized bit NOT NULL,
        LastEditedBy int NOT NULL,
        LastEditedWhen datetime2(7) NOT NULL,
        CONSTRAINT PK_sj_PurchaseOrderLines PRIMARY KEY (PurchaseOrderLineID)
    );
END;

IF OBJECT_ID(N'sj.SupplierTransactions', N'U') IS NULL
BEGIN
    CREATE TABLE sj.SupplierTransactions
    (
        SupplierTransactionID int NOT NULL,
        SupplierID int NOT NULL,
        TransactionTypeID int NOT NULL,
        PurchaseOrderID int NULL,
        PaymentMethodID int NULL,
        SupplierInvoiceNumber nvarchar(20) NULL,
        TransactionDate date NOT NULL,
        AmountExcludingTax decimal(18,2) NOT NULL,
        TaxAmount decimal(18,2) NOT NULL,
        TransactionAmount decimal(18,2) NOT NULL,
        OutstandingBalance decimal(18,2) NOT NULL,
        FinalizationDate date NULL,
        LastEditedBy int NOT NULL,
        LastEditedWhen datetime2(7) NOT NULL,
        CONSTRAINT PK_sj_SupplierTransactions PRIMARY KEY (SupplierTransactionID)
    );
END;

IF OBJECT_ID(N'sj.StockItemHoldings', N'U') IS NULL
BEGIN
    CREATE TABLE sj.StockItemHoldings
    (
        StockItemID int NOT NULL,
        QuantityOnHand int NOT NULL,
        BinLocation nvarchar(20) NOT NULL,
        LastStocktakeQuantity int NOT NULL,
        LastCostPrice decimal(18,2) NOT NULL,
        ReorderLevel int NOT NULL,
        TargetStockLevel int NOT NULL,
        LastEditedBy int NOT NULL,
        LastEditedWhen datetime2(7) NOT NULL,
        VersionExistencias int NOT NULL,
        CONSTRAINT PK_sj_StockItemHoldings PRIMARY KEY (StockItemID)
    );
END;

IF OBJECT_ID(N'sj.LatidoSucursal', N'U') IS NULL
BEGIN
    CREATE TABLE sj.LatidoSucursal
    (
        SucursalID int NOT NULL,
        FechaUtc datetime2(7) NOT NULL,
        CONSTRAINT PK_sj_LatidoSucursal PRIMARY KEY (SucursalID)
    );
END;
GO

IF OBJECT_ID(N'limon.Orders', N'U') IS NULL
BEGIN
    CREATE TABLE limon.Orders
    (
        OrderID int NOT NULL,
        CustomerID int NOT NULL,
        OrderDate date NOT NULL,
        LastEditedBy int NOT NULL,
        LastEditedWhen datetime2(7) NOT NULL,
        CONSTRAINT PK_limon_Orders PRIMARY KEY (OrderID)
    );
END;

IF OBJECT_ID(N'limon.PurchaseOrders', N'U') IS NULL
BEGIN
    CREATE TABLE limon.PurchaseOrders
    (
        PurchaseOrderID int NOT NULL,
        SupplierID int NOT NULL,
        OrderDate date NOT NULL,
        DeliveryMethodID int NOT NULL,
        ContactPersonID int NOT NULL,
        ExpectedDeliveryDate date NULL,
        IsOrderFinalized bit NOT NULL,
        LastEditedBy int NOT NULL,
        LastEditedWhen datetime2(7) NOT NULL,
        CONSTRAINT PK_limon_PurchaseOrders PRIMARY KEY (PurchaseOrderID)
    );
END;

IF OBJECT_ID(N'limon.Invoices', N'U') IS NULL
BEGIN
    CREATE TABLE limon.Invoices
    (
        InvoiceID int NOT NULL,
        CustomerID int NOT NULL,
        BillToCustomerID int NOT NULL,
        OrderID int NULL,
        DeliveryMethodID int NOT NULL,
        ContactPersonID int NOT NULL,
        AccountsPersonID int NOT NULL,
        SalespersonPersonID int NOT NULL,
        PackedByPersonID int NOT NULL,
        InvoiceDate date NOT NULL,
        CustomerPurchaseOrderNumber nvarchar(20) NULL,
        IsCreditNote bit NOT NULL,
        CreditNoteReason nvarchar(max) NULL,
        Comments nvarchar(max) NULL,
        DeliveryInstructions nvarchar(max) NULL,
        InternalComments nvarchar(max) NULL,
        TotalDryItems int NOT NULL,
        TotalChillerItems int NOT NULL,
        DeliveryRun nvarchar(5) NULL,
        RunPosition nvarchar(5) NULL,
        ReturnedDeliveryData nvarchar(max) NULL,
        LastEditedBy int NOT NULL,
        LastEditedWhen datetime2(7) NOT NULL,
        VersionVenta int NOT NULL,
        CONSTRAINT PK_limon_Invoices PRIMARY KEY (InvoiceID)
    );

    CREATE INDEX IX_limon_Invoices_CustomerDate ON limon.Invoices(CustomerID, InvoiceDate);
END;

IF OBJECT_ID(N'limon.InvoiceLines', N'U') IS NULL
BEGIN
    CREATE TABLE limon.InvoiceLines
    (
        InvoiceLineID int NOT NULL,
        InvoiceID int NOT NULL,
        StockItemID int NOT NULL,
        Description nvarchar(100) NOT NULL,
        PackageTypeID int NOT NULL,
        Quantity int NOT NULL,
        UnitPrice decimal(18,2) NULL,
        TaxRate decimal(18,3) NOT NULL,
        TaxAmount decimal(18,2) NOT NULL,
        LineProfit decimal(18,2) NOT NULL,
        ExtendedPrice decimal(18,2) NOT NULL,
        LastEditedBy int NOT NULL,
        LastEditedWhen datetime2(7) NOT NULL,
        CONSTRAINT PK_limon_InvoiceLines PRIMARY KEY (InvoiceLineID)
    );

    CREATE INDEX IX_limon_InvoiceLines_InvoiceID ON limon.InvoiceLines(InvoiceID);
END;

IF OBJECT_ID(N'limon.CustomerTransactions', N'U') IS NULL
BEGIN
    CREATE TABLE limon.CustomerTransactions
    (
        CustomerTransactionID int NOT NULL,
        CustomerID int NOT NULL,
        TransactionTypeID int NOT NULL,
        InvoiceID int NULL,
        PaymentMethodID int NULL,
        TransactionDate date NOT NULL,
        AmountExcludingTax decimal(18,2) NOT NULL,
        TaxAmount decimal(18,2) NOT NULL,
        TransactionAmount decimal(18,2) NOT NULL,
        OutstandingBalance decimal(18,2) NOT NULL,
        FinalizationDate date NULL,
        LastEditedBy int NOT NULL,
        LastEditedWhen datetime2(7) NOT NULL,
        CONSTRAINT PK_limon_CustomerTransactions PRIMARY KEY (CustomerTransactionID)
    );
END;

IF OBJECT_ID(N'limon.PurchaseOrderLines', N'U') IS NULL
BEGIN
    CREATE TABLE limon.PurchaseOrderLines
    (
        PurchaseOrderLineID int NOT NULL,
        PurchaseOrderID int NOT NULL,
        StockItemID int NOT NULL,
        OrderedOuters int NOT NULL,
        Description nvarchar(100) NOT NULL,
        ReceivedOuters int NOT NULL,
        PackageTypeID int NOT NULL,
        ExpectedUnitPricePerOuter decimal(18,2) NULL,
        LastReceiptDate date NULL,
        IsOrderLineFinalized bit NOT NULL,
        LastEditedBy int NOT NULL,
        LastEditedWhen datetime2(7) NOT NULL,
        CONSTRAINT PK_limon_PurchaseOrderLines PRIMARY KEY (PurchaseOrderLineID)
    );
END;

IF OBJECT_ID(N'limon.SupplierTransactions', N'U') IS NULL
BEGIN
    CREATE TABLE limon.SupplierTransactions
    (
        SupplierTransactionID int NOT NULL,
        SupplierID int NOT NULL,
        TransactionTypeID int NOT NULL,
        PurchaseOrderID int NULL,
        PaymentMethodID int NULL,
        SupplierInvoiceNumber nvarchar(20) NULL,
        TransactionDate date NOT NULL,
        AmountExcludingTax decimal(18,2) NOT NULL,
        TaxAmount decimal(18,2) NOT NULL,
        TransactionAmount decimal(18,2) NOT NULL,
        OutstandingBalance decimal(18,2) NOT NULL,
        FinalizationDate date NULL,
        LastEditedBy int NOT NULL,
        LastEditedWhen datetime2(7) NOT NULL,
        CONSTRAINT PK_limon_SupplierTransactions PRIMARY KEY (SupplierTransactionID)
    );
END;

IF OBJECT_ID(N'limon.StockItemHoldings', N'U') IS NULL
BEGIN
    CREATE TABLE limon.StockItemHoldings
    (
        StockItemID int NOT NULL,
        QuantityOnHand int NOT NULL,
        BinLocation nvarchar(20) NOT NULL,
        LastStocktakeQuantity int NOT NULL,
        LastCostPrice decimal(18,2) NOT NULL,
        ReorderLevel int NOT NULL,
        TargetStockLevel int NOT NULL,
        LastEditedBy int NOT NULL,
        LastEditedWhen datetime2(7) NOT NULL,
        VersionExistencias int NOT NULL,
        CONSTRAINT PK_limon_StockItemHoldings PRIMARY KEY (StockItemID)
    );
END;

IF OBJECT_ID(N'limon.LatidoSucursal', N'U') IS NULL
BEGIN
    CREATE TABLE limon.LatidoSucursal
    (
        SucursalID int NOT NULL,
        FechaUtc datetime2(7) NOT NULL,
        CONSTRAINT PK_limon_LatidoSucursal PRIMARY KEY (SucursalID)
    );
END;
GO

SELECT
    schemaObject.name AS SchemaName,
    tableObject.name AS TableName,
    SUM(partitionObject.rows) AS TotalFilas
FROM sys.tables AS tableObject
INNER JOIN sys.schemas AS schemaObject
    ON schemaObject.schema_id = tableObject.schema_id
LEFT JOIN sys.partitions AS partitionObject
    ON partitionObject.object_id = tableObject.object_id
   AND partitionObject.index_id IN (0, 1)
WHERE schemaObject.name IN (N'sj', N'limon')
GROUP BY schemaObject.name, tableObject.name
ORDER BY schemaObject.name, tableObject.name;

