USE [WideWorldImporters];
GO

-- Sinónimos utilizados por el CRUD de clientes.
IF OBJECT_ID('dbo.src_Cliente', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_Cliente FOR Sales.Customers;');
GO

-- Crea un cliente. Si BillToCustomerID es NULL, el cliente se factura así mismo.
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
    @LastEditedBy int,
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

    BEGIN TRY
        BEGIN TRANSACTION;

        IF (@DeliveryLatitude IS NULL AND @DeliveryLongitude IS NOT NULL)
            OR (@DeliveryLatitude IS NOT NULL AND @DeliveryLongitude IS NULL)
            THROW 50001, 'Debe enviar la latitud y la longitud juntas.', 1;

        DECLARE @NewCustomerID int = NEXT VALUE FOR Sequences.CustomerID;
        DECLARE @DeliveryLocation geography = NULL;

        IF @DeliveryLatitude IS NOT NULL AND @DeliveryLongitude IS NOT NULL
            SET @DeliveryLocation = geography::Point(
                @DeliveryLatitude,
                @DeliveryLongitude,
                4326
            );

        INSERT INTO dbo.src_Cliente
        (
            CustomerID,
            CustomerName,
            BillToCustomerID,
            CustomerCategoryID,
            BuyingGroupID,
            PrimaryContactPersonID,
            AlternateContactPersonID,
            DeliveryMethodID,
            DeliveryCityID,
            PostalCityID,
            CreditLimit,
            AccountOpenedDate,
            StandardDiscountPercentage,
            IsStatementSent,
            IsOnCreditHold,
            PaymentDays,
            PhoneNumber,
            FaxNumber,
            DeliveryRun,
            RunPosition,
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
            @NewCustomerID,
            @CustomerName,
            ISNULL(@BillToCustomerID, @NewCustomerID),
            @CustomerCategoryID,
            @BuyingGroupID,
            @PrimaryContactPersonID,
            @AlternateContactPersonID,
            @DeliveryMethodID,
            @DeliveryCityID,
            @PostalCityID,
            @CreditLimit,
            @AccountOpenedDate,
            @StandardDiscountPercentage,
            @IsStatementSent,
            @IsOnCreditHold,
            @PaymentDays,
            @PhoneNumber,
            @FaxNumber,
            @DeliveryRun,
            @RunPosition,
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

        SELECT @NewCustomerID AS CustomerID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

-- Actualiza todos los datos editables de un cliente.
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
    @LastEditedBy int,
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

    BEGIN TRY
        BEGIN TRANSACTION;

        IF (@DeliveryLatitude IS NULL AND @DeliveryLongitude IS NOT NULL)
            OR (@DeliveryLatitude IS NOT NULL AND @DeliveryLongitude IS NULL)
            THROW 50001, 'Debe enviar la latitud y la longitud juntas.', 1;

        DECLARE @DeliveryLocation geography = NULL;

        IF @DeliveryLatitude IS NOT NULL AND @DeliveryLongitude IS NOT NULL
            SET @DeliveryLocation = geography::Point(
                @DeliveryLatitude,
                @DeliveryLongitude,
                4326
            );

        UPDATE dbo.src_Cliente
        SET CustomerName = @CustomerName,
            BillToCustomerID = ISNULL(@BillToCustomerID, @CustomerID),
            CustomerCategoryID = @CustomerCategoryID,
            BuyingGroupID = @BuyingGroupID,
            PrimaryContactPersonID = @PrimaryContactPersonID,
            AlternateContactPersonID = @AlternateContactPersonID,
            DeliveryMethodID = @DeliveryMethodID,
            DeliveryCityID = @DeliveryCityID,
            PostalCityID = @PostalCityID,
            CreditLimit = @CreditLimit,
            AccountOpenedDate = @AccountOpenedDate,
            StandardDiscountPercentage = @StandardDiscountPercentage,
            IsStatementSent = @IsStatementSent,
            IsOnCreditHold = @IsOnCreditHold,
            PaymentDays = @PaymentDays,
            PhoneNumber = @PhoneNumber,
            FaxNumber = @FaxNumber,
            DeliveryRun = @DeliveryRun,
            RunPosition = @RunPosition,
            WebsiteURL = @WebsiteURL,
            DeliveryAddressLine1 = @DeliveryAddressLine1,
            DeliveryAddressLine2 = @DeliveryAddressLine2,
            DeliveryPostalCode = @DeliveryPostalCode,
            DeliveryLocation = @DeliveryLocation,
            PostalAddressLine1 = @PostalAddressLine1,
            PostalAddressLine2 = @PostalAddressLine2,
            PostalPostalCode = @PostalPostalCode,
            LastEditedBy = @LastEditedBy
        WHERE CustomerID = @CustomerID;

        IF @@ROWCOUNT = 0
            THROW 50002, 'El cliente no existe.', 1;

        SELECT @CustomerID AS CustomerID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

-- Elimina un cliente. No se elimina si otra tabla todavía lo usa.
CREATE OR ALTER PROCEDURE dbo.usp_Clientes_Eliminar
    @CustomerID int
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM dbo.src_Cliente
        WHERE CustomerID = @CustomerID;

        IF @@ROWCOUNT = 0
            THROW 50002, 'El cliente no existe.', 1;

        SELECT @CustomerID AS CustomerID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO
