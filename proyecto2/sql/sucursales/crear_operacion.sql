:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

USE [WideWorldImporters];
GO

IF OBJECT_ID(N'Sales.Orders', N'U') IS NULL
BEGIN
    CREATE TABLE Sales.Orders
    (
        OrderID int NOT NULL,
        CustomerID int NOT NULL,
        OrderDate date NOT NULL,
        LastEditedBy int NOT NULL,
        LastEditedWhen datetime2(7) NOT NULL,
        CONSTRAINT PK_Orders PRIMARY KEY (OrderID)
    );

    CREATE INDEX IX_Orders_CustomerDate ON Sales.Orders(CustomerID, OrderDate);
END;

IF OBJECT_ID(N'Purchasing.PurchaseOrders', N'U') IS NULL
BEGIN
    CREATE TABLE Purchasing.PurchaseOrders
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
        CONSTRAINT PK_PurchaseOrders PRIMARY KEY (PurchaseOrderID)
    );

    CREATE INDEX IX_PurchaseOrders_SupplierDate
        ON Purchasing.PurchaseOrders(SupplierID, OrderDate);
END;

IF OBJECT_ID(N'Sales.Invoices', N'U') IS NULL
BEGIN
    CREATE TABLE Sales.Invoices
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
        LastEditedWhen datetime2(7) NOT NULL
            CONSTRAINT DF_Invoices_LastEditedWhen DEFAULT (SYSUTCDATETIME()),
        VersionVenta int NOT NULL CONSTRAINT DF_Invoices_Version DEFAULT (1),
        CONSTRAINT PK_Invoices PRIMARY KEY (InvoiceID),
        CONSTRAINT CK_Invoices_Version CHECK (VersionVenta > 0),
        CONSTRAINT CK_Invoices_ItemCounts CHECK (TotalDryItems >= 0 AND TotalChillerItems >= 0)
    );

    CREATE INDEX IX_Invoices_CustomerDate ON Sales.Invoices(CustomerID, InvoiceDate);
    CREATE INDEX IX_Invoices_BillToCustomer ON Sales.Invoices(BillToCustomerID);
    CREATE INDEX IX_Invoices_OrderID ON Sales.Invoices(OrderID) WHERE OrderID IS NOT NULL;
END;

IF OBJECT_ID(N'Sales.InvoiceLines', N'U') IS NULL
BEGIN
    CREATE TABLE Sales.InvoiceLines
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
        LastEditedWhen datetime2(7) NOT NULL
            CONSTRAINT DF_InvoiceLines_LastEditedWhen DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_InvoiceLines PRIMARY KEY (InvoiceLineID),
        CONSTRAINT CK_InvoiceLines_Quantity CHECK (Quantity > 0),
        CONSTRAINT CK_InvoiceLines_TaxRate CHECK (TaxRate >= 0)
    );

    CREATE INDEX IX_InvoiceLines_InvoiceID ON Sales.InvoiceLines(InvoiceID);
    CREATE INDEX IX_InvoiceLines_StockItemID ON Sales.InvoiceLines(StockItemID);
END;

IF OBJECT_ID(N'Sales.CustomerTransactions', N'U') IS NULL
BEGIN
    CREATE TABLE Sales.CustomerTransactions
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
        CONSTRAINT PK_CustomerTransactions PRIMARY KEY (CustomerTransactionID)
    );

    CREATE INDEX IX_CustomerTransactions_CustomerDate
        ON Sales.CustomerTransactions(CustomerID, TransactionDate);
    CREATE INDEX IX_CustomerTransactions_InvoiceID
        ON Sales.CustomerTransactions(InvoiceID) WHERE InvoiceID IS NOT NULL;
END;

IF OBJECT_ID(N'Purchasing.PurchaseOrderLines', N'U') IS NULL
BEGIN
    CREATE TABLE Purchasing.PurchaseOrderLines
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
        CONSTRAINT PK_PurchaseOrderLines PRIMARY KEY (PurchaseOrderLineID),
        CONSTRAINT CK_PurchaseOrderLines_Quantities CHECK (OrderedOuters >= 0 AND ReceivedOuters >= 0)
    );

    CREATE INDEX IX_PurchaseOrderLines_OrderID
        ON Purchasing.PurchaseOrderLines(PurchaseOrderID);
    CREATE INDEX IX_PurchaseOrderLines_StockItemID
        ON Purchasing.PurchaseOrderLines(StockItemID);
END;

IF OBJECT_ID(N'Purchasing.SupplierTransactions', N'U') IS NULL
BEGIN
    CREATE TABLE Purchasing.SupplierTransactions
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
        CONSTRAINT PK_SupplierTransactions PRIMARY KEY (SupplierTransactionID)
    );

    CREATE INDEX IX_SupplierTransactions_SupplierDate
        ON Purchasing.SupplierTransactions(SupplierID, TransactionDate);
    CREATE INDEX IX_SupplierTransactions_PurchaseOrderID
        ON Purchasing.SupplierTransactions(PurchaseOrderID) WHERE PurchaseOrderID IS NOT NULL;
END;

IF OBJECT_ID(N'Warehouse.StockItemHoldings', N'U') IS NULL
BEGIN
    CREATE TABLE Warehouse.StockItemHoldings
    (
        StockItemID int NOT NULL,
        QuantityOnHand int NOT NULL,
        BinLocation nvarchar(20) NOT NULL,
        LastStocktakeQuantity int NOT NULL,
        LastCostPrice decimal(18,2) NOT NULL,
        ReorderLevel int NOT NULL,
        TargetStockLevel int NOT NULL,
        LastEditedBy int NOT NULL,
        LastEditedWhen datetime2(7) NOT NULL
            CONSTRAINT DF_StockItemHoldings_LastEditedWhen DEFAULT (SYSUTCDATETIME()),
        VersionExistencias int NOT NULL CONSTRAINT DF_StockItemHoldings_Version DEFAULT (1),
        CONSTRAINT PK_StockItemHoldings PRIMARY KEY (StockItemID),
        CONSTRAINT CK_StockItemHoldings_Values CHECK
        (
            QuantityOnHand >= 0
            AND LastStocktakeQuantity >= 0
            AND LastCostPrice >= 0
            AND ReorderLevel >= 0
            AND TargetStockLevel >= 0
        ),
        CONSTRAINT CK_StockItemHoldings_Version CHECK (VersionExistencias > 0)
    );
END;
GO

