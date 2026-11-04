USE [WideWorldImporters];
GO

-- Sinónimos utilizados por el módulo de clientes.
IF OBJECT_ID('dbo.src_Cliente', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_Cliente FOR Sales.Customers;');
GO

IF OBJECT_ID('dbo.src_CategoriaCliente', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_CategoriaCliente FOR Sales.CustomerCategories;');
GO

IF OBJECT_ID('dbo.src_GrupoCompra', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_GrupoCompra FOR Sales.BuyingGroups;');
GO

IF OBJECT_ID('dbo.src_Persona', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_Persona FOR Application.People;');
GO

IF OBJECT_ID('dbo.src_MetodoEntrega', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_MetodoEntrega FOR Application.DeliveryMethods;');
GO

IF OBJECT_ID('dbo.src_Ciudad', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_Ciudad FOR Application.Cities;');
GO

IF OBJECT_ID('dbo.src_Provincia', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_Provincia FOR Application.StateProvinces;');
GO

IF OBJECT_ID('dbo.src_Pais', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_Pais FOR Application.Countries;');
GO

-- Lista los clientes. Los filtros son opcionales y se pueden combinar.
CREATE OR ALTER PROCEDURE dbo.usp_Clientes_Listar
    @CustomerName nvarchar(100) = NULL,
    @CustomerCategoryID int = NULL,
    @DeliveryMethodID int = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT
            C.CustomerID,
            C.CustomerName,
            CC.CustomerCategoryID,
            CC.CustomerCategoryName,
            DM.DeliveryMethodID,
            DM.DeliveryMethodName
        FROM dbo.src_Cliente AS C
        INNER JOIN dbo.src_CategoriaCliente AS CC
            ON C.CustomerCategoryID = CC.CustomerCategoryID
        INNER JOIN dbo.src_MetodoEntrega AS DM
            ON C.DeliveryMethodID = DM.DeliveryMethodID
        WHERE (@CustomerName IS NULL
            OR C.CustomerName LIKE '%' + @CustomerName + '%')
            AND (@CustomerCategoryID IS NULL
            OR C.CustomerCategoryID = @CustomerCategoryID)
            AND (@DeliveryMethodID IS NULL
            OR C.DeliveryMethodID = @DeliveryMethodID)
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

-- Muestra todos los datos de un cliente.
CREATE OR ALTER PROCEDURE dbo.usp_Clientes_ObtenerDetalle
    @CustomerID int
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT
            C.CustomerID,
            C.CustomerName,
            C.CustomerCategoryID,
            CC.CustomerCategoryName,
            C.BuyingGroupID,
            BG.BuyingGroupName,
            C.PrimaryContactPersonID,
            P1.FullName AS PrimaryContactPerson,
            C.AlternateContactPersonID,
            P2.FullName AS AlternateContactPerson,
            C1.CustomerID AS BillToCustomerID,
            C1.CustomerName AS BillToCustomerName,
            C.DeliveryMethodID,
            DM.DeliveryMethodName,
            C.DeliveryCityID,
            DC.CityName AS DeliveryCityName,
            C.PostalCityID,
            PC.CityName AS PostalCityName,
            CONVERT(char(10), C.AccountOpenedDate, 23) AS AccountOpenedDate,
            C.StandardDiscountPercentage,
            C.IsStatementSent,
            C.IsOnCreditHold,
            C.CreditLimit,
            C.DeliveryPostalCode,
            C.PhoneNumber,
            C.FaxNumber,
            C.PaymentDays,
            C.WebsiteURL,
            C.DeliveryRun,
            C.RunPosition,
            C.DeliveryAddressLine1,
            C.DeliveryAddressLine2,
            C.PostalAddressLine1,
            C.PostalAddressLine2,
            C.PostalPostalCode,
            CONCAT(
                'Delivery: ', C.DeliveryAddressLine1, ' ', C.DeliveryAddressLine2,
                ' - ', C.DeliveryPostalCode,
                '; Postal: ', C.PostalAddressLine1, ' ', C.PostalAddressLine2,
                ' - ', C.PostalPostalCode
            ) AS [Address],
            C.DeliveryLocation,
            CAST(C.DeliveryLocation.Lat AS decimal(9, 6)) AS DeliveryLatitude,
            CAST(C.DeliveryLocation.Long AS decimal(9, 6)) AS DeliveryLongitude,
            C.LastEditedBy
        FROM dbo.src_Cliente AS C
        INNER JOIN dbo.src_CategoriaCliente AS CC
            ON C.CustomerCategoryID = CC.CustomerCategoryID
        LEFT JOIN dbo.src_GrupoCompra AS BG
            ON C.BuyingGroupID = BG.BuyingGroupID
        INNER JOIN dbo.src_Persona AS P1
            ON C.PrimaryContactPersonID = P1.PersonID
        LEFT JOIN dbo.src_Persona AS P2
            ON C.AlternateContactPersonID = P2.PersonID
        INNER JOIN dbo.src_Cliente AS C1
            ON C.BillToCustomerID = C1.CustomerID
        INNER JOIN dbo.src_MetodoEntrega AS DM
            ON C.DeliveryMethodID = DM.DeliveryMethodID
        INNER JOIN dbo.src_Ciudad AS DC
            ON C.DeliveryCityID = DC.CityID
        INNER JOIN dbo.src_Ciudad AS PC
            ON C.PostalCityID = PC.CityID
        WHERE C.CustomerID = @CustomerID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

-- Devuelve los catálogos pequeños utilizados en clientes.
CREATE OR ALTER PROCEDURE dbo.usp_Clientes_ObtenerCatalogos
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT
            CustomerCategoryID AS [Value],
            CustomerCategoryName AS [Label]
        FROM dbo.src_CategoriaCliente
        ORDER BY CustomerCategoryName ASC;

        SELECT
            BuyingGroupID AS [Value],
            BuyingGroupName AS [Label]
        FROM dbo.src_GrupoCompra
        ORDER BY BuyingGroupName ASC;

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
            CustomerID AS [Value],
            CustomerName AS [Label]
        FROM dbo.src_Cliente
        ORDER BY CustomerName ASC;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

-- Busca ciudades por nombre. También permite obtener una ciudad por su ID.
CREATE OR ALTER PROCEDURE dbo.usp_Ciudades_Buscar
    @CityName nvarchar(50) = NULL,
    @CityID int = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT TOP (50)
            C.CityID AS [Value],
            CONCAT(
                C.CityName, ', ',
                SP.StateProvinceName, ', ',
                CO.CountryName
            ) AS [Label]
        FROM dbo.src_Ciudad AS C
        INNER JOIN dbo.src_Provincia AS SP
            ON C.StateProvinceID = SP.StateProvinceID
        INNER JOIN dbo.src_Pais AS CO
            ON SP.CountryID = CO.CountryID
        WHERE (@CityID IS NULL OR C.CityID = @CityID)
            AND (@CityName IS NULL
            OR C.CityName LIKE '%' + @CityName + '%')
        ORDER BY C.CityName ASC;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO
