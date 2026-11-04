USE [WideWorldImporters];
GO

-- Sinónimos utilizados por el CRUD de inventarios.
IF OBJECT_ID('dbo.src_Producto', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_Producto FOR Warehouse.StockItems;');
GO

IF OBJECT_ID('dbo.src_Existencia', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_Existencia FOR Warehouse.StockItemHoldings;');
GO

IF OBJECT_ID('dbo.src_ProductoGrupo', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_ProductoGrupo FOR Warehouse.StockItemStockGroups;');
GO

-- Crea el producto y su registro de existencias en una sola transacción.
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
    @QuantityOnHand int,
    @BinLocation nvarchar(20),
    @LastStocktakeQuantity int,
    @LastCostPrice decimal(18, 2),
    @ReorderLevel int,
    @TargetStockLevel int,
    @LastEditedBy int,
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

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @NewStockItemID int = NEXT VALUE FOR Sequences.StockItemID;

        INSERT INTO dbo.src_Producto
        (
            StockItemID,
            StockItemName,
            SupplierID,
            ColorID,
            UnitPackageID,
            OuterPackageID,
            Brand,
            Size,
            LeadTimeDays,
            QuantityPerOuter,
            IsChillerStock,
            Barcode,
            TaxRate,
            UnitPrice,
            RecommendedRetailPrice,
            TypicalWeightPerUnit,
            MarketingComments,
            InternalComments,
            Photo,
            CustomFields,
            LastEditedBy
        )
        VALUES
        (
            @NewStockItemID,
            @StockItemName,
            @SupplierID,
            @ColorID,
            @UnitPackageID,
            @OuterPackageID,
            @Brand,
            @Size,
            @LeadTimeDays,
            @QuantityPerOuter,
            @IsChillerStock,
            @Barcode,
            @TaxRate,
            @UnitPrice,
            @RecommendedRetailPrice,
            @TypicalWeightPerUnit,
            @MarketingComments,
            @InternalComments,
            @Photo,
            @CustomFields,
            @LastEditedBy
        );

        INSERT INTO dbo.src_Existencia
        (
            StockItemID,
            QuantityOnHand,
            BinLocation,
            LastStocktakeQuantity,
            LastCostPrice,
            ReorderLevel,
            TargetStockLevel,
            LastEditedBy
        )
        VALUES
        (
            @NewStockItemID,
            @QuantityOnHand,
            @BinLocation,
            @LastStocktakeQuantity,
            @LastCostPrice,
            @ReorderLevel,
            @TargetStockLevel,
            @LastEditedBy
        );

        IF @StockGroupID IS NOT NULL
        BEGIN
            INSERT INTO dbo.src_ProductoGrupo
            (
                StockItemID,
                StockGroupID,
                LastEditedBy
            )
            VALUES
            (
                @NewStockItemID,
                @StockGroupID,
                @LastEditedBy
            );
        END;

        SELECT @NewStockItemID AS StockItemID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

-- Actualiza el producto y sus existencias en una sola transacción.
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
    @QuantityOnHand int,
    @BinLocation nvarchar(20),
    @LastStocktakeQuantity int,
    @LastCostPrice decimal(18, 2),
    @ReorderLevel int,
    @TargetStockLevel int,
    @LastEditedBy int,
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

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE dbo.src_Producto
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
            InternalComments = ISNULL(@InternalComments, InternalComments),
            Photo = ISNULL(@Photo, Photo),
            CustomFields = ISNULL(@CustomFields, CustomFields),
            LastEditedBy = @LastEditedBy
        WHERE StockItemID = @StockItemID;

        IF @@ROWCOUNT = 0
            THROW 50201, 'El producto no existe.', 1;

        UPDATE dbo.src_Existencia
        SET QuantityOnHand = @QuantityOnHand,
            BinLocation = @BinLocation,
            LastStocktakeQuantity = @LastStocktakeQuantity,
            LastCostPrice = @LastCostPrice,
            ReorderLevel = @ReorderLevel,
            TargetStockLevel = @TargetStockLevel,
            LastEditedBy = @LastEditedBy,
            LastEditedWhen = SYSDATETIME()
        WHERE StockItemID = @StockItemID;

        IF @@ROWCOUNT = 0
            THROW 50202, 'El producto no tiene un registro de existencias.', 1;

        SELECT @StockItemID AS StockItemID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

-- Agrega un producto a un grupo. No duplica la relación si ya existe.
CREATE OR ALTER PROCEDURE dbo.usp_Inventarios_AsignarGrupo
    @StockItemID int,
    @StockGroupID int,
    @LastEditedBy int
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.src_ProductoGrupo
            WHERE StockItemID = @StockItemID
                AND StockGroupID = @StockGroupID
        )
        BEGIN
            INSERT INTO dbo.src_ProductoGrupo
            (
                StockItemID,
                StockGroupID,
                LastEditedBy
            )
            VALUES
            (
                @StockItemID,
                @StockGroupID,
                @LastEditedBy
            );
        END;

        SELECT
            @StockItemID AS StockItemID,
            @StockGroupID AS StockGroupID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

-- Quita un producto de un grupo.
CREATE OR ALTER PROCEDURE dbo.usp_Inventarios_QuitarGrupo
    @StockItemID int,
    @StockGroupID int
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM dbo.src_ProductoGrupo
        WHERE StockItemID = @StockItemID
            AND StockGroupID = @StockGroupID;

        IF @@ROWCOUNT = 0
            THROW 50203, 'El producto no pertenece al grupo indicado.', 1;

        SELECT
            @StockItemID AS StockItemID,
            @StockGroupID AS StockGroupID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

-- Elimina primero las relaciones propias del inventario y después el producto.
CREATE OR ALTER PROCEDURE dbo.usp_Inventarios_Eliminar
    @StockItemID int
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM dbo.src_ProductoGrupo
        WHERE StockItemID = @StockItemID;

        DELETE FROM dbo.src_Existencia
        WHERE StockItemID = @StockItemID;

        DELETE FROM dbo.src_Producto
        WHERE StockItemID = @StockItemID;

        IF @@ROWCOUNT = 0
            THROW 50201, 'El producto no existe.', 1;

        SELECT @StockItemID AS StockItemID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO
