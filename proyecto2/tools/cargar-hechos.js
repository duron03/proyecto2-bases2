import { config } from 'dotenv';
import sql from 'mssql';

config();

const batchSize = 5000;

function required(name) {
    const value = process.env[name];

    if (!value) {
        throw new Error(`Falta ${name} en proyecto2/.env`);
    }

    return value;
}

function connection(serverName, portName, database) {
    return {
        user: required('OPERATOR_USER'),
        password: required('OPERATOR_PASSWORD'),
        server: required(serverName),
        port: Number(required(portName)),
        database,
        connectionTimeout: 10000,
        requestTimeout: 60000,
        pool: { min: 0, max: 3 },
        options: {
            encrypt: process.env.DB_ENCRYPT !== 'false',
            trustServerCertificate: process.env.DB_TRUST_SERVER_CERTIFICATE !== 'false'
        }
    };
}

function column(name, type, nullable = false) {
    return { name, type, nullable };
}

const definitions = [
    {
        name: 'Sales.Orders',
        key: 'OrderID',
        columns: [
            column('OrderID', sql.Int),
            column('CustomerID', sql.Int),
            column('OrderDate', sql.Date),
            column('LastEditedBy', sql.Int),
            column('LastEditedWhen', sql.DateTime2(7))
        ],
        query: `
            SELECT TOP (@BatchSize)
                sourceObject.OrderID,
                sourceObject.CustomerID,
                sourceObject.OrderDate,
                sourceObject.LastEditedBy,
                sourceObject.LastEditedWhen
            FROM WWI_Origen.Sales.Orders AS sourceObject
            INNER JOIN WideWorldImporters.Preparacion.AsignacionPedidos AS mapObject
                ON mapObject.OrderID = sourceObject.OrderID
            WHERE mapObject.SucursalID = @SucursalID
              AND sourceObject.OrderID > @LastId
            ORDER BY sourceObject.OrderID;`
    },
    {
        name: 'Purchasing.PurchaseOrders',
        key: 'PurchaseOrderID',
        columns: [
            column('PurchaseOrderID', sql.Int),
            column('SupplierID', sql.Int),
            column('OrderDate', sql.Date),
            column('DeliveryMethodID', sql.Int),
            column('ContactPersonID', sql.Int),
            column('ExpectedDeliveryDate', sql.Date, true),
            column('IsOrderFinalized', sql.Bit),
            column('LastEditedBy', sql.Int),
            column('LastEditedWhen', sql.DateTime2(7))
        ],
        query: `
            SELECT TOP (@BatchSize)
                sourceObject.PurchaseOrderID,
                sourceObject.SupplierID,
                sourceObject.OrderDate,
                sourceObject.DeliveryMethodID,
                sourceObject.ContactPersonID,
                sourceObject.ExpectedDeliveryDate,
                sourceObject.IsOrderFinalized,
                sourceObject.LastEditedBy,
                sourceObject.LastEditedWhen
            FROM WWI_Origen.Purchasing.PurchaseOrders AS sourceObject
            INNER JOIN WideWorldImporters.Preparacion.AsignacionCompras AS mapObject
                ON mapObject.PurchaseOrderID = sourceObject.PurchaseOrderID
            WHERE mapObject.SucursalID = @SucursalID
              AND sourceObject.PurchaseOrderID > @LastId
            ORDER BY sourceObject.PurchaseOrderID;`
    },
    {
        name: 'Sales.Invoices',
        key: 'InvoiceID',
        columns: [
            column('InvoiceID', sql.Int),
            column('CustomerID', sql.Int),
            column('BillToCustomerID', sql.Int),
            column('OrderID', sql.Int, true),
            column('DeliveryMethodID', sql.Int),
            column('ContactPersonID', sql.Int),
            column('AccountsPersonID', sql.Int),
            column('SalespersonPersonID', sql.Int),
            column('PackedByPersonID', sql.Int),
            column('InvoiceDate', sql.Date),
            column('CustomerPurchaseOrderNumber', sql.NVarChar(20), true),
            column('IsCreditNote', sql.Bit),
            column('CreditNoteReason', sql.NVarChar(sql.MAX), true),
            column('Comments', sql.NVarChar(sql.MAX), true),
            column('DeliveryInstructions', sql.NVarChar(sql.MAX), true),
            column('InternalComments', sql.NVarChar(sql.MAX), true),
            column('TotalDryItems', sql.Int),
            column('TotalChillerItems', sql.Int),
            column('DeliveryRun', sql.NVarChar(5), true),
            column('RunPosition', sql.NVarChar(5), true),
            column('ReturnedDeliveryData', sql.NVarChar(sql.MAX), true),
            column('LastEditedBy', sql.Int),
            column('LastEditedWhen', sql.DateTime2(7)),
            column('VersionVenta', sql.Int)
        ],
        query: `
            SELECT TOP (@BatchSize)
                sourceObject.InvoiceID,
                sourceObject.CustomerID,
                sourceObject.BillToCustomerID,
                sourceObject.OrderID,
                sourceObject.DeliveryMethodID,
                sourceObject.ContactPersonID,
                sourceObject.AccountsPersonID,
                sourceObject.SalespersonPersonID,
                sourceObject.PackedByPersonID,
                sourceObject.InvoiceDate,
                sourceObject.CustomerPurchaseOrderNumber,
                sourceObject.IsCreditNote,
                CONVERT(nvarchar(max), NULL) AS CreditNoteReason,
                CONVERT(nvarchar(max), NULL) AS Comments,
                CONVERT(nvarchar(max), NULL) AS DeliveryInstructions,
                CONVERT(nvarchar(max), NULL) AS InternalComments,
                sourceObject.TotalDryItems,
                sourceObject.TotalChillerItems,
                CONVERT(nvarchar(5), NULL) AS DeliveryRun,
                CONVERT(nvarchar(5), NULL) AS RunPosition,
                CONVERT(nvarchar(max), NULL) AS ReturnedDeliveryData,
                sourceObject.LastEditedBy,
                sourceObject.LastEditedWhen,
                CONVERT(int, 1) AS VersionVenta
            FROM WWI_Origen.Sales.Invoices AS sourceObject
            INNER JOIN WideWorldImporters.Preparacion.AsignacionFacturas AS mapObject
                ON mapObject.InvoiceID = sourceObject.InvoiceID
            WHERE mapObject.SucursalID = @SucursalID
              AND sourceObject.InvoiceID > @LastId
            ORDER BY sourceObject.InvoiceID;`
    },
    {
        name: 'Sales.InvoiceLines',
        key: 'InvoiceLineID',
        columns: [
            column('InvoiceLineID', sql.Int),
            column('InvoiceID', sql.Int),
            column('StockItemID', sql.Int),
            column('Description', sql.NVarChar(100)),
            column('PackageTypeID', sql.Int),
            column('Quantity', sql.Int),
            column('UnitPrice', sql.Decimal(18, 2), true),
            column('TaxRate', sql.Decimal(18, 3)),
            column('TaxAmount', sql.Decimal(18, 2)),
            column('LineProfit', sql.Decimal(18, 2)),
            column('ExtendedPrice', sql.Decimal(18, 2)),
            column('LastEditedBy', sql.Int),
            column('LastEditedWhen', sql.DateTime2(7))
        ],
        query: `
            SELECT TOP (@BatchSize)
                sourceObject.InvoiceLineID,
                sourceObject.InvoiceID,
                sourceObject.StockItemID,
                sourceObject.Description,
                sourceObject.PackageTypeID,
                sourceObject.Quantity,
                sourceObject.UnitPrice,
                sourceObject.TaxRate,
                sourceObject.TaxAmount,
                sourceObject.LineProfit,
                sourceObject.ExtendedPrice,
                sourceObject.LastEditedBy,
                sourceObject.LastEditedWhen
            FROM WWI_Origen.Sales.InvoiceLines AS sourceObject
            INNER JOIN WideWorldImporters.Preparacion.AsignacionFacturas AS mapObject
                ON mapObject.InvoiceID = sourceObject.InvoiceID
            WHERE mapObject.SucursalID = @SucursalID
              AND sourceObject.InvoiceLineID > @LastId
            ORDER BY sourceObject.InvoiceLineID;`
    },
    {
        name: 'Purchasing.PurchaseOrderLines',
        key: 'PurchaseOrderLineID',
        columns: [
            column('PurchaseOrderLineID', sql.Int),
            column('PurchaseOrderID', sql.Int),
            column('StockItemID', sql.Int),
            column('OrderedOuters', sql.Int),
            column('Description', sql.NVarChar(100)),
            column('ReceivedOuters', sql.Int),
            column('PackageTypeID', sql.Int),
            column('ExpectedUnitPricePerOuter', sql.Decimal(18, 2), true),
            column('LastReceiptDate', sql.Date, true),
            column('IsOrderLineFinalized', sql.Bit),
            column('LastEditedBy', sql.Int),
            column('LastEditedWhen', sql.DateTime2(7))
        ],
        query: `
            SELECT TOP (@BatchSize)
                sourceObject.PurchaseOrderLineID,
                sourceObject.PurchaseOrderID,
                sourceObject.StockItemID,
                sourceObject.OrderedOuters,
                sourceObject.Description,
                sourceObject.ReceivedOuters,
                sourceObject.PackageTypeID,
                sourceObject.ExpectedUnitPricePerOuter,
                sourceObject.LastReceiptDate,
                sourceObject.IsOrderLineFinalized,
                sourceObject.LastEditedBy,
                sourceObject.LastEditedWhen
            FROM WWI_Origen.Purchasing.PurchaseOrderLines AS sourceObject
            INNER JOIN WideWorldImporters.Preparacion.AsignacionCompras AS mapObject
                ON mapObject.PurchaseOrderID = sourceObject.PurchaseOrderID
            WHERE mapObject.SucursalID = @SucursalID
              AND sourceObject.PurchaseOrderLineID > @LastId
            ORDER BY sourceObject.PurchaseOrderLineID;`
    },
    {
        name: 'Sales.CustomerTransactions',
        key: 'CustomerTransactionID',
        columns: [
            column('CustomerTransactionID', sql.Int),
            column('CustomerID', sql.Int),
            column('TransactionTypeID', sql.Int),
            column('InvoiceID', sql.Int, true),
            column('PaymentMethodID', sql.Int, true),
            column('TransactionDate', sql.Date),
            column('AmountExcludingTax', sql.Decimal(18, 2)),
            column('TaxAmount', sql.Decimal(18, 2)),
            column('TransactionAmount', sql.Decimal(18, 2)),
            column('OutstandingBalance', sql.Decimal(18, 2)),
            column('FinalizationDate', sql.Date, true),
            column('LastEditedBy', sql.Int),
            column('LastEditedWhen', sql.DateTime2(7))
        ],
        query: `
            SELECT TOP (@BatchSize)
                sourceObject.CustomerTransactionID,
                sourceObject.CustomerID,
                sourceObject.TransactionTypeID,
                sourceObject.InvoiceID,
                sourceObject.PaymentMethodID,
                sourceObject.TransactionDate,
                sourceObject.AmountExcludingTax,
                sourceObject.TaxAmount,
                sourceObject.TransactionAmount,
                sourceObject.OutstandingBalance,
                sourceObject.FinalizationDate,
                sourceObject.LastEditedBy,
                sourceObject.LastEditedWhen
            FROM WWI_Origen.Sales.CustomerTransactions AS sourceObject
            LEFT JOIN WideWorldImporters.Preparacion.AsignacionFacturas AS mapObject
                ON mapObject.InvoiceID = sourceObject.InvoiceID
            WHERE
                CASE
                    WHEN sourceObject.InvoiceID IS NULL
                        THEN CASE WHEN sourceObject.CustomerTransactionID % 2 = 0 THEN 1 ELSE 2 END
                    ELSE mapObject.SucursalID
                END = @SucursalID
              AND sourceObject.CustomerTransactionID > @LastId
            ORDER BY sourceObject.CustomerTransactionID;`
    },
    {
        name: 'Purchasing.SupplierTransactions',
        key: 'SupplierTransactionID',
        columns: [
            column('SupplierTransactionID', sql.Int),
            column('SupplierID', sql.Int),
            column('TransactionTypeID', sql.Int),
            column('PurchaseOrderID', sql.Int, true),
            column('PaymentMethodID', sql.Int, true),
            column('SupplierInvoiceNumber', sql.NVarChar(20), true),
            column('TransactionDate', sql.Date),
            column('AmountExcludingTax', sql.Decimal(18, 2)),
            column('TaxAmount', sql.Decimal(18, 2)),
            column('TransactionAmount', sql.Decimal(18, 2)),
            column('OutstandingBalance', sql.Decimal(18, 2)),
            column('FinalizationDate', sql.Date, true),
            column('LastEditedBy', sql.Int),
            column('LastEditedWhen', sql.DateTime2(7))
        ],
        query: `
            SELECT TOP (@BatchSize)
                sourceObject.SupplierTransactionID,
                sourceObject.SupplierID,
                sourceObject.TransactionTypeID,
                sourceObject.PurchaseOrderID,
                sourceObject.PaymentMethodID,
                sourceObject.SupplierInvoiceNumber,
                sourceObject.TransactionDate,
                sourceObject.AmountExcludingTax,
                sourceObject.TaxAmount,
                sourceObject.TransactionAmount,
                sourceObject.OutstandingBalance,
                sourceObject.FinalizationDate,
                sourceObject.LastEditedBy,
                sourceObject.LastEditedWhen
            FROM WWI_Origen.Purchasing.SupplierTransactions AS sourceObject
            LEFT JOIN WideWorldImporters.Preparacion.AsignacionCompras AS mapObject
                ON mapObject.PurchaseOrderID = sourceObject.PurchaseOrderID
            WHERE
                CASE
                    WHEN sourceObject.PurchaseOrderID IS NULL
                        THEN CASE WHEN sourceObject.SupplierTransactionID % 2 = 0 THEN 1 ELSE 2 END
                    ELSE mapObject.SucursalID
                END = @SucursalID
              AND sourceObject.SupplierTransactionID > @LastId
            ORDER BY sourceObject.SupplierTransactionID;`
    },
    {
        name: 'Warehouse.StockItemHoldings',
        key: 'StockItemID',
        columns: [
            column('StockItemID', sql.Int),
            column('QuantityOnHand', sql.Int),
            column('BinLocation', sql.NVarChar(20)),
            column('LastStocktakeQuantity', sql.Int),
            column('LastCostPrice', sql.Decimal(18, 2)),
            column('ReorderLevel', sql.Int),
            column('TargetStockLevel', sql.Int),
            column('LastEditedBy', sql.Int),
            column('LastEditedWhen', sql.DateTime2(7)),
            column('VersionExistencias', sql.Int)
        ],
        query: `
            SELECT TOP (@BatchSize)
                sourceObject.StockItemID,
                CASE @SucursalID
                    WHEN 1 THEN sourceObject.QuantityOnHand / 2
                    ELSE sourceObject.QuantityOnHand - (sourceObject.QuantityOnHand / 2)
                END AS QuantityOnHand,
                sourceObject.BinLocation,
                CASE @SucursalID
                    WHEN 1 THEN sourceObject.LastStocktakeQuantity / 2
                    ELSE sourceObject.LastStocktakeQuantity - (sourceObject.LastStocktakeQuantity / 2)
                END AS LastStocktakeQuantity,
                sourceObject.LastCostPrice,
                CASE @SucursalID
                    WHEN 1 THEN sourceObject.ReorderLevel / 2
                    ELSE sourceObject.ReorderLevel - (sourceObject.ReorderLevel / 2)
                END AS ReorderLevel,
                CASE @SucursalID
                    WHEN 1 THEN sourceObject.TargetStockLevel / 2
                    ELSE sourceObject.TargetStockLevel - (sourceObject.TargetStockLevel / 2)
                END AS TargetStockLevel,
                sourceObject.LastEditedBy,
                sourceObject.LastEditedWhen,
                CONVERT(int, 1) AS VersionExistencias
            FROM WWI_Origen.Warehouse.StockItemHoldings AS sourceObject
            WHERE sourceObject.StockItemID > @LastId
            ORDER BY sourceObject.StockItemID;`
    }
];

const expectedCounts = {
    1: [36797, 1037, 35254, 114208, 4215, 48585, 1218, 228],
    2: [36798, 1037, 35257, 114059, 4152, 48562, 1220, 228]
};

async function assertReady(pool, branch) {
    const result = await pool.request().query(`
        SELECT
            (SELECT Codigo FROM Control.Nodo WHERE Id = 1) AS NodeCode,
            (SELECT DatosValidados FROM Control.EstadoCatalogo WHERE Id = 1) AS CatalogValidated,
            (SELECT COUNT_BIG(*) FROM Sales.Orders) AS OrdersCount,
            (SELECT COUNT_BIG(*) FROM Purchasing.PurchaseOrders) AS PurchaseOrdersCount,
            (SELECT COUNT_BIG(*) FROM Sales.Invoices) AS InvoicesCount,
            (SELECT COUNT_BIG(*) FROM Sales.InvoiceLines) AS InvoiceLinesCount,
            (SELECT COUNT_BIG(*) FROM Purchasing.PurchaseOrderLines) AS PurchaseOrderLinesCount,
            (SELECT COUNT_BIG(*) FROM Sales.CustomerTransactions) AS CustomerTransactionsCount,
            (SELECT COUNT_BIG(*) FROM Purchasing.SupplierTransactions) AS SupplierTransactionsCount,
            (SELECT COUNT_BIG(*) FROM Warehouse.StockItemHoldings) AS HoldingsCount;
    `);

    const row = result.recordset[0];

    if (row.NodeCode !== branch.code || row.CatalogValidated !== true) {
        throw new Error(`${branch.code}: catalogo no validado o identidad incorrecta.`);
    }

    const totalRows = Object.entries(row)
        .filter(([name]) => name.endsWith('Count'))
        .reduce((total, [, value]) => total + Number(value), 0);

    if (totalRows !== 0) {
        throw new Error(`${branch.code}: la carga se rechazo porque existen hechos en el destino.`);
    }
}

async function bulkRows(pool, definition, rows) {
    const table = new sql.Table(definition.name);
    table.create = false;

    for (const item of definition.columns) {
        table.columns.add(item.name, item.type, { nullable: item.nullable });
    }

    for (const row of rows) {
        table.rows.add(...definition.columns.map((item) => row[item.name]));
    }

    await pool.request().bulk(table);
}

async function loadDefinition(sourcePool, destinationPool, branch, definition) {
    let lastId = 0;
    let loaded = 0;

    while (true) {
        const result = await sourcePool.request()
            .input('SucursalID', sql.Int, branch.id)
            .input('LastId', sql.Int, lastId)
            .input('BatchSize', sql.Int, batchSize)
            .query(definition.query);

        if (result.recordset.length === 0) {
            break;
        }

        await bulkRows(destinationPool, definition, result.recordset);
        loaded += result.recordset.length;
        lastId = result.recordset[result.recordset.length - 1][definition.key];
    }

    console.log(`${branch.code} ${definition.name}: ${loaded} filas`);
    return loaded;
}

async function loadBranch(sourcePool, branch) {
    const destinationPool = new sql.ConnectionPool(
        connection(branch.serverVariable, branch.portVariable, 'WideWorldImporters')
    );

    await destinationPool.connect();

    try {
        await assertReady(destinationPool, branch);
        const measured = [];

        for (const definition of definitions) {
            measured.push(await loadDefinition(sourcePool, destinationPool, branch, definition));
        }

        const expected = expectedCounts[branch.id];

        if (measured.some((value, index) => value !== expected[index])) {
            throw new Error(`${branch.code}: los conteos cargados no coinciden con la matriz T02.`);
        }

        await destinationPool.request().batch(`
            SET ANSI_NULLS ON;
            SET QUOTED_IDENTIFIER ON;
            ALTER TABLE Sales.Orders WITH CHECK CHECK CONSTRAINT ALL;
            ALTER TABLE Purchasing.PurchaseOrders WITH CHECK CHECK CONSTRAINT ALL;
            ALTER TABLE Sales.Invoices WITH CHECK CHECK CONSTRAINT ALL;
            ALTER TABLE Sales.InvoiceLines WITH CHECK CHECK CONSTRAINT ALL;
            ALTER TABLE Purchasing.PurchaseOrderLines WITH CHECK CHECK CONSTRAINT ALL;
            ALTER TABLE Sales.CustomerTransactions WITH CHECK CHECK CONSTRAINT ALL;
            ALTER TABLE Purchasing.SupplierTransactions WITH CHECK CHECK CONSTRAINT ALL;
            ALTER TABLE Warehouse.StockItemHoldings WITH CHECK CHECK CONSTRAINT ALL;
        `);
    } finally {
        await destinationPool.close();
    }
}

async function main() {
    const requestedBranch = process.argv[2];
    const branches = [
        {
            id: 1,
            code: 'SJ',
            serverVariable: 'SJ_SERVER',
            portVariable: 'SJ_PORT'
        },
        {
            id: 2,
            code: 'LI',
            serverVariable: 'LI_SERVER',
            portVariable: 'LI_PORT'
        }
    ];

    if (requestedBranch && !branches.some((branch) => branch.code === requestedBranch)) {
        throw new Error('Sucursal invalida. Use SJ o LI.');
    }

    const sourcePool = new sql.ConnectionPool(
        connection('CORP_SERVER', 'CORP_PORT', 'WideWorldImporters')
    );

    await sourcePool.connect();

    try {
        for (const branch of branches) {
            if (!requestedBranch || requestedBranch === branch.code) {
                await loadBranch(sourcePool, branch);
            }
        }
    } finally {
        await sourcePool.close();
    }

    console.log('Carga inicial de hechos completada.');
}

main().catch((error) => {
    console.error(error.message);
    process.exitCode = 1;
});
