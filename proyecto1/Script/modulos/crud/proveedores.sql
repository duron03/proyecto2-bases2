USE [WideWorldImporters];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

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
    @LastEditedBy int = NULL,
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
    SET XACT_ABORT ON;

    DECLARE @Actor int;
    SELECT @Actor = PersonID
    FROM Seguridad.Usuarios
    WHERE SqlLogin = ORIGINAL_LOGIN()
      AND active = 1
      AND rol = N'ADMINISTRADOR';

    IF @Actor IS NULL
        THROW 50403, 'El usuario no puede modificar proveedores.', 1;

    IF (@DeliveryLatitude IS NULL AND @DeliveryLongitude IS NOT NULL)
       OR (@DeliveryLatitude IS NOT NULL AND @DeliveryLongitude IS NULL)
        THROW 50101, 'La latitud y longitud deben enviarse juntas.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @NewSupplierID int = NEXT VALUE FOR Sequences.SupplierID;
        DECLARE @DeliveryLocation geography = NULL;

        IF @DeliveryLatitude IS NOT NULL
            SET @DeliveryLocation = geography::Point(@DeliveryLatitude, @DeliveryLongitude, 4326);

        INSERT INTO Purchasing.Suppliers
        (
            SupplierID, SupplierName, SupplierCategoryID, DeliveryMethodID,
            PaymentDays, LastEditedBy, LastEditedWhen, Activo, VersionCatalogo
        )
        VALUES
        (
            @NewSupplierID, @SupplierName, @SupplierCategoryID, @DeliveryMethodID,
            @PaymentDays, @Actor, SYSUTCDATETIME(), 1, 1
        );

        INSERT INTO Privado.Proveedores
        (
            SupplierID, PrimaryContactPersonID, AlternateContactPersonID,
            DeliveryCityID, PostalCityID, SupplierReference,
            BankAccountName, BankAccountBranch, BankAccountCode,
            BankAccountNumber, BankInternationalCode, InternalComments,
            PhoneNumber, FaxNumber, WebsiteURL,
            DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode,
            DeliveryLocation, PostalAddressLine1, PostalAddressLine2, PostalPostalCode
        )
        VALUES
        (
            @NewSupplierID, @PrimaryContactPersonID, @AlternateContactPersonID,
            @DeliveryCityID, @PostalCityID, @SupplierReference,
            @BankAccountName, @BankAccountBranch, @BankAccountCode,
            @BankAccountNumber, @BankInternationalCode, @InternalComments,
            @PhoneNumber, @FaxNumber, @WebsiteURL,
            @DeliveryAddressLine1, @DeliveryAddressLine2, @DeliveryPostalCode,
            @DeliveryLocation, @PostalAddressLine1, @PostalAddressLine2, @PostalPostalCode
        );

        COMMIT TRANSACTION;
        SELECT @NewSupplierID AS SupplierID, 1 AS VersionCatalogo;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

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
    @VersionEsperada int,
    @LastEditedBy int = NULL,
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
    SET XACT_ABORT ON;

    DECLARE @Actor int;
    SELECT @Actor = PersonID
    FROM Seguridad.Usuarios
    WHERE SqlLogin = ORIGINAL_LOGIN()
      AND active = 1
      AND rol = N'ADMINISTRADOR';

    IF @Actor IS NULL
        THROW 50403, 'El usuario no puede modificar proveedores.', 1;

    IF @VersionEsperada <= 0
        THROW 50401, 'La version esperada no es valida.', 1;

    IF (@DeliveryLatitude IS NULL AND @DeliveryLongitude IS NOT NULL)
       OR (@DeliveryLatitude IS NOT NULL AND @DeliveryLongitude IS NULL)
        THROW 50101, 'La latitud y longitud deben enviarse juntas.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE Purchasing.Suppliers
        SET SupplierName = @SupplierName,
            SupplierCategoryID = @SupplierCategoryID,
            DeliveryMethodID = @DeliveryMethodID,
            PaymentDays = @PaymentDays,
            LastEditedBy = @Actor,
            LastEditedWhen = SYSUTCDATETIME(),
            VersionCatalogo = VersionCatalogo + 1
        WHERE SupplierID = @SupplierID
          AND VersionCatalogo = @VersionEsperada
          AND Activo = 1;

        IF @@ROWCOUNT = 0
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM Purchasing.Suppliers WHERE SupplierID = @SupplierID)
                THROW 50102, 'El proveedor no existe.', 1;
            THROW 50401, 'El proveedor fue modificado por otra sesion o esta inactivo.', 1;
        END;

        UPDATE Privado.Proveedores
        SET PrimaryContactPersonID = @PrimaryContactPersonID,
            AlternateContactPersonID = @AlternateContactPersonID,
            DeliveryCityID = @DeliveryCityID,
            PostalCityID = @PostalCityID,
            SupplierReference = @SupplierReference,
            BankAccountName = @BankAccountName,
            BankAccountBranch = @BankAccountBranch,
            BankAccountCode = @BankAccountCode,
            BankAccountNumber = @BankAccountNumber,
            BankInternationalCode = @BankInternationalCode,
            InternalComments = @InternalComments,
            PhoneNumber = @PhoneNumber,
            FaxNumber = @FaxNumber,
            WebsiteURL = @WebsiteURL,
            DeliveryAddressLine1 = @DeliveryAddressLine1,
            DeliveryAddressLine2 = @DeliveryAddressLine2,
            DeliveryPostalCode = @DeliveryPostalCode,
            DeliveryLocation = CASE
                WHEN @DeliveryLatitude IS NULL THEN NULL
                ELSE geography::Point(@DeliveryLatitude, @DeliveryLongitude, 4326)
            END,
            PostalAddressLine1 = @PostalAddressLine1,
            PostalAddressLine2 = @PostalAddressLine2,
            PostalPostalCode = @PostalPostalCode
        WHERE SupplierID = @SupplierID;

        IF @@ROWCOUNT = 0
            THROW 50102, 'No existe el fragmento privado del proveedor.', 1;

        COMMIT TRANSACTION;
        SELECT @SupplierID AS SupplierID, @VersionEsperada + 1 AS VersionCatalogo;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Proveedores_Eliminar
    @SupplierID int,
    @VersionEsperada int
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Actor int;
    SELECT @Actor = PersonID
    FROM Seguridad.Usuarios
    WHERE SqlLogin = ORIGINAL_LOGIN()
      AND active = 1
      AND rol = N'ADMINISTRADOR';

    IF @Actor IS NULL
        THROW 50403, 'El usuario no puede dar de baja proveedores.', 1;

    BEGIN TRANSACTION;
    BEGIN TRY
        UPDATE Purchasing.Suppliers
        SET Activo = 0,
            VersionCatalogo = VersionCatalogo + 1,
            LastEditedBy = @Actor,
            LastEditedWhen = SYSUTCDATETIME()
        WHERE SupplierID = @SupplierID
          AND VersionCatalogo = @VersionEsperada
          AND Activo = 1;

        IF @@ROWCOUNT = 0
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM Purchasing.Suppliers WHERE SupplierID = @SupplierID)
                THROW 50102, 'El proveedor no existe.', 1;
            THROW 50401, 'El proveedor fue modificado por otra sesion o ya esta inactivo.', 1;
        END;

        COMMIT TRANSACTION;
        SELECT @SupplierID AS SupplierID, @VersionEsperada + 1 AS VersionCatalogo;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
