USE [WideWorldImporters];
GO

-- Sinónimos utilizados por el CRUD de proveedores.
IF OBJECT_ID('dbo.src_Proveedor', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_Proveedor FOR Purchasing.Suppliers;');
GO

-- Crea un proveedor.
CREATE OR ALTER PROCEDURE dbo.usp_Proveedores_Crear
    @SupplierName nvarchar(100),
    @SupplierCategoryID int,
    @PrimaryContactPersonID int,
    @AlternateContactPersonID int,
    @DeliveryCityID int,
    @PostalCityID int,
    @PaymentDays int,
    @PhoneNumber nvarchar(20),
    @FaxNumber nvarchar(20),
    @WebsiteURL nvarchar(256),
    @DeliveryAddressLine1 nvarchar(60),
    @DeliveryPostalCode nvarchar(10),
    @PostalAddressLine1 nvarchar(60),
    @PostalPostalCode nvarchar(10),
    @LastEditedBy int,
    @DeliveryMethodID int = NULL,
    @SupplierReference nvarchar(20) = NULL,
    @BankAccountName nvarchar(50) = NULL,
    @BankAccountBranch nvarchar(50) = NULL,
    @BankAccountCode nvarchar(20) = NULL,
    @BankAccountNumber nvarchar(20) = NULL,
    @BankInternationalCode nvarchar(20) = NULL,
    @InternalComments nvarchar(max) = NULL,
    @DeliveryAddressLine2 nvarchar(60) = NULL,
    @DeliveryLatitude decimal(9, 6) = NULL,
    @DeliveryLongitude decimal(9, 6) = NULL,
    @PostalAddressLine2 nvarchar(60) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF (@DeliveryLatitude IS NULL AND @DeliveryLongitude IS NOT NULL)
            OR (@DeliveryLatitude IS NOT NULL AND @DeliveryLongitude IS NULL)
            THROW 50101, 'Debe enviar la latitud y la longitud juntas.', 1;

        DECLARE @NewSupplierID int = NEXT VALUE FOR Sequences.SupplierID;
        DECLARE @DeliveryLocation geography = NULL;

        IF @DeliveryLatitude IS NOT NULL AND @DeliveryLongitude IS NOT NULL
            SET @DeliveryLocation = geography::Point(
                @DeliveryLatitude,
                @DeliveryLongitude,
                4326
            );

        INSERT INTO dbo.src_Proveedor
        (
            SupplierID,
            SupplierName,
            SupplierCategoryID,
            PrimaryContactPersonID,
            AlternateContactPersonID,
            DeliveryMethodID,
            DeliveryCityID,
            PostalCityID,
            SupplierReference,
            BankAccountName,
            BankAccountBranch,
            BankAccountCode,
            BankAccountNumber,
            BankInternationalCode,
            PaymentDays,
            InternalComments,
            PhoneNumber,
            FaxNumber,
            WebsiteURL,
            DeliveryAddressLine1,
            DeliveryAddressLine2,
            DeliveryPostalCode,
            DeliveryLocation,
            PostalAddressLine1,
            PostalAddressLine2,
            PostalPostalCode,
            LastEditedBy
        )
        VALUES
        (
            @NewSupplierID,
            @SupplierName,
            @SupplierCategoryID,
            @PrimaryContactPersonID,
            @AlternateContactPersonID,
            @DeliveryMethodID,
            @DeliveryCityID,
            @PostalCityID,
            @SupplierReference,
            @BankAccountName,
            @BankAccountBranch,
            @BankAccountCode,
            @BankAccountNumber,
            @BankInternationalCode,
            @PaymentDays,
            @InternalComments,
            @PhoneNumber,
            @FaxNumber,
            @WebsiteURL,
            @DeliveryAddressLine1,
            @DeliveryAddressLine2,
            @DeliveryPostalCode,
            @DeliveryLocation,
            @PostalAddressLine1,
            @PostalAddressLine2,
            @PostalPostalCode,
            @LastEditedBy
        );

        SELECT @NewSupplierID AS SupplierID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

-- Actualiza todos los datos editables de un proveedor.
CREATE OR ALTER PROCEDURE dbo.usp_Proveedores_Actualizar
    @SupplierID int,
    @SupplierName nvarchar(100),
    @SupplierCategoryID int,
    @PrimaryContactPersonID int,
    @AlternateContactPersonID int,
    @DeliveryCityID int,
    @PostalCityID int,
    @PaymentDays int,
    @PhoneNumber nvarchar(20),
    @FaxNumber nvarchar(20),
    @WebsiteURL nvarchar(256),
    @DeliveryAddressLine1 nvarchar(60),
    @DeliveryPostalCode nvarchar(10),
    @PostalAddressLine1 nvarchar(60),
    @PostalPostalCode nvarchar(10),
    @LastEditedBy int,
    @DeliveryMethodID int = NULL,
    @SupplierReference nvarchar(20) = NULL,
    @BankAccountName nvarchar(50) = NULL,
    @BankAccountBranch nvarchar(50) = NULL,
    @BankAccountCode nvarchar(20) = NULL,
    @BankAccountNumber nvarchar(20) = NULL,
    @BankInternationalCode nvarchar(20) = NULL,
    @InternalComments nvarchar(max) = NULL,
    @DeliveryAddressLine2 nvarchar(60) = NULL,
    @DeliveryLatitude decimal(9, 6) = NULL,
    @DeliveryLongitude decimal(9, 6) = NULL,
    @PostalAddressLine2 nvarchar(60) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF (@DeliveryLatitude IS NULL AND @DeliveryLongitude IS NOT NULL)
            OR (@DeliveryLatitude IS NOT NULL AND @DeliveryLongitude IS NULL)
            THROW 50101, 'Debe enviar la latitud y la longitud juntas.', 1;

        DECLARE @DeliveryLocation geography = NULL;

        IF @DeliveryLatitude IS NOT NULL AND @DeliveryLongitude IS NOT NULL
            SET @DeliveryLocation = geography::Point(
                @DeliveryLatitude,
                @DeliveryLongitude,
                4326
            );

        UPDATE dbo.src_Proveedor
        SET SupplierName = @SupplierName,
            SupplierCategoryID = @SupplierCategoryID,
            PrimaryContactPersonID = @PrimaryContactPersonID,
            AlternateContactPersonID = @AlternateContactPersonID,
            DeliveryMethodID = @DeliveryMethodID,
            DeliveryCityID = @DeliveryCityID,
            PostalCityID = @PostalCityID,
            SupplierReference = @SupplierReference,
            BankAccountName = @BankAccountName,
            BankAccountBranch = @BankAccountBranch,
            BankAccountCode = ISNULL(@BankAccountCode, BankAccountCode),
            BankAccountNumber = @BankAccountNumber,
            BankInternationalCode = ISNULL(@BankInternationalCode, BankInternationalCode),
            PaymentDays = @PaymentDays,
            InternalComments = ISNULL(@InternalComments, InternalComments),
            PhoneNumber = @PhoneNumber,
            FaxNumber = @FaxNumber,
            WebsiteURL = @WebsiteURL,
            DeliveryAddressLine1 = @DeliveryAddressLine1,
            DeliveryAddressLine2 = @DeliveryAddressLine2,
            DeliveryPostalCode = @DeliveryPostalCode,
            DeliveryLocation = @DeliveryLocation,
            PostalAddressLine1 = @PostalAddressLine1,
            PostalAddressLine2 = @PostalAddressLine2,
            PostalPostalCode = @PostalPostalCode,
            LastEditedBy = @LastEditedBy
        WHERE SupplierID = @SupplierID;

        IF @@ROWCOUNT = 0
            THROW 50102, 'El proveedor no existe.', 1;

        SELECT @SupplierID AS SupplierID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

-- Elimina un proveedor. Se impide eliminarlo si otra tabla todavía lo usa.
CREATE OR ALTER PROCEDURE dbo.usp_Proveedores_Eliminar
    @SupplierID int
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM dbo.src_Proveedor
        WHERE SupplierID = @SupplierID;

        IF @@ROWCOUNT = 0
            THROW 50102, 'El proveedor no existe.', 1;

        SELECT @SupplierID AS SupplierID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO
