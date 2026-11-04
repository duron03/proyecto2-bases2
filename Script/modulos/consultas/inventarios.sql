USE [WideWorldImporters];
GO

-- Sinónimos utilizados por el módulo de inventarios.
IF OBJECT_ID('dbo.src_Producto', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_Producto FOR Warehouse.StockItems;');
GO

IF OBJECT_ID('dbo.src_Existencia', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_Existencia FOR Warehouse.StockItemHoldings;');
GO

IF OBJECT_ID('dbo.src_GrupoProducto', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_GrupoProducto FOR Warehouse.StockGroups;');
GO

IF OBJECT_ID('dbo.src_ProductoGrupo', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_ProductoGrupo FOR Warehouse.StockItemStockGroups;');
GO

IF OBJECT_ID('dbo.src_Color', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_Color FOR Warehouse.Colors;');
GO

IF OBJECT_ID('dbo.src_TipoEmpaque', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_TipoEmpaque FOR Warehouse.PackageTypes;');
GO

IF OBJECT_ID('dbo.src_Proveedor', 'SN') IS NULL
    EXEC('CREATE SYNONYM dbo.src_Proveedor FOR Purchasing.Suppliers;');
GO

-- Lista los productos. Los filtros son opcionales y se pueden combinar. Un producto puede aparecer más de una vez cuando pertenece a varios grupos.
CREATE OR ALTER PROCEDURE dbo.usp_Inventarios_Listar
    @StockItemName nvarchar(100) = NULL,
    @StockGroupID int = NULL,
    @MinimumQuantityOnHand int = NULL,
    @MaximumQuantityOnHand int = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT
            SI.StockItemID,
            SI.StockItemName,
            SG.StockGroupID,
            SG.StockGroupName,
            H.QuantityOnHand
        FROM dbo.src_Producto AS SI
        INNER JOIN dbo.src_Existencia AS H
            ON SI.StockItemID = H.StockItemID
        LEFT JOIN dbo.src_ProductoGrupo AS SISG
            ON SI.StockItemID = SISG.StockItemID
        LEFT JOIN dbo.src_GrupoProducto AS SG
            ON SISG.StockGroupID = SG.StockGroupID
        WHERE (@StockItemName IS NULL
            OR SI.StockItemName LIKE '%' + @StockItemName + '%')
            AND (@StockGroupID IS NULL OR SG.StockGroupID = @StockGroupID)
            AND (@MinimumQuantityOnHand IS NULL
            OR H.QuantityOnHand >= @MinimumQuantityOnHand)
            AND (@MaximumQuantityOnHand IS NULL
            OR H.QuantityOnHand <= @MaximumQuantityOnHand)
        ORDER BY SI.StockItemName ASC, SG.StockGroupName ASC;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

-- Muestra todos los datos de un producto.
CREATE OR ALTER PROCEDURE dbo.usp_Inventarios_ObtenerDetalle
    @StockItemID int
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT
            SI.StockItemID,
            SI.StockItemName,
            S.SupplierID,
            S.SupplierName,
            S.WebsiteURL AS SupplierWebsiteURL,
            SI.ColorID,
            C.ColorName,
            SI.UnitPackageID,
            UPT.PackageTypeName AS UnitPackageName,
            SI.OuterPackageID,
            OPT.PackageTypeName AS OuterPackageName,
            SI.LeadTimeDays,
            SI.QuantityPerOuter,
            SI.IsChillerStock,
            SI.Brand,
            SI.Size,
            SI.Barcode,
            SI.TaxRate,
            SI.UnitPrice,
            SI.RecommendedRetailPrice,
            SI.TypicalWeightPerUnit,
            SI.MarketingComments,
            H.QuantityOnHand,
            H.BinLocation,
            H.LastStocktakeQuantity,
            H.LastCostPrice,
            H.ReorderLevel,
            H.TargetStockLevel,
            SI.LastEditedBy,
            SI.SearchDetails AS KeyWords
        FROM dbo.src_Producto AS SI
        INNER JOIN dbo.src_Proveedor AS S
            ON SI.SupplierID = S.SupplierID
        LEFT JOIN dbo.src_Color AS C
            ON SI.ColorID = C.ColorID
        INNER JOIN dbo.src_TipoEmpaque AS UPT
            ON SI.UnitPackageID = UPT.PackageTypeID
        INNER JOIN dbo.src_TipoEmpaque AS OPT
            ON SI.OuterPackageID = OPT.PackageTypeID
        INNER JOIN dbo.src_Existencia AS H
            ON SI.StockItemID = H.StockItemID
        WHERE SI.StockItemID = @StockItemID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

-- Devuelve los catálogos pequeños utilizados en inventarios.
CREATE OR ALTER PROCEDURE dbo.usp_Inventarios_ObtenerCatalogos
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT
            SupplierID AS [Value],
            SupplierName AS [Label]
        FROM dbo.src_Proveedor
        ORDER BY SupplierName ASC;

        SELECT
            StockGroupID AS [Value],
            StockGroupName AS [Label]
        FROM dbo.src_GrupoProducto
        ORDER BY StockGroupName ASC;

        SELECT
            ColorID AS [Value],
            ColorName AS [Label]
        FROM dbo.src_Color
        ORDER BY ColorName ASC;

        SELECT
            PackageTypeID AS [Value],
            PackageTypeName AS [Label]
        FROM dbo.src_TipoEmpaque
        ORDER BY PackageTypeName ASC;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO
