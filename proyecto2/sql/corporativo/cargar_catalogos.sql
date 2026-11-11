:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;

USE [WideWorldImporters];
GO

IF DB_ID(N'WWI_Origen') IS NULL
    THROW 51210, N'No existe WWI_Origen en el nodo corporativo.', 1;

IF DATABASEPROPERTYEX(N'WWI_Origen', N'Updateability') <> N'READ_ONLY'
    THROW 51211, N'WWI_Origen debe permanecer en modo READ_ONLY.', 1;

IF OBJECT_ID(N'Privado.Personas', N'U') IS NULL
   OR OBJECT_ID(N'Preparacion.AsignacionPedidos', N'U') IS NULL
    THROW 51212, N'Ejecute primero crear_catalogos.sql y crear_datos_privados.sql.', 1;

/*
    Esta carga se ejecuta una sola vez. Si encuentra una fila, se detiene para no
    reemplazar cambios que ya puedan pertenecer a los usuarios.
*/
IF EXISTS (SELECT 1 FROM Application.People)
   OR EXISTS (SELECT 1 FROM Application.DeliveryMethods)
   OR EXISTS (SELECT 1 FROM Application.PaymentMethods)
   OR EXISTS (SELECT 1 FROM Application.TransactionTypes)
   OR EXISTS (SELECT 1 FROM Sales.CustomerCategories)
   OR EXISTS (SELECT 1 FROM Sales.BuyingGroups)
   OR EXISTS (SELECT 1 FROM Sales.Customers)
   OR EXISTS (SELECT 1 FROM Purchasing.SupplierCategories)
   OR EXISTS (SELECT 1 FROM Purchasing.Suppliers)
   OR EXISTS (SELECT 1 FROM Warehouse.StockGroups)
   OR EXISTS (SELECT 1 FROM Warehouse.Colors)
   OR EXISTS (SELECT 1 FROM Warehouse.PackageTypes)
   OR EXISTS (SELECT 1 FROM Warehouse.StockItems)
   OR EXISTS (SELECT 1 FROM Warehouse.StockItemStockGroups)
   OR EXISTS (SELECT 1 FROM Privado.Personas)
   OR EXISTS (SELECT 1 FROM Privado.Clientes)
   OR EXISTS (SELECT 1 FROM Privado.Proveedores)
   OR EXISTS (SELECT 1 FROM Application.Countries)
   OR EXISTS (SELECT 1 FROM Application.StateProvinces)
   OR EXISTS (SELECT 1 FROM Application.Cities)
   OR EXISTS (SELECT 1 FROM Preparacion.AsignacionPedidos)
   OR EXISTS (SELECT 1 FROM Preparacion.AsignacionFacturas)
   OR EXISTS (SELECT 1 FROM Preparacion.AsignacionCompras)
BEGIN
    THROW 51213, N'La carga inicial se rechazo porque el destino no esta vacio.', 1;
END;

DECLARE @MaxPersonID int = (SELECT MAX(PersonID) FROM WWI_Origen.Application.People);

IF @MaxPersonID <> 3261
BEGIN
    THROW 51214, N'El maximo PersonID cambio. Revise los IDs demo documentados antes de cargar.', 1;
END;

BEGIN TRANSACTION;

/* Personas publicas: las sedes reciben alias, nunca nombres ni datos de contacto. */
INSERT INTO Application.People
(
    PersonID, FullName, IsEmployee, IsSalesperson, LastEditedBy, LastEditedWhen
)
SELECT
    PersonID,
    CONVERT(nvarchar(50), CONCAT(N'Persona ', PersonID)),
    IsEmployee,
    IsSalesperson,
    LastEditedBy,
    ValidFrom
FROM WWI_Origen.Application.People;

INSERT INTO Application.People
(
    PersonID, FullName, IsEmployee, IsSalesperson, LastEditedBy, LastEditedWhen
)
VALUES
    (3262, N'Administrador San Jose', 1, 0, 1, SYSUTCDATETIME()),
    (3263, N'Administrador Limon',    1, 0, 1, SYSUTCDATETIME()),
    (3264, N'Usuario Corporativo',    1, 0, 1, SYSUTCDATETIME());

INSERT INTO Privado.Personas
(
    PersonID, FullName, PhoneNumber, FaxNumber, EmailAddress
)
SELECT
    PersonID, FullName, PhoneNumber, FaxNumber, EmailAddress
FROM WWI_Origen.Application.People;

INSERT INTO Privado.Personas
(
    PersonID, FullName, PhoneNumber, FaxNumber, EmailAddress
)
VALUES
    (3262, N'Administrador San Jose', NULL, NULL, NULL),
    (3263, N'Administrador Limon',    NULL, NULL, NULL),
    (3264, N'Usuario Corporativo',    NULL, NULL, NULL);

/* Catalogos de referencia. */
INSERT INTO Application.DeliveryMethods
    (DeliveryMethodID, DeliveryMethodName, LastEditedBy, LastEditedWhen)
SELECT DeliveryMethodID, DeliveryMethodName, LastEditedBy, ValidFrom
FROM WWI_Origen.Application.DeliveryMethods;

INSERT INTO Application.PaymentMethods
    (PaymentMethodID, PaymentMethodName, LastEditedBy, LastEditedWhen)
SELECT PaymentMethodID, PaymentMethodName, LastEditedBy, ValidFrom
FROM WWI_Origen.Application.PaymentMethods;

INSERT INTO Application.TransactionTypes
    (TransactionTypeID, TransactionTypeName, LastEditedBy, LastEditedWhen)
SELECT TransactionTypeID, TransactionTypeName, LastEditedBy, ValidFrom
FROM WWI_Origen.Application.TransactionTypes;

INSERT INTO Sales.CustomerCategories
    (CustomerCategoryID, CustomerCategoryName, LastEditedBy, LastEditedWhen)
SELECT CustomerCategoryID, CustomerCategoryName, LastEditedBy, ValidFrom
FROM WWI_Origen.Sales.CustomerCategories;

INSERT INTO Sales.BuyingGroups
    (BuyingGroupID, BuyingGroupName, LastEditedBy, LastEditedWhen)
SELECT BuyingGroupID, BuyingGroupName, LastEditedBy, ValidFrom
FROM WWI_Origen.Sales.BuyingGroups;

INSERT INTO Purchasing.SupplierCategories
    (SupplierCategoryID, SupplierCategoryName, LastEditedBy, LastEditedWhen)
SELECT SupplierCategoryID, SupplierCategoryName, LastEditedBy, ValidFrom
FROM WWI_Origen.Purchasing.SupplierCategories;

INSERT INTO Warehouse.StockGroups
    (StockGroupID, StockGroupName, LastEditedBy, LastEditedWhen)
SELECT StockGroupID, StockGroupName, LastEditedBy, ValidFrom
FROM WWI_Origen.Warehouse.StockGroups;

INSERT INTO Warehouse.Colors
    (ColorID, ColorName, LastEditedBy, LastEditedWhen)
SELECT ColorID, ColorName, LastEditedBy, ValidFrom
FROM WWI_Origen.Warehouse.Colors;

INSERT INTO Warehouse.PackageTypes
    (PackageTypeID, PackageTypeName, LastEditedBy, LastEditedWhen)
SELECT PackageTypeID, PackageTypeName, LastEditedBy, ValidFrom
FROM WWI_Origen.Warehouse.PackageTypes;

/* Geografia privada: solo existe en Corporativo. */
INSERT INTO Application.Countries
(
    CountryID, CountryName, FormalName, IsoAlpha3Code, IsoNumericCode,
    CountryType, LatestRecordedPopulation, Continent, Region, Subregion,
    Border, LastEditedBy, LastEditedWhen
)
SELECT
    CountryID, CountryName, FormalName, IsoAlpha3Code, IsoNumericCode,
    CountryType, LatestRecordedPopulation, Continent, Region, Subregion,
    Border, LastEditedBy, ValidFrom
FROM WWI_Origen.Application.Countries;

INSERT INTO Application.StateProvinces
(
    StateProvinceID, StateProvinceCode, StateProvinceName, CountryID,
    SalesTerritory, Border, LatestRecordedPopulation, LastEditedBy, LastEditedWhen
)
SELECT
    StateProvinceID, StateProvinceCode, StateProvinceName, CountryID,
    SalesTerritory, Border, LatestRecordedPopulation, LastEditedBy, ValidFrom
FROM WWI_Origen.Application.StateProvinces;

INSERT INTO Application.Cities
(
    CityID, CityName, StateProvinceID, Location, LatestRecordedPopulation,
    LastEditedBy, LastEditedWhen
)
SELECT
    CityID, CityName, StateProvinceID, Location, LatestRecordedPopulation,
    LastEditedBy, ValidFrom
FROM WWI_Origen.Application.Cities;

/* Fragmento publico y fragmento privado de clientes. */
INSERT INTO Sales.Customers
(
    CustomerID, CustomerName, BillToCustomerID, CustomerCategoryID,
    BuyingGroupID, DeliveryMethodID, AccountOpenedDate, IsStatementSent,
    IsOnCreditHold, PaymentDays, LastEditedBy, LastEditedWhen,
    Activo, VersionCatalogo
)
SELECT
    CustomerID, CustomerName, BillToCustomerID, CustomerCategoryID,
    BuyingGroupID, DeliveryMethodID, AccountOpenedDate, IsStatementSent,
    IsOnCreditHold, PaymentDays, LastEditedBy, ValidFrom, 1, 1
FROM WWI_Origen.Sales.Customers;

INSERT INTO Privado.Clientes
(
    CustomerID, PrimaryContactPersonID, AlternateContactPersonID,
    DeliveryCityID, PostalCityID, CreditLimit, StandardDiscountPercentage,
    PhoneNumber, FaxNumber, DeliveryRun, RunPosition, WebsiteURL,
    DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode,
    DeliveryLocation, PostalAddressLine1, PostalAddressLine2, PostalPostalCode
)
SELECT
    CustomerID, PrimaryContactPersonID, AlternateContactPersonID,
    DeliveryCityID, PostalCityID, CreditLimit, StandardDiscountPercentage,
    PhoneNumber, FaxNumber, DeliveryRun, RunPosition, WebsiteURL,
    DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode,
    DeliveryLocation, PostalAddressLine1, PostalAddressLine2, PostalPostalCode
FROM WWI_Origen.Sales.Customers;

/* Fragmento publico y fragmento privado de proveedores. */
INSERT INTO Purchasing.Suppliers
(
    SupplierID, SupplierName, SupplierCategoryID, DeliveryMethodID,
    PaymentDays, LastEditedBy, LastEditedWhen, Activo, VersionCatalogo
)
SELECT
    SupplierID, SupplierName, SupplierCategoryID, DeliveryMethodID,
    PaymentDays, LastEditedBy, ValidFrom, 1, 1
FROM WWI_Origen.Purchasing.Suppliers;

INSERT INTO Privado.Proveedores
(
    SupplierID, PrimaryContactPersonID, AlternateContactPersonID,
    DeliveryCityID, PostalCityID, SupplierReference, BankAccountName,
    BankAccountBranch, BankAccountCode, BankAccountNumber,
    BankInternationalCode, InternalComments, PhoneNumber, FaxNumber,
    WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2,
    DeliveryPostalCode, DeliveryLocation, PostalAddressLine1,
    PostalAddressLine2, PostalPostalCode
)
SELECT
    SupplierID, PrimaryContactPersonID, AlternateContactPersonID,
    DeliveryCityID, PostalCityID, SupplierReference, BankAccountName,
    BankAccountBranch, BankAccountCode, BankAccountNumber,
    BankInternationalCode, InternalComments, PhoneNumber, FaxNumber,
    WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2,
    DeliveryPostalCode, DeliveryLocation, PostalAddressLine1,
    PostalAddressLine2, PostalPostalCode
FROM WWI_Origen.Purchasing.Suppliers;

/* Productos: se excluyen los campos no clasificados definidos para la migracion. */
INSERT INTO Warehouse.StockItems
(
    StockItemID, StockItemName, SupplierID, ColorID, UnitPackageID,
    OuterPackageID, Brand, Size, LeadTimeDays, QuantityPerOuter,
    IsChillerStock, Barcode, TaxRate, UnitPrice, RecommendedRetailPrice,
    TypicalWeightPerUnit, MarketingComments, InternalComments, Photo,
    CustomFields, LastEditedBy, LastEditedWhen, Activo, VersionCatalogo
)
SELECT
    StockItemID, StockItemName, SupplierID, ColorID, UnitPackageID,
    OuterPackageID, Brand, Size, LeadTimeDays, QuantityPerOuter,
    IsChillerStock, Barcode, TaxRate, UnitPrice, RecommendedRetailPrice,
    TypicalWeightPerUnit, MarketingComments, NULL, Photo,
    NULL, LastEditedBy, ValidFrom, 1, 1
FROM WWI_Origen.Warehouse.StockItems;

INSERT INTO Warehouse.StockItemStockGroups
(
    StockItemStockGroupID, StockItemID, StockGroupID,
    LastEditedBy, LastEditedWhen
)
SELECT
    StockItemStockGroupID, StockItemID, StockGroupID,
    LastEditedBy, LastEditedWhen
FROM WWI_Origen.Warehouse.StockItemStockGroups;

/* Mapas fijos para la fragmentacion horizontal de hechos. */
INSERT INTO Preparacion.AsignacionPedidos (OrderID, SucursalID)
SELECT OrderID, CASE WHEN OrderID % 2 = 0 THEN 1 ELSE 2 END
FROM WWI_Origen.Sales.Orders;

IF EXISTS
(
    SELECT 1
    FROM WWI_Origen.Sales.Invoices AS invoiceObject
    LEFT JOIN Preparacion.AsignacionPedidos AS mapObject
        ON mapObject.OrderID = invoiceObject.OrderID
    WHERE invoiceObject.OrderID IS NOT NULL
      AND mapObject.OrderID IS NULL
)
BEGIN
    THROW 51215, N'Existe una factura cuyo pedido no fue asignado.', 1;
END;

INSERT INTO Preparacion.AsignacionFacturas (InvoiceID, SucursalID)
SELECT
    invoiceObject.InvoiceID,
    CASE
        WHEN invoiceObject.OrderID IS NULL
            THEN CASE WHEN invoiceObject.InvoiceID % 2 = 0 THEN 1 ELSE 2 END
        ELSE mapObject.SucursalID
    END
FROM WWI_Origen.Sales.Invoices AS invoiceObject
LEFT JOIN Preparacion.AsignacionPedidos AS mapObject
    ON mapObject.OrderID = invoiceObject.OrderID;

INSERT INTO Preparacion.AsignacionCompras (PurchaseOrderID, SucursalID)
SELECT PurchaseOrderID, CASE WHEN PurchaseOrderID % 2 = 0 THEN 1 ELSE 2 END
FROM WWI_Origen.Purchasing.PurchaseOrders;

COMMIT TRANSACTION;
GO

/* Las secuencias centrales se crean despues de importar los maximos medidos. */
IF OBJECT_ID(N'Sequences.PersonID', N'SO') IS NULL
    CREATE SEQUENCE Sequences.PersonID AS int START WITH 3265 INCREMENT BY 1 NO CYCLE;

IF OBJECT_ID(N'Sequences.CustomerID', N'SO') IS NULL
    CREATE SEQUENCE Sequences.CustomerID AS int START WITH 1062 INCREMENT BY 1 NO CYCLE;

IF OBJECT_ID(N'Sequences.SupplierID', N'SO') IS NULL
    CREATE SEQUENCE Sequences.SupplierID AS int START WITH 14 INCREMENT BY 1 NO CYCLE;

IF OBJECT_ID(N'Sequences.StockItemID', N'SO') IS NULL
    CREATE SEQUENCE Sequences.StockItemID AS int START WITH 329 INCREMENT BY 1 NO CYCLE;

IF OBJECT_ID(N'Sequences.StockItemStockGroupID', N'SO') IS NULL
    CREATE SEQUENCE Sequences.StockItemStockGroupID AS int START WITH 544 INCREMENT BY 1 NO CYCLE;
GO

/* La foto y los MAX deben poder viajar por replicacion. */
USE [master];
GO
EXEC sys.sp_configure N'show advanced options', 1;
RECONFIGURE;
EXEC sys.sp_configure N'max text repl size (B)', -1;
RECONFIGURE;
GO

USE [WideWorldImporters];
GO

SELECT N'Application.People' AS Tabla, COUNT_BIG(*) AS Filas FROM Application.People
UNION ALL SELECT N'Sales.Customers', COUNT_BIG(*) FROM Sales.Customers
UNION ALL SELECT N'Privado.Clientes', COUNT_BIG(*) FROM Privado.Clientes
UNION ALL SELECT N'Purchasing.Suppliers', COUNT_BIG(*) FROM Purchasing.Suppliers
UNION ALL SELECT N'Privado.Proveedores', COUNT_BIG(*) FROM Privado.Proveedores
UNION ALL SELECT N'Warehouse.StockItems', COUNT_BIG(*) FROM Warehouse.StockItems
UNION ALL SELECT N'Preparacion.AsignacionPedidos', COUNT_BIG(*) FROM Preparacion.AsignacionPedidos
UNION ALL SELECT N'Preparacion.AsignacionFacturas', COUNT_BIG(*) FROM Preparacion.AsignacionFacturas
UNION ALL SELECT N'Preparacion.AsignacionCompras', COUNT_BIG(*) FROM Preparacion.AsignacionCompras;

SELECT
    sequenceObject.name AS Secuencia,
    CONVERT(bigint, sequenceObject.start_value) AS Inicio,
    sequenceObject.is_cycling AS PermiteCiclo
FROM sys.sequences AS sequenceObject
WHERE SCHEMA_NAME(sequenceObject.schema_id) = N'Sequences'
ORDER BY sequenceObject.name;

SELECT N'CATALOG_LOAD_READY' AS Result;
