:on error exit
SET NOCOUNT ON;

USE [WideWorldImporters];
GO

CREATE OR ALTER PROCEDURE dbo.usp_Clientes_ObtenerPrivados
    @CustomerID int
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS
    (
        SELECT 1 FROM Seguridad.Usuarios
        WHERE SqlLogin = ORIGINAL_LOGIN() AND active = 1 AND rol = N'ADMINISTRADOR'
    )
        THROW 50403, 'El usuario no puede consultar datos privados.', 1;

    SELECT
        P.CustomerID,
        P.PrimaryContactPersonID,
        PC.FullName AS PrimaryContactPerson,
        P.AlternateContactPersonID,
        AC.FullName AS AlternateContactPerson,
        P.DeliveryCityID,
        DC.CityName AS DeliveryCityName,
        P.PostalCityID,
        PoC.CityName AS PostalCityName,
        P.CreditLimit,
        P.StandardDiscountPercentage,
        P.PhoneNumber,
        P.FaxNumber,
        P.DeliveryRun,
        P.RunPosition,
        P.WebsiteURL,
        P.DeliveryAddressLine1,
        P.DeliveryAddressLine2,
        P.DeliveryPostalCode,
        P.PostalAddressLine1,
        P.PostalAddressLine2,
        P.PostalPostalCode,
        CAST(P.DeliveryLocation.Lat AS decimal(9, 6)) AS DeliveryLatitude,
        CAST(P.DeliveryLocation.Long AS decimal(9, 6)) AS DeliveryLongitude,
        C.VersionCatalogo
    FROM Privado.Clientes AS P
    INNER JOIN Sales.Customers AS C ON P.CustomerID = C.CustomerID
    INNER JOIN Privado.Personas AS PC ON P.PrimaryContactPersonID = PC.PersonID
    LEFT JOIN Privado.Personas AS AC ON P.AlternateContactPersonID = AC.PersonID
    INNER JOIN Application.Cities AS DC ON P.DeliveryCityID = DC.CityID
    INNER JOIN Application.Cities AS PoC ON P.PostalCityID = PoC.CityID
    WHERE P.CustomerID = @CustomerID;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Clientes_ObtenerDatosEdicion
    @CustomerID int
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS
    (
        SELECT 1 FROM Seguridad.Usuarios
        WHERE SqlLogin = ORIGINAL_LOGIN() AND active = 1 AND rol = N'ADMINISTRADOR'
    )
        THROW 50403, 'El usuario no puede editar datos privados.', 1;

    SELECT
        C.CustomerID,
        C.CustomerName,
        C.BillToCustomerID,
        C.CustomerCategoryID,
        C.BuyingGroupID,
        C.PrimaryContactPersonID,
        C.AlternateContactPersonID,
        C.DeliveryMethodID,
        C.DeliveryCityID,
        C.PostalCityID,
        C.CreditLimit,
        C.AccountOpenedDate,
        C.StandardDiscountPercentage,
        C.IsStatementSent,
        C.IsOnCreditHold,
        C.PaymentDays,
        C.PhoneNumber,
        C.FaxNumber,
        C.DeliveryRun,
        C.RunPosition,
        C.WebsiteURL,
        C.DeliveryAddressLine1,
        C.DeliveryAddressLine2,
        C.DeliveryPostalCode,
        C.PostalAddressLine1,
        C.PostalAddressLine2,
        C.PostalPostalCode,
        C.Activo,
        C.VersionCatalogo,
        CAST(C.DeliveryLocation.Lat AS decimal(9, 6)) AS DeliveryLatitude,
        CAST(C.DeliveryLocation.Long AS decimal(9, 6)) AS DeliveryLongitude
    FROM Privado.v_ClientesCompletos AS C
    WHERE C.CustomerID = @CustomerID;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Clientes_ObtenerCatalogosEdicion
    @CustomerID int = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS
    (
        SELECT 1 FROM Seguridad.Usuarios
        WHERE SqlLogin = ORIGINAL_LOGIN() AND active = 1 AND rol = N'ADMINISTRADOR'
    )
        THROW 50403, 'El usuario no puede consultar catalogos privados.', 1;

    SELECT CustomerCategoryID AS [Value], CustomerCategoryName AS [Label]
    FROM Sales.CustomerCategories ORDER BY CustomerCategoryName;

    SELECT BuyingGroupID AS [Value], BuyingGroupName AS [Label]
    FROM Sales.BuyingGroups ORDER BY BuyingGroupName;

    SELECT PersonID AS [Value], FullName AS [Label]
    FROM Privado.Personas ORDER BY FullName;

    SELECT DeliveryMethodID AS [Value], DeliveryMethodName AS [Label]
    FROM Application.DeliveryMethods ORDER BY DeliveryMethodName;

    SELECT CustomerID AS [Value],
        CustomerName + CASE WHEN Activo = 0 THEN N' (inactivo)' ELSE N'' END AS [Label]
    FROM Sales.Customers AS C
    WHERE C.Activo = 1
       OR EXISTS
       (
           SELECT 1 FROM Sales.Customers AS Actual
           WHERE Actual.CustomerID = @CustomerID
             AND Actual.BillToCustomerID = C.CustomerID
       )
    ORDER BY CustomerName;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Proveedores_ObtenerPrivados
    @SupplierID int
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS
    (
        SELECT 1 FROM Seguridad.Usuarios
        WHERE SqlLogin = ORIGINAL_LOGIN() AND active = 1 AND rol = N'ADMINISTRADOR'
    )
        THROW 50403, 'El usuario no puede consultar datos privados.', 1;

    SELECT
        P.SupplierID,
        P.PrimaryContactPersonID,
        PC.FullName AS PrimaryContactPerson,
        P.AlternateContactPersonID,
        AC.FullName AS AlternateContactPerson,
        P.DeliveryCityID,
        DC.CityName AS DeliveryCityName,
        P.PostalCityID,
        PoC.CityName AS PostalCityName,
        P.SupplierReference,
        P.BankAccountName,
        P.BankAccountBranch,
        P.BankAccountCode,
        P.BankAccountNumber,
        P.BankInternationalCode,
        P.InternalComments,
        P.PhoneNumber,
        P.FaxNumber,
        P.WebsiteURL,
        P.DeliveryAddressLine1,
        P.DeliveryAddressLine2,
        P.DeliveryPostalCode,
        P.PostalAddressLine1,
        P.PostalAddressLine2,
        P.PostalPostalCode,
        CAST(P.DeliveryLocation.Lat AS decimal(9, 6)) AS DeliveryLatitude,
        CAST(P.DeliveryLocation.Long AS decimal(9, 6)) AS DeliveryLongitude,
        S.VersionCatalogo
    FROM Privado.Proveedores AS P
    INNER JOIN Purchasing.Suppliers AS S ON P.SupplierID = S.SupplierID
    INNER JOIN Privado.Personas AS PC ON P.PrimaryContactPersonID = PC.PersonID
    INNER JOIN Privado.Personas AS AC ON P.AlternateContactPersonID = AC.PersonID
    INNER JOIN Application.Cities AS DC ON P.DeliveryCityID = DC.CityID
    INNER JOIN Application.Cities AS PoC ON P.PostalCityID = PoC.CityID
    WHERE P.SupplierID = @SupplierID;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Proveedores_ObtenerDatosEdicion
    @SupplierID int
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS
    (
        SELECT 1 FROM Seguridad.Usuarios
        WHERE SqlLogin = ORIGINAL_LOGIN() AND active = 1 AND rol = N'ADMINISTRADOR'
    )
        THROW 50403, 'El usuario no puede editar datos privados.', 1;

    SELECT
        S.SupplierID,
        S.SupplierName,
        S.SupplierCategoryID,
        S.PrimaryContactPersonID,
        S.AlternateContactPersonID,
        S.DeliveryMethodID,
        S.DeliveryCityID,
        S.PostalCityID,
        S.SupplierReference,
        S.BankAccountName,
        S.BankAccountBranch,
        S.BankAccountCode,
        S.BankAccountNumber,
        S.BankInternationalCode,
        S.PaymentDays,
        S.InternalComments,
        S.PhoneNumber,
        S.FaxNumber,
        S.WebsiteURL,
        S.DeliveryAddressLine1,
        S.DeliveryAddressLine2,
        S.DeliveryPostalCode,
        S.PostalAddressLine1,
        S.PostalAddressLine2,
        S.PostalPostalCode,
        S.Activo,
        S.VersionCatalogo,
        CAST(S.DeliveryLocation.Lat AS decimal(9, 6)) AS DeliveryLatitude,
        CAST(S.DeliveryLocation.Long AS decimal(9, 6)) AS DeliveryLongitude
    FROM Privado.v_ProveedoresCompletos AS S
    WHERE S.SupplierID = @SupplierID;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Proveedores_ObtenerCatalogosEdicion
    @SupplierID int = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS
    (
        SELECT 1 FROM Seguridad.Usuarios
        WHERE SqlLogin = ORIGINAL_LOGIN() AND active = 1 AND rol = N'ADMINISTRADOR'
    )
        THROW 50403, 'El usuario no puede consultar catalogos privados.', 1;

    SELECT SupplierCategoryID AS [Value], SupplierCategoryName AS [Label]
    FROM Purchasing.SupplierCategories ORDER BY SupplierCategoryName;

    SELECT PersonID AS [Value], FullName AS [Label]
    FROM Privado.Personas ORDER BY FullName;

    SELECT DeliveryMethodID AS [Value], DeliveryMethodName AS [Label]
    FROM Application.DeliveryMethods ORDER BY DeliveryMethodName;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Inventarios_ObtenerCatalogoCentral
    @StockItemID int
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS
    (
        SELECT 1 FROM Seguridad.Usuarios
        WHERE SqlLogin = ORIGINAL_LOGIN() AND active = 1 AND rol = N'ADMINISTRADOR'
    )
        THROW 50403, 'El usuario no puede consultar el catalogo central.', 1;

    SELECT
        SI.StockItemID, SI.StockItemName, SI.SupplierID, SI.ColorID,
        SI.UnitPackageID, SI.OuterPackageID, SI.Brand, SI.Size,
        SI.LeadTimeDays, SI.QuantityPerOuter, SI.IsChillerStock, SI.Barcode,
        SI.TaxRate, SI.UnitPrice, SI.RecommendedRetailPrice,
        SI.TypicalWeightPerUnit, SI.MarketingComments, SI.InternalComments,
        SI.Photo, SI.CustomFields, SI.Activo, SI.VersionCatalogo
    FROM Warehouse.StockItems AS SI
    WHERE SI.StockItemID = @StockItemID;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Inventarios_ObtenerCatalogosEdicion
    @StockItemID int = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS
    (
        SELECT 1 FROM Seguridad.Usuarios
        WHERE SqlLogin = ORIGINAL_LOGIN() AND active = 1 AND rol = N'ADMINISTRADOR'
    )
        THROW 50403, 'El usuario no puede consultar el catalogo central.', 1;

    SELECT SupplierID AS [Value],
        SupplierName + CASE WHEN Activo = 0 THEN N' (inactivo)' ELSE N'' END AS [Label]
    FROM Purchasing.Suppliers AS S
    WHERE S.Activo = 1
       OR EXISTS
       (
           SELECT 1 FROM Warehouse.StockItems AS SI
           WHERE SI.StockItemID = @StockItemID AND SI.SupplierID = S.SupplierID
       )
    ORDER BY SupplierName;

    SELECT StockGroupID AS [Value], StockGroupName AS [Label]
    FROM Warehouse.StockGroups ORDER BY StockGroupName;

    SELECT ColorID AS [Value], ColorName AS [Label]
    FROM Warehouse.Colors ORDER BY ColorName;

    SELECT PackageTypeID AS [Value], PackageTypeName AS [Label]
    FROM Warehouse.PackageTypes ORDER BY PackageTypeName;
END;
GO
