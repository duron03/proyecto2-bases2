USE [WideWorldImporters];
GO

-- Estas consultas solo muestran el fragmento publico del proveedor.
CREATE OR ALTER PROCEDURE dbo.usp_Proveedores_Listar
    @SupplierName nvarchar(100) = NULL,
    @SupplierCategoryID int = NULL,
    @DeliveryMethodID int = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        S.SupplierID,
        S.SupplierName,
        SC.SupplierCategoryID,
        SC.SupplierCategoryName,
        DM.DeliveryMethodID,
        DM.DeliveryMethodName,
        S.Activo,
        S.VersionCatalogo
    FROM dbo.src_Proveedor AS S
    INNER JOIN dbo.src_CategoriaProveedor AS SC
        ON S.SupplierCategoryID = SC.SupplierCategoryID
    LEFT JOIN dbo.src_MetodoEntrega AS DM
        ON S.DeliveryMethodID = DM.DeliveryMethodID
    WHERE (@SupplierName IS NULL OR S.SupplierName LIKE N'%' + @SupplierName + N'%')
      AND (@SupplierCategoryID IS NULL OR S.SupplierCategoryID = @SupplierCategoryID)
      AND (@DeliveryMethodID IS NULL OR S.DeliveryMethodID = @DeliveryMethodID)
    ORDER BY S.SupplierName;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Proveedores_ObtenerDetalle
    @SupplierID int
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        S.SupplierID,
        S.SupplierName,
        S.SupplierCategoryID,
        SC.SupplierCategoryName,
        S.DeliveryMethodID,
        DM.DeliveryMethodName,
        S.PaymentDays,
        S.LastEditedBy,
        S.LastEditedWhen,
        S.Activo,
        S.VersionCatalogo
    FROM dbo.src_Proveedor AS S
    INNER JOIN dbo.src_CategoriaProveedor AS SC
        ON S.SupplierCategoryID = SC.SupplierCategoryID
    LEFT JOIN dbo.src_MetodoEntrega AS DM
        ON S.DeliveryMethodID = DM.DeliveryMethodID
    WHERE S.SupplierID = @SupplierID;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Proveedores_ObtenerCatalogos
AS
BEGIN
    SET NOCOUNT ON;

    SELECT SupplierCategoryID AS [Value], SupplierCategoryName AS [Label]
    FROM dbo.src_CategoriaProveedor
    ORDER BY SupplierCategoryName;

    SELECT PersonID AS [Value], FullName AS [Label]
    FROM dbo.src_Persona
    ORDER BY FullName;

    SELECT DeliveryMethodID AS [Value], DeliveryMethodName AS [Label]
    FROM dbo.src_MetodoEntrega
    ORDER BY DeliveryMethodName;
END;
GO
