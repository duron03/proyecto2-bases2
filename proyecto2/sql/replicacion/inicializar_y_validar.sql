:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;

USE [WideWorldImporters];
GO

DECLARE @NodeCode varchar(4) = '$(NodeCode)';
DECLARE @Action varchar(12) = '$(Action)';
DECLARE @Publication sysname;

IF @NodeCode NOT IN ('CORP', 'SJ', 'LI')
    THROW 51430, N'NodeCode debe ser CORP, SJ o LI.', 1;

IF @Action NOT IN ('START', 'STATUS', 'CHECKSJ', 'CHECKLI', 'VALIDATE')
    THROW 51431, N'Action debe ser START, STATUS, CHECKSJ, CHECKLI o VALIDATE.', 1;

SET @Publication =
    CASE @NodeCode
        WHEN 'CORP' THEN N'P2_Catalogos'
        WHEN 'SJ' THEN N'P2_Operacion_SJ'
        ELSE N'P2_Operacion_LI'
    END;

IF @Action = 'STATUS'
BEGIN
    SELECT
        jobObject.name AS JobName,
        stepObject.subsystem AS AgentType,
        activityObject.start_execution_date AS StartedAt,
        activityObject.stop_execution_date AS StoppedAt,
        historyObject.run_status AS LastRunStatus,
        historyObject.message AS LastMessage,
        CASE WHEN stepObject.command LIKE N'%-EncryptionLevel 1%' THEN 1 ELSE 0 END AS TlsConfigured
    FROM msdb.dbo.sysjobs AS jobObject
    INNER JOIN msdb.dbo.sysjobsteps AS stepObject
        ON stepObject.job_id = jobObject.job_id
       AND stepObject.step_id = 2
    LEFT JOIN msdb.dbo.sysjobactivity AS activityObject
        ON activityObject.job_id = jobObject.job_id
       AND activityObject.session_id = (SELECT MAX(session_id) FROM msdb.dbo.syssessions)
    OUTER APPLY
    (
        SELECT TOP (1)
            history.run_status,
            history.message
        FROM msdb.dbo.sysjobhistory AS history
        WHERE history.job_id = jobObject.job_id
          AND history.step_id = 0
        ORDER BY history.instance_id DESC
    ) AS historyObject
    WHERE jobObject.name LIKE N'%' + @Publication + N'%'
       OR
       (
           @Publication = N'P2_Catalogos'
           AND stepObject.subsystem = N'LogReader'
           AND stepObject.command LIKE N'%WideWorldImporters%'
       )
    ORDER BY AgentType, JobName;

    SELECT
        agentObject.name AS AgentName,
        agentObject.publication AS PublicationName,
        agentObject.subscriber_name AS SubscriberName,
        statusObject.undelivcmdsindistdb AS PendingCommands,
        historyObject.time AS LastHistoryAt,
        historyObject.runstatus AS RunStatus,
        historyObject.delivery_latency AS DeliveryLatencySeconds,
        historyObject.comments AS LastComment,
        errorObject.error_text AS ErrorText
    FROM distribution.dbo.MSdistribution_agents AS agentObject
    OUTER APPLY
    (
        SELECT TOP (1)
            history.time,
            history.runstatus,
            history.delivery_latency,
            history.comments,
            history.error_id
        FROM distribution.dbo.MSdistribution_history AS history
        WHERE history.agent_id = agentObject.id
        ORDER BY history.timestamp DESC
    ) AS historyObject
    LEFT JOIN distribution.dbo.MSrepl_errors AS errorObject
        ON errorObject.id = historyObject.error_id
    OUTER APPLY
    (
        SELECT SUM(statusRow.undelivcmdsindistdb) AS undelivcmdsindistdb
        FROM distribution.dbo.MSdistribution_status AS statusRow
        WHERE statusRow.agent_id = agentObject.id
    ) AS statusObject
    WHERE agentObject.publisher_db = N'WideWorldImporters'
      AND agentObject.publication = @Publication
    ORDER BY SubscriberName;

    RETURN;
END;

