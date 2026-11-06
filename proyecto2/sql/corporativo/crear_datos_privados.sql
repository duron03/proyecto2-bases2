:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;

USE [WideWorldImporters];
GO

IF SCHEMA_ID(N'Privado') IS NULL EXEC(N'CREATE SCHEMA [Privado] AUTHORIZATION [dbo];');
IF SCHEMA_ID(N'Preparacion') IS NULL EXEC(N'CREATE SCHEMA [Preparacion] AUTHORIZATION [dbo];');
IF SCHEMA_ID(N'Corporativo') IS NULL EXEC(N'CREATE SCHEMA [Corporativo] AUTHORIZATION [dbo];');
GO

IF OBJECT_ID(N'Privado.Personas', N'U') IS NULL
BEGIN
    CREATE TABLE Privado.Personas
    (
        PersonID int NOT NULL,
        FullName nvarchar(50) NOT NULL,
        PhoneNumber nvarchar(20) NULL,
        FaxNumber nvarchar(20) NULL,
        EmailAddress nvarchar(256) NULL,
        CONSTRAINT PK_Privado_Personas PRIMARY KEY (PersonID)
    );
END;

IF OBJECT_ID(N'Application.Countries', N'U') IS NULL
BEGIN
    CREATE TABLE Application.Countries
    (
        CountryID int NOT NULL,
        CountryName nvarchar(60) NOT NULL,
        FormalName nvarchar(60) NOT NULL,
        IsoAlpha3Code nvarchar(3) NULL,
        IsoNumericCode int NULL,
        CountryType nvarchar(20) NULL,
        LatestRecordedPopulation bigint NULL,
        Continent nvarchar(30) NOT NULL,
        Region nvarchar(30) NOT NULL,
        Subregion nvarchar(30) NOT NULL,
        Border geography NULL,
        LastEditedBy int NOT NULL,
        LastEditedWhen datetime2(7) NOT NULL,
        CONSTRAINT PK_Countries PRIMARY KEY (CountryID),
        CONSTRAINT UQ_Countries_Name UNIQUE (CountryName)
    );
END;

IF OBJECT_ID(N'Application.StateProvinces', N'U') IS NULL
BEGIN
    CREATE TABLE Application.StateProvinces
    (
        StateProvinceID int NOT NULL,
        StateProvinceCode nvarchar(5) NOT NULL,
        StateProvinceName nvarchar(50) NOT NULL,
        CountryID int NOT NULL,
        SalesTerritory nvarchar(50) NOT NULL,
        Border geography NULL,
        LatestRecordedPopulation bigint NULL,
        LastEditedBy int NOT NULL,
        LastEditedWhen datetime2(7) NOT NULL,
        CONSTRAINT PK_StateProvinces PRIMARY KEY (StateProvinceID),
        CONSTRAINT UQ_StateProvinces_Name UNIQUE (StateProvinceName)
    );
END;

IF OBJECT_ID(N'Application.Cities', N'U') IS NULL
BEGIN
    CREATE TABLE Application.Cities
    (
        CityID int NOT NULL,
        CityName nvarchar(50) NOT NULL,
        StateProvinceID int NOT NULL,
        Location geography NULL,
        LatestRecordedPopulation bigint NULL,
        LastEditedBy int NOT NULL,
        LastEditedWhen datetime2(7) NOT NULL,
        CONSTRAINT PK_Cities PRIMARY KEY (CityID)
    );

    CREATE INDEX IX_Cities_CityName ON Application.Cities(CityName);
END;
GO

IF OBJECT_ID(N'Privado.Clientes', N'U') IS NULL
BEGIN
    CREATE TABLE Privado.Clientes
    (
        CustomerID int NOT NULL,
        PrimaryContactPersonID int NOT NULL,
        AlternateContactPersonID int NULL,
        DeliveryCityID int NOT NULL,
        PostalCityID int NOT NULL,
        CreditLimit decimal(18,2) NULL,
        StandardDiscountPercentage decimal(18,3) NOT NULL,
        PhoneNumber nvarchar(20) NOT NULL,
        FaxNumber nvarchar(20) NOT NULL,
        DeliveryRun nvarchar(5) NULL,
        RunPosition nvarchar(5) NULL,
        WebsiteURL nvarchar(256) NOT NULL,
        DeliveryAddressLine1 nvarchar(60) NOT NULL,
        DeliveryAddressLine2 nvarchar(60) NULL,
        DeliveryPostalCode nvarchar(10) NOT NULL,
        DeliveryLocation geography NULL,
        PostalAddressLine1 nvarchar(60) NOT NULL,
        PostalAddressLine2 nvarchar(60) NULL,
        PostalPostalCode nvarchar(10) NOT NULL,
        CONSTRAINT PK_Privado_Clientes PRIMARY KEY (CustomerID),
        CONSTRAINT CK_Privado_Clientes_Credit CHECK (CreditLimit IS NULL OR CreditLimit >= 0),
        CONSTRAINT CK_Privado_Clientes_Discount CHECK (StandardDiscountPercentage >= 0)
    );
END;

IF OBJECT_ID(N'Privado.Proveedores', N'U') IS NULL
BEGIN
    CREATE TABLE Privado.Proveedores
    (
        SupplierID int NOT NULL,
        PrimaryContactPersonID int NOT NULL,
        AlternateContactPersonID int NOT NULL,
        DeliveryCityID int NOT NULL,
        PostalCityID int NOT NULL,
        SupplierReference nvarchar(20) NULL,
        BankAccountName nvarchar(50) NULL,
        BankAccountBranch nvarchar(50) NULL,
        BankAccountCode nvarchar(20) NULL,
        BankAccountNumber nvarchar(20) NULL,
        BankInternationalCode nvarchar(20) NULL,
        InternalComments nvarchar(max) NULL,
        PhoneNumber nvarchar(20) NOT NULL,
        FaxNumber nvarchar(20) NOT NULL,
        WebsiteURL nvarchar(256) NOT NULL,
        DeliveryAddressLine1 nvarchar(60) NOT NULL,
        DeliveryAddressLine2 nvarchar(60) NULL,
        DeliveryPostalCode nvarchar(10) NOT NULL,
        DeliveryLocation geography NULL,
        PostalAddressLine1 nvarchar(60) NOT NULL,
        PostalAddressLine2 nvarchar(60) NULL,
        PostalPostalCode nvarchar(10) NOT NULL,
        CONSTRAINT PK_Privado_Proveedores PRIMARY KEY (SupplierID)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Privado_Personas_Publicas')
    ALTER TABLE Privado.Personas WITH CHECK ADD CONSTRAINT FK_Privado_Personas_Publicas
        FOREIGN KEY (PersonID) REFERENCES Application.People(PersonID);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Countries_LastEditedBy')
    ALTER TABLE Application.Countries WITH CHECK ADD CONSTRAINT FK_Countries_LastEditedBy
        FOREIGN KEY (LastEditedBy) REFERENCES Application.People(PersonID);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_StateProvinces_Country')
    ALTER TABLE Application.StateProvinces WITH CHECK ADD CONSTRAINT FK_StateProvinces_Country
        FOREIGN KEY (CountryID) REFERENCES Application.Countries(CountryID);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_StateProvinces_LastEditedBy')
    ALTER TABLE Application.StateProvinces WITH CHECK ADD CONSTRAINT FK_StateProvinces_LastEditedBy
        FOREIGN KEY (LastEditedBy) REFERENCES Application.People(PersonID);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Cities_StateProvince')
    ALTER TABLE Application.Cities WITH CHECK ADD CONSTRAINT FK_Cities_StateProvince
        FOREIGN KEY (StateProvinceID) REFERENCES Application.StateProvinces(StateProvinceID);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Cities_LastEditedBy')
    ALTER TABLE Application.Cities WITH CHECK ADD CONSTRAINT FK_Cities_LastEditedBy
        FOREIGN KEY (LastEditedBy) REFERENCES Application.People(PersonID);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Privado_Clientes_Publicos')
    ALTER TABLE Privado.Clientes WITH CHECK ADD CONSTRAINT FK_Privado_Clientes_Publicos
        FOREIGN KEY (CustomerID) REFERENCES Sales.Customers(CustomerID);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Privado_Clientes_ContactoPrincipal')
    ALTER TABLE Privado.Clientes WITH CHECK ADD CONSTRAINT FK_Privado_Clientes_ContactoPrincipal
        FOREIGN KEY (PrimaryContactPersonID) REFERENCES Privado.Personas(PersonID);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Privado_Clientes_ContactoAlterno')
    ALTER TABLE Privado.Clientes WITH CHECK ADD CONSTRAINT FK_Privado_Clientes_ContactoAlterno
        FOREIGN KEY (AlternateContactPersonID) REFERENCES Privado.Personas(PersonID);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Privado_Clientes_CiudadEntrega')
    ALTER TABLE Privado.Clientes WITH CHECK ADD CONSTRAINT FK_Privado_Clientes_CiudadEntrega
        FOREIGN KEY (DeliveryCityID) REFERENCES Application.Cities(CityID);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Privado_Clientes_CiudadPostal')
    ALTER TABLE Privado.Clientes WITH CHECK ADD CONSTRAINT FK_Privado_Clientes_CiudadPostal
        FOREIGN KEY (PostalCityID) REFERENCES Application.Cities(CityID);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Privado_Proveedores_Publicos')
    ALTER TABLE Privado.Proveedores WITH CHECK ADD CONSTRAINT FK_Privado_Proveedores_Publicos
        FOREIGN KEY (SupplierID) REFERENCES Purchasing.Suppliers(SupplierID);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Privado_Proveedores_ContactoPrincipal')
    ALTER TABLE Privado.Proveedores WITH CHECK ADD CONSTRAINT FK_Privado_Proveedores_ContactoPrincipal
        FOREIGN KEY (PrimaryContactPersonID) REFERENCES Privado.Personas(PersonID);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Privado_Proveedores_ContactoAlterno')
    ALTER TABLE Privado.Proveedores WITH CHECK ADD CONSTRAINT FK_Privado_Proveedores_ContactoAlterno
        FOREIGN KEY (AlternateContactPersonID) REFERENCES Privado.Personas(PersonID);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Privado_Proveedores_CiudadEntrega')
    ALTER TABLE Privado.Proveedores WITH CHECK ADD CONSTRAINT FK_Privado_Proveedores_CiudadEntrega
        FOREIGN KEY (DeliveryCityID) REFERENCES Application.Cities(CityID);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Privado_Proveedores_CiudadPostal')
    ALTER TABLE Privado.Proveedores WITH CHECK ADD CONSTRAINT FK_Privado_Proveedores_CiudadPostal
        FOREIGN KEY (PostalCityID) REFERENCES Application.Cities(CityID);
GO

IF OBJECT_ID(N'Preparacion.AsignacionPedidos', N'U') IS NULL
BEGIN
    CREATE TABLE Preparacion.AsignacionPedidos
    (
        OrderID int NOT NULL,
        SucursalID int NOT NULL,
        CONSTRAINT PK_Preparacion_AsignacionPedidos PRIMARY KEY (OrderID),
        CONSTRAINT CK_Preparacion_AsignacionPedidos_Sucursal CHECK (SucursalID IN (1, 2))
    );
END;

IF OBJECT_ID(N'Preparacion.AsignacionFacturas', N'U') IS NULL
BEGIN
    CREATE TABLE Preparacion.AsignacionFacturas
    (
        InvoiceID int NOT NULL,
        SucursalID int NOT NULL,
        CONSTRAINT PK_Preparacion_AsignacionFacturas PRIMARY KEY (InvoiceID),
        CONSTRAINT CK_Preparacion_AsignacionFacturas_Sucursal CHECK (SucursalID IN (1, 2))
    );
END;

IF OBJECT_ID(N'Preparacion.AsignacionCompras', N'U') IS NULL
BEGIN
    CREATE TABLE Preparacion.AsignacionCompras
    (
        PurchaseOrderID int NOT NULL,
        SucursalID int NOT NULL,
        CONSTRAINT PK_Preparacion_AsignacionCompras PRIMARY KEY (PurchaseOrderID),
        CONSTRAINT CK_Preparacion_AsignacionCompras_Sucursal CHECK (SucursalID IN (1, 2))
    );
END;
GO

CREATE OR ALTER VIEW Privado.v_ClientesCompletos
AS
SELECT
    publicObject.CustomerID,
    publicObject.CustomerName,
    publicObject.BillToCustomerID,
    publicObject.CustomerCategoryID,
    publicObject.BuyingGroupID,
    privateObject.PrimaryContactPersonID,
    privateObject.AlternateContactPersonID,
    publicObject.DeliveryMethodID,
    privateObject.DeliveryCityID,
    privateObject.PostalCityID,
    privateObject.CreditLimit,
    publicObject.AccountOpenedDate,
    privateObject.StandardDiscountPercentage,
    publicObject.IsStatementSent,
    publicObject.IsOnCreditHold,
    publicObject.PaymentDays,
    privateObject.PhoneNumber,
    privateObject.FaxNumber,
    privateObject.DeliveryRun,
    privateObject.RunPosition,
    privateObject.WebsiteURL,
    privateObject.DeliveryAddressLine1,
    privateObject.DeliveryAddressLine2,
    privateObject.DeliveryPostalCode,
    privateObject.DeliveryLocation,
    privateObject.PostalAddressLine1,
    privateObject.PostalAddressLine2,
    privateObject.PostalPostalCode,
    publicObject.LastEditedBy,
    publicObject.LastEditedWhen,
    publicObject.Activo,
    publicObject.VersionCatalogo
FROM Sales.Customers AS publicObject
INNER JOIN Privado.Clientes AS privateObject
    ON privateObject.CustomerID = publicObject.CustomerID;
GO

CREATE OR ALTER VIEW Privado.v_ProveedoresCompletos
AS
SELECT
    publicObject.SupplierID,
    publicObject.SupplierName,
    publicObject.SupplierCategoryID,
    privateObject.PrimaryContactPersonID,
    privateObject.AlternateContactPersonID,
    publicObject.DeliveryMethodID,
    privateObject.DeliveryCityID,
    privateObject.PostalCityID,
    privateObject.SupplierReference,
    privateObject.BankAccountName,
    privateObject.BankAccountBranch,
    privateObject.BankAccountCode,
    privateObject.BankAccountNumber,
    privateObject.BankInternationalCode,
    publicObject.PaymentDays,
    privateObject.InternalComments,
    privateObject.PhoneNumber,
    privateObject.FaxNumber,
    privateObject.WebsiteURL,
    privateObject.DeliveryAddressLine1,
    privateObject.DeliveryAddressLine2,
    privateObject.DeliveryPostalCode,
    privateObject.DeliveryLocation,
    privateObject.PostalAddressLine1,
    privateObject.PostalAddressLine2,
    privateObject.PostalPostalCode,
    publicObject.LastEditedBy,
    publicObject.LastEditedWhen,
    publicObject.Activo,
    publicObject.VersionCatalogo
FROM Purchasing.Suppliers AS publicObject
INNER JOIN Privado.Proveedores AS privateObject
    ON privateObject.SupplierID = publicObject.SupplierID;
GO

SELECT N'PRIVATE_SCHEMA_READY' AS Result;

