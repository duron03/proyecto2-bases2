:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;

USE [WideWorldImporters];
GO

IF N'$(NodeCode)' NOT IN (N'CORP', N'SJ', N'LI')
    THROW 51300, N'NodeCode debe ser CORP, SJ o LI.', 1;

IF NOT EXISTS
(
    SELECT 1
    FROM Control.Nodo
    WHERE Id = 1
      AND Codigo = N'$(NodeCode)'
      AND
      (
          (N'$(NodeCode)' = N'CORP' AND SucursalID IS NULL)
          OR (N'$(NodeCode)' = N'SJ' AND SucursalID = 1)
          OR (N'$(NodeCode)' = N'LI' AND SucursalID = 2)
      )
)
    THROW 51301, N'La identidad de Control.Nodo no coincide.', 1;

IF EXISTS
(
    SELECT 1
    FROM sys.tables
    WHERE temporal_type <> 0
      AND SCHEMA_NAME(schema_id) IN
          (N'Application', N'Sales', N'Purchasing', N'Warehouse', N'Privado', N'sj', N'limon')
)
    THROW 51302, N'El esquema activo contiene una tabla temporal no autorizada.', 1;

IF EXISTS
(
    SELECT 1
    FROM sys.computed_columns AS columnObject
    INNER JOIN sys.tables AS tableObject
        ON tableObject.object_id = columnObject.object_id
    WHERE SCHEMA_NAME(tableObject.schema_id) IN
          (N'Application', N'Sales', N'Purchasing', N'Warehouse', N'Privado', N'sj', N'limon')
)
    THROW 51303, N'El esquema activo contiene una columna calculada no autorizada.', 1;

IF EXISTS
(
    SELECT 1
    FROM sys.foreign_keys
    WHERE is_disabled = 1
       OR (is_not_trusted = 1 AND is_not_for_replication = 0)
)
BEGIN
    SELECT
        SCHEMA_NAME(tableObject.schema_id) AS SchemaName,
        tableObject.name AS TableName,
        foreignKeyObject.name AS ForeignKeyName,
        foreignKeyObject.is_disabled AS IsDisabled,
        foreignKeyObject.is_not_trusted AS IsNotTrusted,
        foreignKeyObject.is_not_for_replication AS IsNotForReplication
    FROM sys.foreign_keys AS foreignKeyObject
    INNER JOIN sys.tables AS tableObject
        ON tableObject.object_id = foreignKeyObject.parent_object_id
    WHERE foreignKeyObject.is_disabled = 1
       OR (foreignKeyObject.is_not_trusted = 1 AND foreignKeyObject.is_not_for_replication = 0)
    ORDER BY SchemaName, TableName, ForeignKeyName;

    THROW 51304, N'Existe una clave foranea deshabilitada o no confiable.', 1;
END;

IF (SELECT value_in_use FROM sys.configurations WHERE name = N'max text repl size (B)') <> -1
    THROW 51305, N'max text repl size debe estar configurado en -1.', 1;