IF @Action = 'CHECKSJ'
BEGIN
    IF @NodeCode <> 'CORP'
        THROW 51437, N'CHECKSJ solo se ejecuta en CORP.', 1;

    SELECT
        (SELECT COUNT_BIG(*) FROM sj.Orders) AS OrdersCount,
        (SELECT COUNT_BIG(*) FROM sj.Invoices) AS InvoicesCount,
        (SELECT COUNT_BIG(*) FROM sj.InvoiceLines) AS InvoiceLinesCount,
        (SELECT COUNT_BIG(*) FROM sj.CustomerTransactions) AS CustomerTransactionsCount,
        (SELECT COUNT_BIG(*) FROM sj.PurchaseOrders) AS PurchaseOrdersCount,
        (SELECT COUNT_BIG(*) FROM sj.PurchaseOrderLines) AS PurchaseOrderLinesCount,
        (SELECT COUNT_BIG(*) FROM sj.SupplierTransactions) AS SupplierTransactionsCount,
        (SELECT COUNT_BIG(*) FROM sj.StockItemHoldings) AS HoldingsCount,
        (SELECT COUNT_BIG(*) FROM sj.LatidoSucursal) AS HeartbeatCount;

    IF (SELECT COUNT_BIG(*) FROM sj.Orders) <> 36797
       OR (SELECT COUNT_BIG(*) FROM sj.Invoices) <> 35254
       OR (SELECT COUNT_BIG(*) FROM sj.InvoiceLines) <> 114208
       OR (SELECT COUNT_BIG(*) FROM sj.CustomerTransactions) <> 48585
       OR (SELECT COUNT_BIG(*) FROM sj.PurchaseOrders) <> 1037
       OR (SELECT COUNT_BIG(*) FROM sj.PurchaseOrderLines) <> 4215
       OR (SELECT COUNT_BIG(*) FROM sj.SupplierTransactions) <> 1218
       OR (SELECT COUNT_BIG(*) FROM sj.StockItemHoldings) <> 228
       OR (SELECT COUNT_BIG(*) FROM sj.LatidoSucursal) <> 1
        THROW 51438, N'La copia de San Jose aun no esta completa.', 1;

    SELECT N'SJ_RECEIVER_COMPLETE' AS Result;
    RETURN;
END;

IF @Action = 'CHECKLI'
BEGIN
    IF @NodeCode <> 'CORP'
        THROW 51443, N'CHECKLI solo se ejecuta en CORP.', 1;

    SELECT
        (SELECT COUNT_BIG(*) FROM limon.Orders) AS OrdersCount,
        (SELECT COUNT_BIG(*) FROM limon.Invoices) AS InvoicesCount,
        (SELECT COUNT_BIG(*) FROM limon.InvoiceLines) AS InvoiceLinesCount,
        (SELECT COUNT_BIG(*) FROM limon.CustomerTransactions) AS CustomerTransactionsCount,
        (SELECT COUNT_BIG(*) FROM limon.PurchaseOrders) AS PurchaseOrdersCount,
        (SELECT COUNT_BIG(*) FROM limon.PurchaseOrderLines) AS PurchaseOrderLinesCount,
        (SELECT COUNT_BIG(*) FROM limon.SupplierTransactions) AS SupplierTransactionsCount,
        (SELECT COUNT_BIG(*) FROM limon.StockItemHoldings) AS HoldingsCount,
        (SELECT COUNT_BIG(*) FROM limon.LatidoSucursal) AS HeartbeatCount;

    IF (SELECT COUNT_BIG(*) FROM limon.Orders) <> 36798
       OR (SELECT COUNT_BIG(*) FROM limon.Invoices) <> 35257
       OR (SELECT COUNT_BIG(*) FROM limon.InvoiceLines) <> 114059
       OR (SELECT COUNT_BIG(*) FROM limon.CustomerTransactions) <> 48562
       OR (SELECT COUNT_BIG(*) FROM limon.PurchaseOrders) <> 1037
       OR (SELECT COUNT_BIG(*) FROM limon.PurchaseOrderLines) <> 4152
       OR (SELECT COUNT_BIG(*) FROM limon.SupplierTransactions) <> 1220
       OR (SELECT COUNT_BIG(*) FROM limon.StockItemHoldings) <> 228
       OR (SELECT COUNT_BIG(*) FROM limon.LatidoSucursal) <> 1
        THROW 51444, N'La copia de Limon aun no esta completa.', 1;

    SELECT N'LI_RECEIVER_COMPLETE' AS Result;
    RETURN;
END;

IF @Action = 'START'
BEGIN
    IF NOT EXISTS (SELECT 1 FROM syspublications WHERE name = @Publication)
        THROW 51432, N'La publicacion indicada no existe.', 1;

    EXEC dbo.sp_startpublication_snapshot @publication = @Publication;

    SELECT
        @@SERVERNAME AS ServerName,
        @Publication AS PublicationName,
        N'SNAPSHOT_STARTED' AS Result;

    RETURN;
END;

IF @Action = 'VALIDATE' AND @NodeCode IN ('SJ', 'LI')
BEGIN
    IF SCHEMA_ID(N'Privado') IS NOT NULL
        THROW 51433, N'La sucursal contiene el esquema privado.', 1;

    IF (SELECT COUNT_BIG(*) FROM Application.People) <> 1114
       OR (SELECT COUNT_BIG(*) FROM Application.DeliveryMethods) <> 10
       OR (SELECT COUNT_BIG(*) FROM Application.PaymentMethods) <> 4
       OR (SELECT COUNT_BIG(*) FROM Application.TransactionTypes) <> 13
       OR (SELECT COUNT_BIG(*) FROM Sales.CustomerCategories) <> 8
       OR (SELECT COUNT_BIG(*) FROM Sales.BuyingGroups) <> 2
       OR (SELECT COUNT_BIG(*) FROM Purchasing.SupplierCategories) <> 9
       OR (SELECT COUNT_BIG(*) FROM Warehouse.StockGroups) <> 10
       OR (SELECT COUNT_BIG(*) FROM Warehouse.Colors) <> 36
       OR (SELECT COUNT_BIG(*) FROM Warehouse.PackageTypes) <> 14
       OR (SELECT COUNT_BIG(*) FROM Sales.Customers) <> 663
       OR (SELECT COUNT_BIG(*) FROM Purchasing.Suppliers) <> 13
       OR (SELECT COUNT_BIG(*) FROM Warehouse.StockItems) <> 228
       OR (SELECT COUNT_BIG(*) FROM Warehouse.StockItemStockGroups) <> 443
       OR (SELECT COUNT_BIG(*) FROM Control.LatidoCatalogo) <> 1
    BEGIN
        SELECT N'Application.People' AS TableName, COUNT_BIG(*) AS TotalRows FROM Application.People
        UNION ALL SELECT N'Application.DeliveryMethods', COUNT_BIG(*) FROM Application.DeliveryMethods
        UNION ALL SELECT N'Application.PaymentMethods', COUNT_BIG(*) FROM Application.PaymentMethods
        UNION ALL SELECT N'Application.TransactionTypes', COUNT_BIG(*) FROM Application.TransactionTypes
        UNION ALL SELECT N'Sales.CustomerCategories', COUNT_BIG(*) FROM Sales.CustomerCategories
        UNION ALL SELECT N'Sales.BuyingGroups', COUNT_BIG(*) FROM Sales.BuyingGroups
        UNION ALL SELECT N'Purchasing.SupplierCategories', COUNT_BIG(*) FROM Purchasing.SupplierCategories
        UNION ALL SELECT N'Warehouse.StockGroups', COUNT_BIG(*) FROM Warehouse.StockGroups
        UNION ALL SELECT N'Warehouse.Colors', COUNT_BIG(*) FROM Warehouse.Colors
        UNION ALL SELECT N'Warehouse.PackageTypes', COUNT_BIG(*) FROM Warehouse.PackageTypes
        UNION ALL SELECT N'Sales.Customers', COUNT_BIG(*) FROM Sales.Customers
        UNION ALL SELECT N'Purchasing.Suppliers', COUNT_BIG(*) FROM Purchasing.Suppliers
        UNION ALL SELECT N'Warehouse.StockItems', COUNT_BIG(*) FROM Warehouse.StockItems
        UNION ALL SELECT N'Warehouse.StockItemStockGroups', COUNT_BIG(*) FROM Warehouse.StockItemStockGroups
        UNION ALL SELECT N'Control.LatidoCatalogo', COUNT_BIG(*) FROM Control.LatidoCatalogo;

        THROW 51434, N'El snapshot de catalogos esta incompleto.', 1;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM Application.People
        WHERE PersonID <= 3261
          AND FullName <> CONVERT(nvarchar(50), CONCAT(N'Persona ', PersonID))
    )
        THROW 51435, N'La sucursal recibio un nombre privado de persona.', 1;

    IF EXISTS
    (
        SELECT 1
        FROM Sales.Customers AS childObject
        LEFT JOIN Sales.Customers AS parentObject
            ON parentObject.CustomerID = childObject.BillToCustomerID
        WHERE parentObject.CustomerID IS NULL
    )
       OR EXISTS
    (
        SELECT 1
        FROM Warehouse.StockItems AS childObject
        LEFT JOIN Purchasing.Suppliers AS parentObject
            ON parentObject.SupplierID = childObject.SupplierID
        WHERE parentObject.SupplierID IS NULL
    )
       OR EXISTS
    (
        SELECT 1
        FROM Warehouse.StockItemStockGroups AS childObject
        LEFT JOIN Warehouse.StockItems AS itemObject
            ON itemObject.StockItemID = childObject.StockItemID
        LEFT JOIN Warehouse.StockGroups AS groupObject
            ON groupObject.StockGroupID = childObject.StockGroupID
        WHERE itemObject.StockItemID IS NULL OR groupObject.StockGroupID IS NULL
    )
        THROW 51436, N'El catalogo replicado contiene una referencia huerfana.', 1;

    UPDATE Control.EstadoCatalogo
    SET DatosValidados = 1,
        ValidadoUtc = SYSUTCDATETIME()
    WHERE Id = 1;

    SELECT
        @@SERVERNAME AS ServerName,
        @NodeCode AS NodeCode,
        N'CATALOG_SNAPSHOT_VALIDATED' AS Result;

    RETURN;
END;

IF @Action = 'VALIDATE' AND @NodeCode = 'CORP'
BEGIN
    IF (SELECT COUNT_BIG(*) FROM sj.Orders) <> 36797
       OR (SELECT COUNT_BIG(*) FROM limon.Orders) <> 36798
       OR (SELECT COUNT_BIG(*) FROM sj.Invoices) <> 35254
       OR (SELECT COUNT_BIG(*) FROM limon.Invoices) <> 35257
       OR (SELECT COUNT_BIG(*) FROM sj.InvoiceLines) <> 114208
       OR (SELECT COUNT_BIG(*) FROM limon.InvoiceLines) <> 114059
       OR (SELECT COUNT_BIG(*) FROM sj.CustomerTransactions) <> 48585
       OR (SELECT COUNT_BIG(*) FROM limon.CustomerTransactions) <> 48562
       OR (SELECT COUNT_BIG(*) FROM sj.PurchaseOrders) <> 1037
       OR (SELECT COUNT_BIG(*) FROM limon.PurchaseOrders) <> 1037
       OR (SELECT COUNT_BIG(*) FROM sj.PurchaseOrderLines) <> 4215
       OR (SELECT COUNT_BIG(*) FROM limon.PurchaseOrderLines) <> 4152
       OR (SELECT COUNT_BIG(*) FROM sj.SupplierTransactions) <> 1218
       OR (SELECT COUNT_BIG(*) FROM limon.SupplierTransactions) <> 1220
       OR (SELECT COUNT_BIG(*) FROM sj.StockItemHoldings) <> 228
       OR (SELECT COUNT_BIG(*) FROM limon.StockItemHoldings) <> 228
       OR (SELECT COUNT_BIG(*) FROM sj.LatidoSucursal) <> 1
       OR (SELECT COUNT_BIG(*) FROM limon.LatidoSucursal) <> 1
        THROW 51440, N'Las copias corporativas de hechos estan incompletas.', 1;

    IF EXISTS
    (
        SELECT InvoiceID FROM sj.Invoices
        INTERSECT
        SELECT InvoiceID FROM limon.Invoices
    )
       OR EXISTS
    (
        SELECT OrderID FROM sj.Orders
        INTERSECT
        SELECT OrderID FROM limon.Orders
    )
       OR EXISTS
    (
        SELECT PurchaseOrderID FROM sj.PurchaseOrders
        INTERSECT
        SELECT PurchaseOrderID FROM limon.PurchaseOrders
    )
        THROW 51441, N'Los fragmentos de hechos se cruzaron entre sedes.', 1;

    IF EXISTS
    (
        SELECT sourceObject.StockItemID
        FROM WWI_Origen.Warehouse.StockItemHoldings AS sourceObject
        INNER JOIN sj.StockItemHoldings AS sjObject
            ON sjObject.StockItemID = sourceObject.StockItemID
        INNER JOIN limon.StockItemHoldings AS liObject
            ON liObject.StockItemID = sourceObject.StockItemID
        WHERE sourceObject.QuantityOnHand <> sjObject.QuantityOnHand + liObject.QuantityOnHand
           OR sourceObject.LastStocktakeQuantity <> sjObject.LastStocktakeQuantity + liObject.LastStocktakeQuantity
           OR sourceObject.ReorderLevel <> sjObject.ReorderLevel + liObject.ReorderLevel
           OR sourceObject.TargetStockLevel <> sjObject.TargetStockLevel + liObject.TargetStockLevel
    )
        THROW 51442, N'Las cantidades de holdings no reconstruyen el origen.', 1;

    UPDATE Control.EstadoInicializacion
    SET DatosValidados = 1,
        ValidadoUtc = SYSUTCDATETIME()
    WHERE SucursalID IN (1, 2);

    SELECT
        @@SERVERNAME AS ServerName,
        N'CORP' AS NodeCode,
        N'FACT_SNAPSHOTS_VALIDATED' AS Result;
END;
