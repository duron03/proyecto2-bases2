USE [WideWorldImporters];
GO

-- Estas consultas solo muestran el fragmento publico del cliente.
CREATE OR ALTER PROCEDURE dbo.usp_Clientes_Listar
    @CustomerName nvarchar(100) = NULL,
    @CustomerCategoryID int = NULL,
    @DeliveryMethodID int = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        C.CustomerID,
        C.CustomerName,
        CC.CustomerCategoryID,
        CC.CustomerCategoryName,
        DM.DeliveryMethodID,
        DM.DeliveryMethodName,
        C.Activo,
        C.VersionCatalogo
    FROM dbo.src_Cliente AS C
    INNER JOIN dbo.src_CategoriaCliente AS CC
        ON C.CustomerCategoryID = CC.CustomerCategoryID
    INNER JOIN dbo.src_MetodoEntrega AS DM
        ON C.DeliveryMethodID = DM.DeliveryMethodID
    WHERE (@CustomerName IS NULL OR C.CustomerName LIKE N'%' + @CustomerName + N'%')
      AND (@CustomerCategoryID IS NULL OR C.CustomerCategoryID = @CustomerCategoryID)
      AND (@DeliveryMethodID IS NULL OR C.DeliveryMethodID = @DeliveryMethodID)
    ORDER BY C.CustomerName;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Clientes_ObtenerDetalle
    @CustomerID int
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        C.CustomerID,
        C.CustomerName,
        C.CustomerCategoryID,
        CC.CustomerCategoryName,
        C.BuyingGroupID,
        BG.BuyingGroupName,
        C.BillToCustomerID,
        BC.CustomerName AS BillToCustomerName,
        C.DeliveryMethodID,
        DM.DeliveryMethodName,
        CONVERT(char(10), C.AccountOpenedDate, 23) AS AccountOpenedDate,
        C.IsStatementSent,
        C.IsOnCreditHold,
        C.PaymentDays,
        C.LastEditedBy,
        C.LastEditedWhen,
        C.Activo,
        C.VersionCatalogo
    FROM dbo.src_Cliente AS C
    INNER JOIN dbo.src_CategoriaCliente AS CC
        ON C.CustomerCategoryID = CC.CustomerCategoryID
    LEFT JOIN dbo.src_GrupoCompra AS BG
        ON C.BuyingGroupID = BG.BuyingGroupID
    INNER JOIN dbo.src_Cliente AS BC
        ON C.BillToCustomerID = BC.CustomerID
    INNER JOIN dbo.src_MetodoEntrega AS DM
        ON C.DeliveryMethodID = DM.DeliveryMethodID
    WHERE C.CustomerID = @CustomerID;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Clientes_ObtenerCatalogos
AS
BEGIN
    SET NOCOUNT ON;

    SELECT CustomerCategoryID AS [Value], CustomerCategoryName AS [Label]
    FROM dbo.src_CategoriaCliente
    ORDER BY CustomerCategoryName;

    SELECT BuyingGroupID AS [Value], BuyingGroupName AS [Label]
    FROM dbo.src_GrupoCompra
    ORDER BY BuyingGroupName;

    SELECT PersonID AS [Value], FullName AS [Label]
    FROM dbo.src_Persona
    ORDER BY FullName;

    SELECT DeliveryMethodID AS [Value], DeliveryMethodName AS [Label]
    FROM dbo.src_MetodoEntrega
    ORDER BY DeliveryMethodName;

    SELECT CustomerID AS [Value], CustomerName AS [Label]
    FROM dbo.src_Cliente
    WHERE Activo = 1
    ORDER BY CustomerName;
END;
GO