IF N'$(NodeCode)' = N'CORP'
BEGIN
    IF DB_ID(N'WWI_Origen') IS NULL
       OR DATABASEPROPERTYEX(N'WWI_Origen', N'Updateability') <> N'READ_ONLY'
        THROW 51306, N'WWI_Origen no existe o no esta en READ_ONLY.', 1;

    IF (SELECT COUNT_BIG(*) FROM Application.People) <> 1114
       OR (SELECT COUNT_BIG(*) FROM Sales.Customers) <> 663
       OR (SELECT COUNT_BIG(*) FROM Privado.Clientes) <> 663
       OR (SELECT COUNT_BIG(*) FROM Purchasing.Suppliers) <> 13
       OR (SELECT COUNT_BIG(*) FROM Privado.Proveedores) <> 13
       OR (SELECT COUNT_BIG(*) FROM Warehouse.StockItems) <> 228
       OR (SELECT COUNT_BIG(*) FROM Warehouse.StockItemStockGroups) <> 443
        THROW 51307, N'Los conteos de catalogo o privados no coinciden con la matriz T02.', 1;

    IF NOT EXISTS (SELECT 1 FROM Application.People WHERE PersonID = 3262 AND FullName = N'Administrador San Jose')
       OR NOT EXISTS (SELECT 1 FROM Application.People WHERE PersonID = 3263 AND FullName = N'Administrador Limon')
       OR NOT EXISTS (SELECT 1 FROM Application.People WHERE PersonID = 3264 AND FullName = N'Usuario Corporativo')
        THROW 51308, N'Las personas reservadas para demostracion no coinciden.', 1;

    IF EXISTS
    (
        SELECT 1
        FROM Application.People
        WHERE PersonID <= 3261
          AND FullName <> CONVERT(nvarchar(50), CONCAT(N'Persona ', PersonID))
    )
        THROW 51309, N'Una persona importada conserva un nombre real en el fragmento publico.', 1;

    IF (SELECT COUNT_BIG(*) FROM Preparacion.AsignacionPedidos) <> 73595
       OR (SELECT COUNT_BIG(*) FROM Preparacion.AsignacionFacturas) <> 70511
       OR (SELECT COUNT_BIG(*) FROM Preparacion.AsignacionCompras) <> 2074
       OR (SELECT COUNT_BIG(*) FROM Preparacion.AsignacionPedidos WHERE SucursalID = 1) <> 36797
       OR (SELECT COUNT_BIG(*) FROM Preparacion.AsignacionPedidos WHERE SucursalID = 2) <> 36798
       OR (SELECT COUNT_BIG(*) FROM Preparacion.AsignacionFacturas WHERE SucursalID = 1) <> 35254
       OR (SELECT COUNT_BIG(*) FROM Preparacion.AsignacionFacturas WHERE SucursalID = 2) <> 35257
       OR (SELECT COUNT_BIG(*) FROM Preparacion.AsignacionCompras WHERE SucursalID = 1) <> 1037
       OR (SELECT COUNT_BIG(*) FROM Preparacion.AsignacionCompras WHERE SucursalID = 2) <> 1037
        THROW 51310, N'Los mapas de fragmentacion no coinciden con la matriz T02.', 1;

    IF EXISTS
    (
        SELECT 1
        FROM
        (
            SELECT N'sj' AS SchemaName, N'Orders' AS TableName
            UNION ALL SELECT N'sj', N'Invoices'
            UNION ALL SELECT N'sj', N'InvoiceLines'
            UNION ALL SELECT N'sj', N'CustomerTransactions'
            UNION ALL SELECT N'sj', N'PurchaseOrders'
            UNION ALL SELECT N'sj', N'PurchaseOrderLines'
            UNION ALL SELECT N'sj', N'SupplierTransactions'
            UNION ALL SELECT N'sj', N'StockItemHoldings'
            UNION ALL SELECT N'sj', N'LatidoSucursal'
            UNION ALL SELECT N'limon', N'Orders'
            UNION ALL SELECT N'limon', N'Invoices'
            UNION ALL SELECT N'limon', N'InvoiceLines'
            UNION ALL SELECT N'limon', N'CustomerTransactions'
            UNION ALL SELECT N'limon', N'PurchaseOrders'
            UNION ALL SELECT N'limon', N'PurchaseOrderLines'
            UNION ALL SELECT N'limon', N'SupplierTransactions'
            UNION ALL SELECT N'limon', N'StockItemHoldings'
            UNION ALL SELECT N'limon', N'LatidoSucursal'
        ) AS expectedObject
        CROSS APPLY
        (
            SELECT SUM(partitionObject.rows) AS TotalRows
            FROM sys.tables AS tableObject
            INNER JOIN sys.schemas AS schemaObject
                ON schemaObject.schema_id = tableObject.schema_id
            INNER JOIN sys.partitions AS partitionObject
                ON partitionObject.object_id = tableObject.object_id
               AND partitionObject.index_id IN (0, 1)
            WHERE schemaObject.name = expectedObject.SchemaName
              AND tableObject.name = expectedObject.TableName
        ) AS measuredObject
        WHERE ISNULL(measuredObject.TotalRows, -1) <> 0
    )
        THROW 51311, N'Falta un receptor corporativo o ya contiene filas.', 1;

    IF (SELECT COUNT(*) FROM sys.synonyms WHERE name LIKE N'src[_]%') <> 12
        THROW 51312, N'Los sinonimos publicos de Corporativo estan incompletos.', 1;

    IF (SELECT COUNT(*) FROM sys.sequences WHERE SCHEMA_NAME(schema_id) = N'Sequences') <> 5
        THROW 51313, N'Las cinco secuencias centrales no estan completas.', 1;

    IF NOT EXISTS
    (
        SELECT 1
        FROM Control.EstadoInicializacion
        GROUP BY DatosValidados
        HAVING DatosValidados = 0 AND COUNT(*) = 2
    )
        THROW 51314, N'EstadoInicializacion no tiene sus dos semillas pendientes.', 1;
END;

IF N'$(NodeCode)' IN (N'SJ', N'LI')
BEGIN
    IF SCHEMA_ID(N'Privado') IS NOT NULL
        THROW 51320, N'Una sucursal contiene el esquema Privado.', 1;

    IF EXISTS (SELECT 1 FROM Application.People)
       OR EXISTS (SELECT 1 FROM Sales.Customers)
       OR EXISTS (SELECT 1 FROM Purchasing.Suppliers)
       OR EXISTS (SELECT 1 FROM Warehouse.StockItems)
        THROW 51321, N'El catalogo de la sucursal debe estar vacio antes del snapshot.', 1;

    IF EXISTS (SELECT 1 FROM Sales.Orders)
       OR EXISTS (SELECT 1 FROM Sales.Invoices)
       OR EXISTS (SELECT 1 FROM Sales.InvoiceLines)
       OR EXISTS (SELECT 1 FROM Sales.CustomerTransactions)
       OR EXISTS (SELECT 1 FROM Purchasing.PurchaseOrders)
       OR EXISTS (SELECT 1 FROM Purchasing.PurchaseOrderLines)
       OR EXISTS (SELECT 1 FROM Purchasing.SupplierTransactions)
       OR EXISTS (SELECT 1 FROM Warehouse.StockItemHoldings)
        THROW 51322, N'Los hechos locales deben estar vacios al cerrar T03.', 1;

    IF (SELECT COUNT(*) FROM sys.synonyms WHERE name LIKE N'src[_]%') <> 19
        THROW 51323, N'Los sinonimos publicos y locales de la sucursal estan incompletos.', 1;

    IF NOT EXISTS (SELECT 1 FROM Control.EstadoCatalogo WHERE Id = 1 AND DatosValidados = 0 AND ValidadoUtc IS NULL)
        THROW 51324, N'EstadoCatalogo no esta pendiente antes del snapshot.', 1;

    IF (SELECT COUNT(*) FROM sys.sequences WHERE name IN (N'InvoiceID', N'InvoiceLineID')) <> 2
        THROW 51325, N'Faltan secuencias de factura en la sucursal.', 1;

    IF N'$(NodeCode)' = N'SJ'
       AND EXISTS
       (
           SELECT 1 FROM sys.sequences
           WHERE name IN (N'InvoiceID', N'InvoiceLineID')
             AND (CONVERT(bigint, minimum_value) <> 1000000000 OR CONVERT(bigint, maximum_value) <> 1499999999)
       )
        THROW 51326, N'Los rangos de San Jose son incorrectos.', 1;

    IF N'$(NodeCode)' = N'LI'
       AND EXISTS
       (
           SELECT 1 FROM sys.sequences
           WHERE name IN (N'InvoiceID', N'InvoiceLineID')
             AND (CONVERT(bigint, minimum_value) <> 1500000000 OR CONVERT(bigint, maximum_value) <> 1999999999)
       )
        THROW 51327, N'Los rangos de Limon son incorrectos.', 1;
END;

SELECT
    @@SERVERNAME AS ServerName,
    N'$(NodeCode)' AS NodeCode,
    N'T03_PASS' AS Result;