/*
    Los indices se verifican fuera de CREATE TABLE para que una ejecucion parcial
    pueda recuperarse sin borrar tablas ni datos.
*/
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'Sales.Orders') AND name = N'IX_Orders_CustomerDate')
    CREATE INDEX IX_Orders_CustomerDate ON Sales.Orders(CustomerID, OrderDate);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'Purchasing.PurchaseOrders') AND name = N'IX_PurchaseOrders_SupplierDate')
    CREATE INDEX IX_PurchaseOrders_SupplierDate ON Purchasing.PurchaseOrders(SupplierID, OrderDate);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'Sales.Invoices') AND name = N'IX_Invoices_CustomerDate')
    CREATE INDEX IX_Invoices_CustomerDate ON Sales.Invoices(CustomerID, InvoiceDate);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'Sales.Invoices') AND name = N'IX_Invoices_BillToCustomer')
    CREATE INDEX IX_Invoices_BillToCustomer ON Sales.Invoices(BillToCustomerID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'Sales.Invoices') AND name = N'IX_Invoices_OrderID')
    CREATE INDEX IX_Invoices_OrderID ON Sales.Invoices(OrderID) WHERE OrderID IS NOT NULL;

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'Sales.InvoiceLines') AND name = N'IX_InvoiceLines_InvoiceID')
    CREATE INDEX IX_InvoiceLines_InvoiceID ON Sales.InvoiceLines(InvoiceID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'Sales.InvoiceLines') AND name = N'IX_InvoiceLines_StockItemID')
    CREATE INDEX IX_InvoiceLines_StockItemID ON Sales.InvoiceLines(StockItemID);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'Sales.CustomerTransactions') AND name = N'IX_CustomerTransactions_CustomerDate')
    CREATE INDEX IX_CustomerTransactions_CustomerDate ON Sales.CustomerTransactions(CustomerID, TransactionDate);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'Sales.CustomerTransactions') AND name = N'IX_CustomerTransactions_InvoiceID')
    CREATE INDEX IX_CustomerTransactions_InvoiceID ON Sales.CustomerTransactions(InvoiceID) WHERE InvoiceID IS NOT NULL;

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'Purchasing.PurchaseOrderLines') AND name = N'IX_PurchaseOrderLines_OrderID')
    CREATE INDEX IX_PurchaseOrderLines_OrderID ON Purchasing.PurchaseOrderLines(PurchaseOrderID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'Purchasing.PurchaseOrderLines') AND name = N'IX_PurchaseOrderLines_StockItemID')
    CREATE INDEX IX_PurchaseOrderLines_StockItemID ON Purchasing.PurchaseOrderLines(StockItemID);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'Purchasing.SupplierTransactions') AND name = N'IX_SupplierTransactions_SupplierDate')
    CREATE INDEX IX_SupplierTransactions_SupplierDate ON Purchasing.SupplierTransactions(SupplierID, TransactionDate);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'Purchasing.SupplierTransactions') AND name = N'IX_SupplierTransactions_PurchaseOrderID')
    CREATE INDEX IX_SupplierTransactions_PurchaseOrderID ON Purchasing.SupplierTransactions(PurchaseOrderID) WHERE PurchaseOrderID IS NOT NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Orders_Customer')
    ALTER TABLE Sales.Orders WITH CHECK ADD CONSTRAINT FK_Orders_Customer
        FOREIGN KEY (CustomerID) REFERENCES Sales.Customers(CustomerID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Orders_LastEditedBy')
    ALTER TABLE Sales.Orders WITH CHECK ADD CONSTRAINT FK_Orders_LastEditedBy
        FOREIGN KEY (LastEditedBy) REFERENCES Application.People(PersonID);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_PurchaseOrders_Supplier')
    ALTER TABLE Purchasing.PurchaseOrders WITH CHECK ADD CONSTRAINT FK_PurchaseOrders_Supplier
        FOREIGN KEY (SupplierID) REFERENCES Purchasing.Suppliers(SupplierID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_PurchaseOrders_DeliveryMethod')
    ALTER TABLE Purchasing.PurchaseOrders WITH CHECK ADD CONSTRAINT FK_PurchaseOrders_DeliveryMethod
        FOREIGN KEY (DeliveryMethodID) REFERENCES Application.DeliveryMethods(DeliveryMethodID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_PurchaseOrders_Contact')
    ALTER TABLE Purchasing.PurchaseOrders WITH CHECK ADD CONSTRAINT FK_PurchaseOrders_Contact
        FOREIGN KEY (ContactPersonID) REFERENCES Application.People(PersonID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_PurchaseOrders_LastEditedBy')
    ALTER TABLE Purchasing.PurchaseOrders WITH CHECK ADD CONSTRAINT FK_PurchaseOrders_LastEditedBy
        FOREIGN KEY (LastEditedBy) REFERENCES Application.People(PersonID);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Invoices_Customer')
    ALTER TABLE Sales.Invoices WITH CHECK ADD CONSTRAINT FK_Invoices_Customer
        FOREIGN KEY (CustomerID) REFERENCES Sales.Customers(CustomerID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Invoices_BillToCustomer')
    ALTER TABLE Sales.Invoices WITH CHECK ADD CONSTRAINT FK_Invoices_BillToCustomer
        FOREIGN KEY (BillToCustomerID) REFERENCES Sales.Customers(CustomerID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Invoices_Order')
    ALTER TABLE Sales.Invoices WITH CHECK ADD CONSTRAINT FK_Invoices_Order
        FOREIGN KEY (OrderID) REFERENCES Sales.Orders(OrderID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Invoices_DeliveryMethod')
    ALTER TABLE Sales.Invoices WITH CHECK ADD CONSTRAINT FK_Invoices_DeliveryMethod
        FOREIGN KEY (DeliveryMethodID) REFERENCES Application.DeliveryMethods(DeliveryMethodID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Invoices_Contact')
    ALTER TABLE Sales.Invoices WITH CHECK ADD CONSTRAINT FK_Invoices_Contact
        FOREIGN KEY (ContactPersonID) REFERENCES Application.People(PersonID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Invoices_AccountsPerson')
    ALTER TABLE Sales.Invoices WITH CHECK ADD CONSTRAINT FK_Invoices_AccountsPerson
        FOREIGN KEY (AccountsPersonID) REFERENCES Application.People(PersonID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Invoices_Salesperson')
    ALTER TABLE Sales.Invoices WITH CHECK ADD CONSTRAINT FK_Invoices_Salesperson
        FOREIGN KEY (SalespersonPersonID) REFERENCES Application.People(PersonID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Invoices_PackedBy')
    ALTER TABLE Sales.Invoices WITH CHECK ADD CONSTRAINT FK_Invoices_PackedBy
        FOREIGN KEY (PackedByPersonID) REFERENCES Application.People(PersonID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Invoices_LastEditedBy')
    ALTER TABLE Sales.Invoices WITH CHECK ADD CONSTRAINT FK_Invoices_LastEditedBy
        FOREIGN KEY (LastEditedBy) REFERENCES Application.People(PersonID);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_InvoiceLines_Invoice')
    ALTER TABLE Sales.InvoiceLines WITH CHECK ADD CONSTRAINT FK_InvoiceLines_Invoice
        FOREIGN KEY (InvoiceID) REFERENCES Sales.Invoices(InvoiceID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_InvoiceLines_StockItem')
    ALTER TABLE Sales.InvoiceLines WITH CHECK ADD CONSTRAINT FK_InvoiceLines_StockItem
        FOREIGN KEY (StockItemID) REFERENCES Warehouse.StockItems(StockItemID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_InvoiceLines_PackageType')
    ALTER TABLE Sales.InvoiceLines WITH CHECK ADD CONSTRAINT FK_InvoiceLines_PackageType
        FOREIGN KEY (PackageTypeID) REFERENCES Warehouse.PackageTypes(PackageTypeID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_InvoiceLines_LastEditedBy')
    ALTER TABLE Sales.InvoiceLines WITH CHECK ADD CONSTRAINT FK_InvoiceLines_LastEditedBy
        FOREIGN KEY (LastEditedBy) REFERENCES Application.People(PersonID);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CustomerTransactions_Customer')
    ALTER TABLE Sales.CustomerTransactions WITH CHECK ADD CONSTRAINT FK_CustomerTransactions_Customer
        FOREIGN KEY (CustomerID) REFERENCES Sales.Customers(CustomerID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CustomerTransactions_Type')
    ALTER TABLE Sales.CustomerTransactions WITH CHECK ADD CONSTRAINT FK_CustomerTransactions_Type
        FOREIGN KEY (TransactionTypeID) REFERENCES Application.TransactionTypes(TransactionTypeID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CustomerTransactions_Invoice')
    ALTER TABLE Sales.CustomerTransactions WITH CHECK ADD CONSTRAINT FK_CustomerTransactions_Invoice
        FOREIGN KEY (InvoiceID) REFERENCES Sales.Invoices(InvoiceID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CustomerTransactions_Payment')
    ALTER TABLE Sales.CustomerTransactions WITH CHECK ADD CONSTRAINT FK_CustomerTransactions_Payment
        FOREIGN KEY (PaymentMethodID) REFERENCES Application.PaymentMethods(PaymentMethodID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CustomerTransactions_LastEditedBy')
    ALTER TABLE Sales.CustomerTransactions WITH CHECK ADD CONSTRAINT FK_CustomerTransactions_LastEditedBy
        FOREIGN KEY (LastEditedBy) REFERENCES Application.People(PersonID);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_PurchaseOrderLines_Order')
    ALTER TABLE Purchasing.PurchaseOrderLines WITH CHECK ADD CONSTRAINT FK_PurchaseOrderLines_Order
        FOREIGN KEY (PurchaseOrderID) REFERENCES Purchasing.PurchaseOrders(PurchaseOrderID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_PurchaseOrderLines_StockItem')
    ALTER TABLE Purchasing.PurchaseOrderLines WITH CHECK ADD CONSTRAINT FK_PurchaseOrderLines_StockItem
        FOREIGN KEY (StockItemID) REFERENCES Warehouse.StockItems(StockItemID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_PurchaseOrderLines_PackageType')
    ALTER TABLE Purchasing.PurchaseOrderLines WITH CHECK ADD CONSTRAINT FK_PurchaseOrderLines_PackageType
        FOREIGN KEY (PackageTypeID) REFERENCES Warehouse.PackageTypes(PackageTypeID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_PurchaseOrderLines_LastEditedBy')
    ALTER TABLE Purchasing.PurchaseOrderLines WITH CHECK ADD CONSTRAINT FK_PurchaseOrderLines_LastEditedBy
        FOREIGN KEY (LastEditedBy) REFERENCES Application.People(PersonID);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SupplierTransactions_Supplier')
    ALTER TABLE Purchasing.SupplierTransactions WITH CHECK ADD CONSTRAINT FK_SupplierTransactions_Supplier
        FOREIGN KEY (SupplierID) REFERENCES Purchasing.Suppliers(SupplierID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SupplierTransactions_Type')
    ALTER TABLE Purchasing.SupplierTransactions WITH CHECK ADD CONSTRAINT FK_SupplierTransactions_Type
        FOREIGN KEY (TransactionTypeID) REFERENCES Application.TransactionTypes(TransactionTypeID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SupplierTransactions_Order')
    ALTER TABLE Purchasing.SupplierTransactions WITH CHECK ADD CONSTRAINT FK_SupplierTransactions_Order
        FOREIGN KEY (PurchaseOrderID) REFERENCES Purchasing.PurchaseOrders(PurchaseOrderID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SupplierTransactions_Payment')
    ALTER TABLE Purchasing.SupplierTransactions WITH CHECK ADD CONSTRAINT FK_SupplierTransactions_Payment
        FOREIGN KEY (PaymentMethodID) REFERENCES Application.PaymentMethods(PaymentMethodID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SupplierTransactions_LastEditedBy')
    ALTER TABLE Purchasing.SupplierTransactions WITH CHECK ADD CONSTRAINT FK_SupplierTransactions_LastEditedBy
        FOREIGN KEY (LastEditedBy) REFERENCES Application.People(PersonID);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_StockItemHoldings_StockItem')
    ALTER TABLE Warehouse.StockItemHoldings WITH CHECK ADD CONSTRAINT FK_StockItemHoldings_StockItem
        FOREIGN KEY (StockItemID) REFERENCES Warehouse.StockItems(StockItemID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_StockItemHoldings_LastEditedBy')
    ALTER TABLE Warehouse.StockItemHoldings WITH CHECK ADD CONSTRAINT FK_StockItemHoldings_LastEditedBy
        FOREIGN KEY (LastEditedBy) REFERENCES Application.People(PersonID);
GO

SELECT @@SERVERNAME AS ServerName, N'OPERATION_SCHEMA_READY' AS Result;

