USE [WideWorldImporters];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Clientes_Crear
    @CustomerName nvarchar(100),
    @CustomerCategoryID int,
    @PrimaryContactPersonID int,
    @DeliveryMethodID int,
    @DeliveryCityID int,
    @PostalCityID int,
    @AccountOpenedDate date,
    @StandardDiscountPercentage decimal(18, 3),
    @IsStatementSent bit,
    @IsOnCreditHold bit,
    @PaymentDays int,
    @PhoneNumber nvarchar(20),
    @FaxNumber nvarchar(20),
    @WebsiteURL nvarchar(256),
    @DeliveryAddressLine1 nvarchar(60),
    @DeliveryPostalCode nvarchar(10),
    @PostalAddressLine1 nvarchar(60),
    @PostalPostalCode nvarchar(10),
    @LastEditedBy int = NULL,
    @BillToCustomerID int = NULL,
    @BuyingGroupID int = NULL,
    @AlternateContactPersonID int = NULL,
    @CreditLimit decimal(18, 2) = NULL,
    @DeliveryRun nvarchar(5) = NULL,
    @RunPosition nvarchar(5) = NULL,
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
        THROW 50403, 'El usuario no puede modificar clientes.', 1;

    IF (@DeliveryLatitude IS NULL AND @DeliveryLongitude IS NOT NULL)
       OR (@DeliveryLatitude IS NOT NULL AND @DeliveryLongitude IS NULL)
        THROW 50001, 'La latitud y longitud deben enviarse juntas.', 1;

    IF @BillToCustomerID IS NOT NULL
       AND NOT EXISTS
       (
           SELECT 1 FROM Sales.Customers
           WHERE CustomerID = @BillToCustomerID AND Activo = 1
       )
        THROW 50402, 'El cliente de facturacion no esta activo.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @NewCustomerID int = NEXT VALUE FOR Sequences.CustomerID;
        DECLARE @DeliveryLocation geography = NULL;

        IF @DeliveryLatitude IS NOT NULL
            SET @DeliveryLocation = geography::Point(@DeliveryLatitude, @DeliveryLongitude, 4326);

        INSERT INTO Sales.Customers
        (
            CustomerID, CustomerName, BillToCustomerID, CustomerCategoryID,
            BuyingGroupID, DeliveryMethodID, AccountOpenedDate,
            IsStatementSent, IsOnCreditHold, PaymentDays,
            LastEditedBy, LastEditedWhen, Activo, VersionCatalogo
        )
        VALUES
        (
            @NewCustomerID, @CustomerName, COALESCE(@BillToCustomerID, @NewCustomerID),
            @CustomerCategoryID, @BuyingGroupID, @DeliveryMethodID,
            @AccountOpenedDate, @IsStatementSent, @IsOnCreditHold, @PaymentDays,
            @Actor, SYSUTCDATETIME(), 1, 1
        );

        INSERT INTO Privado.Clientes
        (
            CustomerID, PrimaryContactPersonID, AlternateContactPersonID,
            DeliveryCityID, PostalCityID, CreditLimit, StandardDiscountPercentage,
            PhoneNumber, FaxNumber, DeliveryRun, RunPosition, WebsiteURL,
            DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode,
            DeliveryLocation, PostalAddressLine1, PostalAddressLine2, PostalPostalCode
        )
        VALUES
        (
            @NewCustomerID, @PrimaryContactPersonID, @AlternateContactPersonID,
            @DeliveryCityID, @PostalCityID, @CreditLimit, @StandardDiscountPercentage,
            @PhoneNumber, @FaxNumber, @DeliveryRun, @RunPosition, @WebsiteURL,
            @DeliveryAddressLine1, @DeliveryAddressLine2, @DeliveryPostalCode,
            @DeliveryLocation, @PostalAddressLine1, @PostalAddressLine2, @PostalPostalCode
        );

        COMMIT TRANSACTION;

        SELECT @NewCustomerID AS CustomerID, 1 AS VersionCatalogo;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Clientes_Actualizar
    @CustomerID int,
    @CustomerName nvarchar(100),
    @CustomerCategoryID int,
    @PrimaryContactPersonID int,
    @DeliveryMethodID int,
    @DeliveryCityID int,
    @PostalCityID int,
    @AccountOpenedDate date,
    @StandardDiscountPercentage decimal(18, 3),
    @IsStatementSent bit,
    @IsOnCreditHold bit,
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
    @BillToCustomerID int = NULL,
    @BuyingGroupID int = NULL,
    @AlternateContactPersonID int = NULL,
    @CreditLimit decimal(18, 2) = NULL,
    @DeliveryRun nvarchar(5) = NULL,
    @RunPosition nvarchar(5) = NULL,
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
        THROW 50403, 'El usuario no puede modificar clientes.', 1;

    IF @VersionEsperada <= 0
        THROW 50401, 'La version esperada no es valida.', 1;

    IF (@DeliveryLatitude IS NULL AND @DeliveryLongitude IS NOT NULL)
       OR (@DeliveryLatitude IS NOT NULL AND @DeliveryLongitude IS NULL)
        THROW 50001, 'La latitud y longitud deben enviarse juntas.', 1;

    DECLARE @BillToActual int;
    SELECT @BillToActual = BillToCustomerID
    FROM Sales.Customers
    WHERE CustomerID = @CustomerID;

    SET @BillToCustomerID = COALESCE(@BillToCustomerID, @CustomerID);

    IF @BillToCustomerID <> COALESCE(@BillToActual, @BillToCustomerID)
       AND NOT EXISTS
       (
           SELECT 1 FROM Sales.Customers
           WHERE CustomerID = @BillToCustomerID AND Activo = 1
       )
        THROW 50402, 'El cliente de facturacion no esta activo.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE Sales.Customers
        SET CustomerName = @CustomerName,
            BillToCustomerID = @BillToCustomerID,
            CustomerCategoryID = @CustomerCategoryID,
            BuyingGroupID = @BuyingGroupID,
            DeliveryMethodID = @DeliveryMethodID,
            AccountOpenedDate = @AccountOpenedDate,
            IsStatementSent = @IsStatementSent,
            IsOnCreditHold = @IsOnCreditHold,
            PaymentDays = @PaymentDays,
            LastEditedBy = @Actor,
            LastEditedWhen = SYSUTCDATETIME(),
            VersionCatalogo = VersionCatalogo + 1
        WHERE CustomerID = @CustomerID
          AND VersionCatalogo = @VersionEsperada
          AND Activo = 1;

        IF @@ROWCOUNT = 0
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM Sales.Customers WHERE CustomerID = @CustomerID)
                THROW 50002, 'El cliente no existe.', 1;
            THROW 50401, 'El cliente fue modificado por otra sesion o esta inactivo.', 1;
        END;

        UPDATE Privado.Clientes
        SET PrimaryContactPersonID = @PrimaryContactPersonID,
            AlternateContactPersonID = @AlternateContactPersonID,
            DeliveryCityID = @DeliveryCityID,
            PostalCityID = @PostalCityID,
            CreditLimit = @CreditLimit,
            StandardDiscountPercentage = @StandardDiscountPercentage,
            PhoneNumber = @PhoneNumber,
            FaxNumber = @FaxNumber,
            DeliveryRun = @DeliveryRun,
            RunPosition = @RunPosition,
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
        WHERE CustomerID = @CustomerID;

        IF @@ROWCOUNT = 0
            THROW 50002, 'No existe el fragmento privado del cliente.', 1;

        COMMIT TRANSACTION;

        SELECT @CustomerID AS CustomerID, @VersionEsperada + 1 AS VersionCatalogo;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Clientes_Eliminar
    @CustomerID int,
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
        THROW 50403, 'El usuario no puede dar de baja clientes.', 1;

    BEGIN TRANSACTION;
    BEGIN TRY
        UPDATE Sales.Customers
        SET Activo = 0,
            VersionCatalogo = VersionCatalogo + 1,
            LastEditedBy = @Actor,
            LastEditedWhen = SYSUTCDATETIME()
        WHERE CustomerID = @CustomerID
          AND VersionCatalogo = @VersionEsperada
          AND Activo = 1;

        IF @@ROWCOUNT = 0
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM Sales.Customers WHERE CustomerID = @CustomerID)
                THROW 50002, 'El cliente no existe.', 1;
            THROW 50401, 'El cliente fue modificado por otra sesion o ya esta inactivo.', 1;
        END;

        COMMIT TRANSACTION;
        SELECT @CustomerID AS CustomerID, @VersionEsperada + 1 AS VersionCatalogo;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
