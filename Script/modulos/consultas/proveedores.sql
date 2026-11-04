USE [WideWorldImporters];
GO

-- Sinónimos utilizados por el módulo de proveedores.
IF OBJECT_ID('dbo.src_Proveedor', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_Proveedor FOR Purchasing.Suppliers;');
GO

IF OBJECT_ID('dbo.src_CategoriaProveedor', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_CategoriaProveedor FOR Purchasing.SupplierCategories;');
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

-- Lista los proveedores. Los filtros son opcionales y se pueden combinar.
CREATE OR ALTER PROCEDURE dbo.usp_Proveedores_Listar
    @SupplierName nvarchar(100) = NULL,
    @SupplierCategoryID int = NULL,
    @DeliveryMethodID int = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT
            S.SupplierID,
            S.SupplierName,
            SC.SupplierCategoryID,
            SC.SupplierCategoryName,
            DM.DeliveryMethodID,
            DM.DeliveryMethodName
        FROM dbo.src_Proveedor AS S
        INNER JOIN dbo.src_CategoriaProveedor AS SC
            ON S.SupplierCategoryID = SC.SupplierCategoryID
        LEFT JOIN dbo.src_MetodoEntrega AS DM
            ON S.DeliveryMethodID = DM.DeliveryMethodID
        WHERE (@SupplierName IS NULL
            OR S.SupplierName LIKE '%' + @SupplierName + '%')
            AND (@SupplierCategoryID IS NULL
            OR S.SupplierCategoryID = @SupplierCategoryID)
            AND (@DeliveryMethodID IS NULL
            OR S.DeliveryMethodID = @DeliveryMethodID)
        ORDER BY S.SupplierName ASC;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

-- Muestra todos los datos de un proveedor.
CREATE OR ALTER PROCEDURE dbo.usp_Proveedores_ObtenerDetalle
    @SupplierID int
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT
            S.SupplierID,
            S.SupplierReference,
            S.SupplierName,
            S.SupplierCategoryID,
            SC.SupplierCategoryName,
            S.PrimaryContactPersonID,
            P1.FullName AS PrimaryContactPerson,
            S.AlternateContactPersonID,
            P2.FullName AS AlternateContactPerson,
            S.DeliveryMethodID,
            DM.DeliveryMethodName,
            S.DeliveryCityID,
            DC.CityName AS DeliveryCityName,
            S.PostalCityID,
            PC.CityName AS PostalCityName,
            S.DeliveryPostalCode,
            S.PhoneNumber,
            S.FaxNumber,
            S.WebsiteURL,
            S.DeliveryAddressLine1,
            S.DeliveryAddressLine2,
            S.PostalAddressLine1,
            S.PostalAddressLine2,
            S.PostalPostalCode,
            CONCAT(
                'Delivery: ', S.DeliveryAddressLine1, ' ', S.DeliveryAddressLine2,
                ' - ', S.DeliveryPostalCode,
                '; Postal: ', S.PostalAddressLine1, ' ', S.PostalAddressLine2,
                ' - ', S.PostalPostalCode
            ) AS [Address],
            S.DeliveryLocation,
            CAST(S.DeliveryLocation.Lat AS decimal(9, 6)) AS DeliveryLatitude,
            CAST(S.DeliveryLocation.Long AS decimal(9, 6)) AS DeliveryLongitude,
            S.BankAccountName,
            S.BankAccountBranch,
            S.BankAccountNumber,
            S.PaymentDays,
            S.LastEditedBy
        FROM dbo.src_Proveedor AS S
        INNER JOIN dbo.src_CategoriaProveedor AS SC
            ON S.SupplierCategoryID = SC.SupplierCategoryID
        INNER JOIN dbo.src_Persona AS P1
            ON S.PrimaryContactPersonID = P1.PersonID
        INNER JOIN dbo.src_Persona AS P2
            ON S.AlternateContactPersonID = P2.PersonID
        LEFT JOIN dbo.src_MetodoEntrega AS DM
            ON S.DeliveryMethodID = DM.DeliveryMethodID
        INNER JOIN dbo.src_Ciudad AS DC
            ON S.DeliveryCityID = DC.CityID
        INNER JOIN dbo.src_Ciudad AS PC
            ON S.PostalCityID = PC.CityID
        WHERE S.SupplierID = @SupplierID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

-- Devuelve los catálogos pequeños utilizados en proveedores.
CREATE OR ALTER PROCEDURE dbo.usp_Proveedores_ObtenerCatalogos
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT
            SupplierCategoryID AS [Value],
            SupplierCategoryName AS [Label]
        FROM dbo.src_CategoriaProveedor
        ORDER BY SupplierCategoryName ASC;

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

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO
