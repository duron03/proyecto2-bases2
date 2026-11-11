USE [WideWorldImporters];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- Se instala en cada sucursal. VersionEsperada = 0 crea la primera existencia.
CREATE OR ALTER PROCEDURE dbo.usp_Inventarios_GuardarExistencias
    @StockItemID int,
    @QuantityOnHand int,
    @BinLocation nvarchar(20),
    @LastStocktakeQuantity int,
    @LastCostPrice decimal(18, 2),
    @ReorderLevel int,
    @TargetStockLevel int,
    @VersionEsperada int
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @QuantityOnHand < 0 OR @LastStocktakeQuantity < 0 OR @LastCostPrice < 0
       OR @ReorderLevel < 0 OR @TargetStockLevel < 0 OR @VersionEsperada < 0
        THROW 50401, 'Los valores de existencias no son validos.', 1;

    DECLARE @Actor int;
    DECLARE @SucursalUsuario int;
    DECLARE @SucursalNodo int;

    SELECT @Actor = PersonID, @SucursalUsuario = SucursalID
    FROM Seguridad.IdentidadesLocales
    WHERE SqlLogin = ORIGINAL_LOGIN()
      AND active = 1;

    SELECT @SucursalNodo = SucursalID
    FROM Control.Nodo
    WHERE Id = 1;

    IF @Actor IS NULL OR @SucursalUsuario <> @SucursalNodo
        THROW 50403, 'El usuario no puede modificar existencias en esta sucursal.', 1;

    IF NOT EXISTS (SELECT 1 FROM Warehouse.StockItems WHERE StockItemID = @StockItemID)
        THROW 50404, 'El producto aun no ha llegado al catalogo local.', 1;

    IF NOT EXISTS
    (
        SELECT 1 FROM Warehouse.StockItems
        WHERE StockItemID = @StockItemID AND Activo = 1
    )
        THROW 50402, 'El producto esta inactivo.', 1;

    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @VersionActual int;

        SELECT @VersionActual = VersionExistencias
        FROM Warehouse.StockItemHoldings WITH (UPDLOCK, HOLDLOCK)
        WHERE StockItemID = @StockItemID;

        IF @VersionActual IS NULL
        BEGIN
            IF @VersionEsperada <> 0
                THROW 50401, 'Las existencias fueron modificadas por otra sesion.', 1;

            INSERT INTO Warehouse.StockItemHoldings
            (
                StockItemID, QuantityOnHand, BinLocation, LastStocktakeQuantity,
                LastCostPrice, ReorderLevel, TargetStockLevel,
                LastEditedBy, LastEditedWhen, VersionExistencias
            )
            VALUES
            (
                @StockItemID, @QuantityOnHand, @BinLocation, @LastStocktakeQuantity,
                @LastCostPrice, @ReorderLevel, @TargetStockLevel,
                @Actor, SYSUTCDATETIME(), 1
            );

            SET @VersionActual = 1;
        END
        ELSE
        BEGIN
            UPDATE Warehouse.StockItemHoldings
            SET QuantityOnHand = @QuantityOnHand,
                BinLocation = @BinLocation,
                LastStocktakeQuantity = @LastStocktakeQuantity,
                LastCostPrice = @LastCostPrice,
                ReorderLevel = @ReorderLevel,
                TargetStockLevel = @TargetStockLevel,
                LastEditedBy = @Actor,
                LastEditedWhen = SYSUTCDATETIME(),
                VersionExistencias = VersionExistencias + 1
            WHERE StockItemID = @StockItemID
              AND VersionExistencias = @VersionEsperada;

            IF @@ROWCOUNT = 0
                THROW 50401, 'Las existencias fueron modificadas por otra sesion.', 1;

            SET @VersionActual = @VersionEsperada + 1;
        END;

        COMMIT TRANSACTION;
        SELECT @StockItemID AS StockItemID, @VersionActual AS VersionExistencias;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
