USE [WideWorldImporters];
GO

-- El catalogo es compartido, pero las existencias pertenecen a esta sucursal.
CREATE OR ALTER PROCEDURE dbo.usp_Inventarios_Listar
    @StockItemName nvarchar(100) = NULL,
    @StockGroupID int = NULL,
    @MinimumQuantityOnHand int = NULL,
    @MaximumQuantityOnHand int = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        SI.StockItemID,
        SI.StockItemName,
        SG.StockGroupID,
        SG.StockGroupName,
        COALESCE(H.QuantityOnHand, 0) AS QuantityOnHand,
        SI.Activo,
        SI.VersionCatalogo,
        COALESCE(H.VersionExistencias, 0) AS VersionExistencias
    FROM dbo.src_Producto AS SI
    LEFT JOIN dbo.src_Existencia AS H
        ON SI.StockItemID = H.StockItemID
    LEFT JOIN dbo.src_ProductoGrupo AS SISG
        ON SI.StockItemID = SISG.StockItemID
    LEFT JOIN dbo.src_GrupoProducto AS SG
        ON SISG.StockGroupID = SG.StockGroupID
    WHERE (@StockItemName IS NULL OR SI.StockItemName LIKE N'%' + @StockItemName + N'%')
      AND (@StockGroupID IS NULL OR SG.StockGroupID = @StockGroupID)
      AND (@MinimumQuantityOnHand IS NULL OR COALESCE(H.QuantityOnHand, 0) >= @MinimumQuantityOnHand)
      AND (@MaximumQuantityOnHand IS NULL OR COALESCE(H.QuantityOnHand, 0) <= @MaximumQuantityOnHand)
    ORDER BY SI.StockItemName, SG.StockGroupName;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Inventarios_ObtenerDetalle
    @StockItemID int
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        SI.StockItemID,
        SI.StockItemName,
        S.SupplierID,
        S.SupplierName,
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
        COALESCE(H.QuantityOnHand, 0) AS QuantityOnHand,
        COALESCE(H.BinLocation, N'') AS BinLocation,
        COALESCE(H.LastStocktakeQuantity, 0) AS LastStocktakeQuantity,
        COALESCE(H.LastCostPrice, 0) AS LastCostPrice,
        COALESCE(H.ReorderLevel, 0) AS ReorderLevel,
        COALESCE(H.TargetStockLevel, 0) AS TargetStockLevel,
        SI.LastEditedBy,
        CONCAT(SI.StockItemName, N' ', COALESCE(SI.MarketingComments, N'')) AS KeyWords,
        SI.Activo,
        SI.VersionCatalogo,
        COALESCE(H.VersionExistencias, 0) AS VersionExistencias
    FROM dbo.src_Producto AS SI
    INNER JOIN dbo.src_Proveedor AS S
        ON SI.SupplierID = S.SupplierID
    LEFT JOIN dbo.src_Color AS C
        ON SI.ColorID = C.ColorID
    INNER JOIN dbo.src_TipoEmpaque AS UPT
        ON SI.UnitPackageID = UPT.PackageTypeID
    INNER JOIN dbo.src_TipoEmpaque AS OPT
        ON SI.OuterPackageID = OPT.PackageTypeID
    LEFT JOIN dbo.src_Existencia AS H
        ON SI.StockItemID = H.StockItemID
    WHERE SI.StockItemID = @StockItemID;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Inventarios_ObtenerCatalogos
AS
BEGIN
    SET NOCOUNT ON;

    SELECT SupplierID AS [Value], SupplierName AS [Label]
    FROM dbo.src_Proveedor
    WHERE Activo = 1
    ORDER BY SupplierName;

    SELECT StockGroupID AS [Value], StockGroupName AS [Label]
    FROM dbo.src_GrupoProducto
    ORDER BY StockGroupName;

    SELECT ColorID AS [Value], ColorName AS [Label]
    FROM dbo.src_Color
    ORDER BY ColorName;

    SELECT PackageTypeID AS [Value], PackageTypeName AS [Label]
    FROM dbo.src_TipoEmpaque
    ORDER BY PackageTypeName;
END;
GO
