:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;

USE [master];
GO

IF DB_ID(N'WideWorldImporters') IS NULL
BEGIN
    CREATE DATABASE [WideWorldImporters];
END;
GO

ALTER DATABASE [WideWorldImporters] SET ALLOW_SNAPSHOT_ISOLATION ON;
GO

USE [WideWorldImporters];
GO

IF SCHEMA_ID(N'Application') IS NULL EXEC(N'CREATE SCHEMA [Application] AUTHORIZATION [dbo];');
IF SCHEMA_ID(N'Sales') IS NULL EXEC(N'CREATE SCHEMA [Sales] AUTHORIZATION [dbo];');
IF SCHEMA_ID(N'Purchasing') IS NULL EXEC(N'CREATE SCHEMA [Purchasing] AUTHORIZATION [dbo];');
IF SCHEMA_ID(N'Warehouse') IS NULL EXEC(N'CREATE SCHEMA [Warehouse] AUTHORIZATION [dbo];');
IF SCHEMA_ID(N'Sequences') IS NULL EXEC(N'CREATE SCHEMA [Sequences] AUTHORIZATION [dbo];');
GO

IF OBJECT_ID(N'Application.People', N'U') IS NULL
BEGIN
    CREATE TABLE Application.People
    (
        PersonID int NOT NULL,
        FullName nvarchar(50) NOT NULL,
        IsEmployee bit NOT NULL,
        IsSalesperson bit NOT NULL,
        LastEditedBy int NOT NULL,
        LastEditedWhen datetime2(7) NOT NULL
            CONSTRAINT DF_People_LastEditedWhen DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_People PRIMARY KEY (PersonID)
    );
END;

IF OBJECT_ID(N'Application.DeliveryMethods', N'U') IS NULL
BEGIN
    CREATE TABLE Application.DeliveryMethods
    (
        DeliveryMethodID int NOT NULL,
        DeliveryMethodName nvarchar(50) NOT NULL,
        LastEditedBy int NOT NULL,
        LastEditedWhen datetime2(7) NOT NULL
            CONSTRAINT DF_DeliveryMethods_LastEditedWhen DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_DeliveryMethods PRIMARY KEY (DeliveryMethodID),
        CONSTRAINT UQ_DeliveryMethods_Name UNIQUE (DeliveryMethodName)
    );
END;

IF OBJECT_ID(N'Application.PaymentMethods', N'U') IS NULL
BEGIN
    CREATE TABLE Application.PaymentMethods
    (
        PaymentMethodID int NOT NULL,
        PaymentMethodName nvarchar(50) NOT NULL,
        LastEditedBy int NOT NULL,
        LastEditedWhen datetime2(7) NOT NULL
            CONSTRAINT DF_PaymentMethods_LastEditedWhen DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_PaymentMethods PRIMARY KEY (PaymentMethodID),
        CONSTRAINT UQ_PaymentMethods_Name UNIQUE (PaymentMethodName)
    );
END;

IF OBJECT_ID(N'Application.TransactionTypes', N'U') IS NULL
BEGIN
    CREATE TABLE Application.TransactionTypes
    (
        TransactionTypeID int NOT NULL,
        TransactionTypeName nvarchar(50) NOT NULL,
        LastEditedBy int NOT NULL,
        LastEditedWhen datetime2(7) NOT NULL
            CONSTRAINT DF_TransactionTypes_LastEditedWhen DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_TransactionTypes PRIMARY KEY (TransactionTypeID),
        CONSTRAINT UQ_TransactionTypes_Name UNIQUE (TransactionTypeName)
    );
END;

IF OBJECT_ID(N'Sales.CustomerCategories', N'U') IS NULL
BEGIN
    CREATE TABLE Sales.CustomerCategories
    (
        CustomerCategoryID int NOT NULL,
        CustomerCategoryName nvarchar(50) NOT NULL,
        LastEditedBy int NOT NULL,
        LastEditedWhen datetime2(7) NOT NULL
            CONSTRAINT DF_CustomerCategories_LastEditedWhen DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_CustomerCategories PRIMARY KEY (CustomerCategoryID),
        CONSTRAINT UQ_CustomerCategories_Name UNIQUE (CustomerCategoryName)
    );
END;

IF OBJECT_ID(N'Sales.BuyingGroups', N'U') IS NULL
BEGIN
    CREATE TABLE Sales.BuyingGroups
    (
        BuyingGroupID int NOT NULL,
        BuyingGroupName nvarchar(50) NOT NULL,
        LastEditedBy int NOT NULL,
        LastEditedWhen datetime2(7) NOT NULL
            CONSTRAINT DF_BuyingGroups_LastEditedWhen DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_BuyingGroups PRIMARY KEY (BuyingGroupID),
        CONSTRAINT UQ_BuyingGroups_Name UNIQUE (BuyingGroupName)
    );
END;

IF OBJECT_ID(N'Purchasing.SupplierCategories', N'U') IS NULL
BEGIN
    CREATE TABLE Purchasing.SupplierCategories
    (
        SupplierCategoryID int NOT NULL,
        SupplierCategoryName nvarchar(50) NOT NULL,
        LastEditedBy int NOT NULL,
        LastEditedWhen datetime2(7) NOT NULL
            CONSTRAINT DF_SupplierCategories_LastEditedWhen DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_SupplierCategories PRIMARY KEY (SupplierCategoryID),
        CONSTRAINT UQ_SupplierCategories_Name UNIQUE (SupplierCategoryName)
    );
END;

IF OBJECT_ID(N'Warehouse.StockGroups', N'U') IS NULL
BEGIN
    CREATE TABLE Warehouse.StockGroups
    (
        StockGroupID int NOT NULL,
        StockGroupName nvarchar(50) NOT NULL,
        LastEditedBy int NOT NULL,
        LastEditedWhen datetime2(7) NOT NULL
            CONSTRAINT DF_StockGroups_LastEditedWhen DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_StockGroups PRIMARY KEY (StockGroupID),
        CONSTRAINT UQ_StockGroups_Name UNIQUE (StockGroupName)
    );
END;

IF OBJECT_ID(N'Warehouse.Colors', N'U') IS NULL
BEGIN
    CREATE TABLE Warehouse.Colors
    (
        ColorID int NOT NULL,
        ColorName nvarchar(20) NOT NULL,
        LastEditedBy int NOT NULL,
        LastEditedWhen datetime2(7) NOT NULL
            CONSTRAINT DF_Colors_LastEditedWhen DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_Colors PRIMARY KEY (ColorID),
        CONSTRAINT UQ_Colors_Name UNIQUE (ColorName)
    );
END;

IF OBJECT_ID(N'Warehouse.PackageTypes', N'U') IS NULL
BEGIN
    CREATE TABLE Warehouse.PackageTypes
    (
        PackageTypeID int NOT NULL,
        PackageTypeName nvarchar(50) NOT NULL,
        LastEditedBy int NOT NULL,
        LastEditedWhen datetime2(7) NOT NULL
            CONSTRAINT DF_PackageTypes_LastEditedWhen DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_PackageTypes PRIMARY KEY (PackageTypeID),
        CONSTRAINT UQ_PackageTypes_Name UNIQUE (PackageTypeName)
    );
END;
GO

IF OBJECT_ID(N'Sales.Customers', N'U') IS NULL
BEGIN
    CREATE TABLE Sales.Customers
    (
        CustomerID int NOT NULL,
        CustomerName nvarchar(100) NOT NULL,
        BillToCustomerID int NOT NULL,
        CustomerCategoryID int NOT NULL,
        BuyingGroupID int NULL,
        DeliveryMethodID int NOT NULL,
        AccountOpenedDate date NOT NULL,
        IsStatementSent bit NOT NULL,
        IsOnCreditHold bit NOT NULL,
        PaymentDays int NOT NULL,
        LastEditedBy int NOT NULL,
        LastEditedWhen datetime2(7) NOT NULL
            CONSTRAINT DF_Customers_LastEditedWhen DEFAULT (SYSUTCDATETIME()),
        Activo bit NOT NULL CONSTRAINT DF_Customers_Activo DEFAULT (1),
        VersionCatalogo int NOT NULL CONSTRAINT DF_Customers_Version DEFAULT (1),
        CONSTRAINT PK_Customers PRIMARY KEY (CustomerID),
        CONSTRAINT UQ_Customers_Name UNIQUE (CustomerName),
        CONSTRAINT CK_Customers_PaymentDays CHECK (PaymentDays >= 0),
        CONSTRAINT CK_Customers_Version CHECK (VersionCatalogo > 0)
    );
END;

IF OBJECT_ID(N'Purchasing.Suppliers', N'U') IS NULL
BEGIN
    CREATE TABLE Purchasing.Suppliers
    (
        SupplierID int NOT NULL,
        SupplierName nvarchar(100) NOT NULL,
        SupplierCategoryID int NOT NULL,
        DeliveryMethodID int NULL,
        PaymentDays int NOT NULL,
        LastEditedBy int NOT NULL,
        LastEditedWhen datetime2(7) NOT NULL
            CONSTRAINT DF_Suppliers_LastEditedWhen DEFAULT (SYSUTCDATETIME()),
        Activo bit NOT NULL CONSTRAINT DF_Suppliers_Activo DEFAULT (1),
        VersionCatalogo int NOT NULL CONSTRAINT DF_Suppliers_Version DEFAULT (1),
        CONSTRAINT PK_Suppliers PRIMARY KEY (SupplierID),
        CONSTRAINT UQ_Suppliers_Name UNIQUE (SupplierName),
        CONSTRAINT CK_Suppliers_PaymentDays CHECK (PaymentDays >= 0),
        CONSTRAINT CK_Suppliers_Version CHECK (VersionCatalogo > 0)
    );
END;
GO

IF OBJECT_ID(N'Warehouse.StockItems', N'U') IS NULL
BEGIN
    CREATE TABLE Warehouse.StockItems
    (
        StockItemID int NOT NULL,
        StockItemName nvarchar(100) NOT NULL,
        SupplierID int NOT NULL,
        ColorID int NULL,
        UnitPackageID int NOT NULL,
        OuterPackageID int NOT NULL,
        Brand nvarchar(50) NULL,
        Size nvarchar(20) NULL,
        LeadTimeDays int NOT NULL,
        QuantityPerOuter int NOT NULL,
        IsChillerStock bit NOT NULL,
        Barcode nvarchar(50) NULL,
        TaxRate decimal(18,3) NOT NULL,
        UnitPrice decimal(18,2) NOT NULL,
        RecommendedRetailPrice decimal(18,2) NULL,
        TypicalWeightPerUnit decimal(18,3) NOT NULL,
        MarketingComments nvarchar(max) NULL,
        InternalComments nvarchar(max) NULL,
        Photo varbinary(max) NULL,
        CustomFields nvarchar(max) NULL,
        LastEditedBy int NOT NULL,
        LastEditedWhen datetime2(7) NOT NULL
            CONSTRAINT DF_StockItems_LastEditedWhen DEFAULT (SYSUTCDATETIME()),
        Activo bit NOT NULL CONSTRAINT DF_StockItems_Activo DEFAULT (1),
        VersionCatalogo int NOT NULL CONSTRAINT DF_StockItems_Version DEFAULT (1),
        CONSTRAINT PK_StockItems PRIMARY KEY (StockItemID),
        CONSTRAINT UQ_StockItems_Name UNIQUE (StockItemName),
        CONSTRAINT CK_StockItems_LeadTime CHECK (LeadTimeDays >= 0),
        CONSTRAINT CK_StockItems_QuantityPerOuter CHECK (QuantityPerOuter > 0),
        CONSTRAINT CK_StockItems_TaxRate CHECK (TaxRate >= 0),
        CONSTRAINT CK_StockItems_UnitPrice CHECK (UnitPrice >= 0),
        CONSTRAINT CK_StockItems_Weight CHECK (TypicalWeightPerUnit >= 0),
        CONSTRAINT CK_StockItems_Version CHECK (VersionCatalogo > 0)
    );
END;

IF OBJECT_ID(N'Warehouse.StockItemStockGroups', N'U') IS NULL
BEGIN
    CREATE TABLE Warehouse.StockItemStockGroups
    (
        StockItemStockGroupID int NOT NULL,
        StockItemID int NOT NULL,
        StockGroupID int NOT NULL,
        LastEditedBy int NOT NULL,
        LastEditedWhen datetime2(7) NOT NULL
            CONSTRAINT DF_StockItemStockGroups_LastEditedWhen DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_StockItemStockGroups PRIMARY KEY (StockItemStockGroupID),
        CONSTRAINT UQ_StockItemStockGroups_ItemGroup UNIQUE (StockItemID, StockGroupID)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_People_LastEditedBy')
    ALTER TABLE Application.People WITH CHECK ADD CONSTRAINT FK_People_LastEditedBy
        FOREIGN KEY (LastEditedBy) REFERENCES Application.People(PersonID) NOT FOR REPLICATION;

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_DeliveryMethods_LastEditedBy')
    ALTER TABLE Application.DeliveryMethods WITH CHECK ADD CONSTRAINT FK_DeliveryMethods_LastEditedBy
        FOREIGN KEY (LastEditedBy) REFERENCES Application.People(PersonID) NOT FOR REPLICATION;

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_PaymentMethods_LastEditedBy')
    ALTER TABLE Application.PaymentMethods WITH CHECK ADD CONSTRAINT FK_PaymentMethods_LastEditedBy
        FOREIGN KEY (LastEditedBy) REFERENCES Application.People(PersonID) NOT FOR REPLICATION;

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_TransactionTypes_LastEditedBy')
    ALTER TABLE Application.TransactionTypes WITH CHECK ADD CONSTRAINT FK_TransactionTypes_LastEditedBy
        FOREIGN KEY (LastEditedBy) REFERENCES Application.People(PersonID) NOT FOR REPLICATION;

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CustomerCategories_LastEditedBy')
    ALTER TABLE Sales.CustomerCategories WITH CHECK ADD CONSTRAINT FK_CustomerCategories_LastEditedBy
        FOREIGN KEY (LastEditedBy) REFERENCES Application.People(PersonID) NOT FOR REPLICATION;

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_BuyingGroups_LastEditedBy')
    ALTER TABLE Sales.BuyingGroups WITH CHECK ADD CONSTRAINT FK_BuyingGroups_LastEditedBy
        FOREIGN KEY (LastEditedBy) REFERENCES Application.People(PersonID) NOT FOR REPLICATION;

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_SupplierCategories_LastEditedBy')
    ALTER TABLE Purchasing.SupplierCategories WITH CHECK ADD CONSTRAINT FK_SupplierCategories_LastEditedBy
        FOREIGN KEY (LastEditedBy) REFERENCES Application.People(PersonID) NOT FOR REPLICATION;

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_StockGroups_LastEditedBy')
    ALTER TABLE Warehouse.StockGroups WITH CHECK ADD CONSTRAINT FK_StockGroups_LastEditedBy
        FOREIGN KEY (LastEditedBy) REFERENCES Application.People(PersonID) NOT FOR REPLICATION;

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Colors_LastEditedBy')
    ALTER TABLE Warehouse.Colors WITH CHECK ADD CONSTRAINT FK_Colors_LastEditedBy
        FOREIGN KEY (LastEditedBy) REFERENCES Application.People(PersonID) NOT FOR REPLICATION;

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_PackageTypes_LastEditedBy')
    ALTER TABLE Warehouse.PackageTypes WITH CHECK ADD CONSTRAINT FK_PackageTypes_LastEditedBy
        FOREIGN KEY (LastEditedBy) REFERENCES Application.People(PersonID) NOT FOR REPLICATION;

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Customers_BillToCustomer')
    ALTER TABLE Sales.Customers WITH CHECK ADD CONSTRAINT FK_Customers_BillToCustomer
        FOREIGN KEY (BillToCustomerID) REFERENCES Sales.Customers(CustomerID) NOT FOR REPLICATION;

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Customers_Category')
    ALTER TABLE Sales.Customers WITH CHECK ADD CONSTRAINT FK_Customers_Category
        FOREIGN KEY (CustomerCategoryID) REFERENCES Sales.CustomerCategories(CustomerCategoryID) NOT FOR REPLICATION;

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Customers_BuyingGroup')
    ALTER TABLE Sales.Customers WITH CHECK ADD CONSTRAINT FK_Customers_BuyingGroup
        FOREIGN KEY (BuyingGroupID) REFERENCES Sales.BuyingGroups(BuyingGroupID) NOT FOR REPLICATION;

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Customers_DeliveryMethod')
    ALTER TABLE Sales.Customers WITH CHECK ADD CONSTRAINT FK_Customers_DeliveryMethod
        FOREIGN KEY (DeliveryMethodID) REFERENCES Application.DeliveryMethods(DeliveryMethodID) NOT FOR REPLICATION;

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Customers_LastEditedBy')
    ALTER TABLE Sales.Customers WITH CHECK ADD CONSTRAINT FK_Customers_LastEditedBy
        FOREIGN KEY (LastEditedBy) REFERENCES Application.People(PersonID) NOT FOR REPLICATION;

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Suppliers_Category')
    ALTER TABLE Purchasing.Suppliers WITH CHECK ADD CONSTRAINT FK_Suppliers_Category
        FOREIGN KEY (SupplierCategoryID) REFERENCES Purchasing.SupplierCategories(SupplierCategoryID) NOT FOR REPLICATION;

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Suppliers_DeliveryMethod')
    ALTER TABLE Purchasing.Suppliers WITH CHECK ADD CONSTRAINT FK_Suppliers_DeliveryMethod
        FOREIGN KEY (DeliveryMethodID) REFERENCES Application.DeliveryMethods(DeliveryMethodID) NOT FOR REPLICATION;

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Suppliers_LastEditedBy')
    ALTER TABLE Purchasing.Suppliers WITH CHECK ADD CONSTRAINT FK_Suppliers_LastEditedBy
        FOREIGN KEY (LastEditedBy) REFERENCES Application.People(PersonID) NOT FOR REPLICATION;

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_StockItems_Supplier')
    ALTER TABLE Warehouse.StockItems WITH CHECK ADD CONSTRAINT FK_StockItems_Supplier
        FOREIGN KEY (SupplierID) REFERENCES Purchasing.Suppliers(SupplierID) NOT FOR REPLICATION;

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_StockItems_Color')
    ALTER TABLE Warehouse.StockItems WITH CHECK ADD CONSTRAINT FK_StockItems_Color
        FOREIGN KEY (ColorID) REFERENCES Warehouse.Colors(ColorID) NOT FOR REPLICATION;

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_StockItems_UnitPackage')
    ALTER TABLE Warehouse.StockItems WITH CHECK ADD CONSTRAINT FK_StockItems_UnitPackage
        FOREIGN KEY (UnitPackageID) REFERENCES Warehouse.PackageTypes(PackageTypeID) NOT FOR REPLICATION;

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_StockItems_OuterPackage')
    ALTER TABLE Warehouse.StockItems WITH CHECK ADD CONSTRAINT FK_StockItems_OuterPackage
        FOREIGN KEY (OuterPackageID) REFERENCES Warehouse.PackageTypes(PackageTypeID) NOT FOR REPLICATION;

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_StockItems_LastEditedBy')
    ALTER TABLE Warehouse.StockItems WITH CHECK ADD CONSTRAINT FK_StockItems_LastEditedBy
        FOREIGN KEY (LastEditedBy) REFERENCES Application.People(PersonID) NOT FOR REPLICATION;

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_StockItemStockGroups_Item')
    ALTER TABLE Warehouse.StockItemStockGroups WITH CHECK ADD CONSTRAINT FK_StockItemStockGroups_Item
        FOREIGN KEY (StockItemID) REFERENCES Warehouse.StockItems(StockItemID) NOT FOR REPLICATION;

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_StockItemStockGroups_Group')
    ALTER TABLE Warehouse.StockItemStockGroups WITH CHECK ADD CONSTRAINT FK_StockItemStockGroups_Group
        FOREIGN KEY (StockGroupID) REFERENCES Warehouse.StockGroups(StockGroupID) NOT FOR REPLICATION;

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_StockItemStockGroups_LastEditedBy')
    ALTER TABLE Warehouse.StockItemStockGroups WITH CHECK ADD CONSTRAINT FK_StockItemStockGroups_LastEditedBy
        FOREIGN KEY (LastEditedBy) REFERENCES Application.People(PersonID) NOT FOR REPLICATION;
GO

SELECT @@SERVERNAME AS ServerName, DB_NAME() AS DatabaseName, N'CATALOG_SCHEMA_READY' AS Result;

