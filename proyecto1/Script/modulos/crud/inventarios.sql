USE [WideWorldImporters];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- Este archivo modifica solo el catalogo compartido y se instala en Corporativo.
CREATE OR ALTER PROCEDURE dbo.usp_Inventarios_Crear
    @StockItemName nvarchar(100),
    @SupplierID int,
    @UnitPackageID int,
    @OuterPackageID int,
    @LeadTimeDays int,
    @QuantityPerOuter int,
    @IsChillerStock bit,
    @TaxRate decimal(18, 3),
    @UnitPrice decimal(18, 2),
    @TypicalWeightPerUnit decimal(18, 3),
    @LastEditedBy int = NULL,
    @ColorID int = NULL,
    @Brand nvarchar(50) = NULL,
    @Size nvarchar(20) = NULL,
    @Barcode nvarchar(50) = NULL,
    @RecommendedRetailPrice decimal(18, 2) = NULL,
    @MarketingComments nvarchar(max) = NULL,
    @InternalComments nvarchar(max) = NULL,
    @Photo varbinary(max) = NULL,
    @CustomFields nvarchar(max) = NULL,
    @StockGroupID int = NULL
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
        THROW 50403, 'El usuario no puede modificar productos.', 1;

    IF NOT EXISTS
    (
        SELECT 1 FROM Purchasing.Suppliers
        WHERE SupplierID = @SupplierID AND Activo = 1
    )
        THROW 50402, 'El proveedor seleccionado no esta activo.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @NewStockItemID int = NEXT VALUE FOR Sequences.StockItemID;

        INSERT INTO Warehouse.StockItems
        (
            StockItemID, StockItemName, SupplierID, ColorID,
            UnitPackageID, OuterPackageID, Brand, Size,
            LeadTimeDays, QuantityPerOuter, IsChillerStock, Barcode,
            TaxRate, UnitPrice, RecommendedRetailPrice, TypicalWeightPerUnit,
            MarketingComments, InternalComments, Photo, CustomFields,
            LastEditedBy, LastEditedWhen, Activo, VersionCatalogo
        )
        VALUES
        (
            @NewStockItemID, @StockItemName, @SupplierID, @ColorID,
            @UnitPackageID, @OuterPackageID, @Brand, @Size,
            @LeadTimeDays, @QuantityPerOuter, @IsChillerStock, @Barcode,
            @TaxRate, @UnitPrice, @RecommendedRetailPrice, @TypicalWeightPerUnit,
            @MarketingComments, @InternalComments, @Photo, @CustomFields,
            @Actor, SYSUTCDATETIME(), 1, 1
        );

        IF @StockGroupID IS NOT NULL
        BEGIN
            INSERT INTO Warehouse.StockItemStockGroups
            (
                StockItemStockGroupID, StockItemID, StockGroupID,
                LastEditedBy, LastEditedWhen
            )
            VALUES
            (
                NEXT VALUE FOR Sequences.StockItemStockGroupID,
                @NewStockItemID, @StockGroupID, @Actor, SYSUTCDATETIME()
            );
        END;

        COMMIT TRANSACTION;
        SELECT @NewStockItemID AS StockItemID, 1 AS VersionCatalogo;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Inventarios_Actualizar
    @StockItemID int,
    @StockItemName nvarchar(100),
    @SupplierID int,
    @UnitPackageID int,
    @OuterPackageID int,
    @LeadTimeDays int,
    @QuantityPerOuter int,
    @IsChillerStock bit,
    @TaxRate decimal(18, 3),
    @UnitPrice decimal(18, 2),
    @TypicalWeightPerUnit decimal(18, 3),
    @VersionEsperada int,
    @LastEditedBy int = NULL,
    @ColorID int = NULL,
    @Brand nvarchar(50) = NULL,
    @Size nvarchar(20) = NULL,
    @Barcode nvarchar(50) = NULL,
    @RecommendedRetailPrice decimal(18, 2) = NULL,
    @MarketingComments nvarchar(max) = NULL,
    @InternalComments nvarchar(max) = NULL,
    @Photo varbinary(max) = NULL,
    @CustomFields nvarchar(max) = NULL
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
        THROW 50403, 'El usuario no puede modificar productos.', 1;

    IF @VersionEsperada <= 0
        THROW 50401, 'La version esperada no es valida.', 1;

    DECLARE @SupplierActual int;
    SELECT @SupplierActual = SupplierID
    FROM Warehouse.StockItems
    WHERE StockItemID = @StockItemID;

    IF @SupplierID <> COALESCE(@SupplierActual, @SupplierID)
       AND NOT EXISTS
       (
           SELECT 1 FROM Purchasing.Suppliers
           WHERE SupplierID = @SupplierID AND Activo = 1
       )
        THROW 50402, 'El proveedor seleccionado no esta activo.', 1;

    BEGIN TRANSACTION;
    BEGIN TRY
        UPDATE Warehouse.StockItems
        SET StockItemName = @StockItemName,
            SupplierID = @SupplierID,
            ColorID = @ColorID,
            UnitPackageID = @UnitPackageID,
            OuterPackageID = @OuterPackageID,
            Brand = @Brand,
            Size = @Size,
            LeadTimeDays = @LeadTimeDays,
            QuantityPerOuter = @QuantityPerOuter,
            IsChillerStock = @IsChillerStock,
            Barcode = @Barcode,
            TaxRate = @TaxRate,
            UnitPrice = @UnitPrice,
            RecommendedRetailPrice = @RecommendedRetailPrice,
            TypicalWeightPerUnit = @TypicalWeightPerUnit,
            MarketingComments = @MarketingComments,
            InternalComments = @InternalComments,
            Photo = @Photo,
            CustomFields = @CustomFields,
            LastEditedBy = @Actor,
            LastEditedWhen = SYSUTCDATETIME(),
            VersionCatalogo = VersionCatalogo + 1
        WHERE StockItemID = @StockItemID
          AND VersionCatalogo = @VersionEsperada
          AND Activo = 1;

        IF @@ROWCOUNT = 0
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM Warehouse.StockItems WHERE StockItemID = @StockItemID)
                THROW 50201, 'El producto no existe.', 1;
            THROW 50401, 'El producto fue modificado por otra sesion o esta inactivo.', 1;
        END;

        COMMIT TRANSACTION;
        SELECT @StockItemID AS StockItemID, @VersionEsperada + 1 AS VersionCatalogo;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Inventarios_Eliminar
    @StockItemID int,
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
        THROW 50403, 'El usuario no puede dar de baja productos.', 1;

    BEGIN TRANSACTION;
    BEGIN TRY
        UPDATE Warehouse.StockItems
        SET Activo = 0,
            VersionCatalogo = VersionCatalogo + 1,
            LastEditedBy = @Actor,
            LastEditedWhen = SYSUTCDATETIME()
        WHERE StockItemID = @StockItemID
          AND VersionCatalogo = @VersionEsperada
          AND Activo = 1;

        IF @@ROWCOUNT = 0
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM Warehouse.StockItems WHERE StockItemID = @StockItemID)
                THROW 50201, 'El producto no existe.', 1;
            THROW 50401, 'El producto fue modificado por otra sesion o ya esta inactivo.', 1;
        END;

        COMMIT TRANSACTION;
        SELECT @StockItemID AS StockItemID, @VersionEsperada + 1 AS VersionCatalogo;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
