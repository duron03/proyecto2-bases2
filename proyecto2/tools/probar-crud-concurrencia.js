import { config } from 'dotenv';
import sql from 'mssql';

config();

function required(name) {
    const value = process.env[name];

    if (!value) {
        throw new Error(`Falta ${name} en proyecto2/.env`);
    }

    return value;
}

function connectionSettings(serverName, portName, user, password) {
    return {
        server: required(serverName),
        port: Number(required(portName)),
        database: process.env.DB_DATABASE || 'WideWorldImporters',
        user,
        password,
        connectionTimeout: 10000,
        requestTimeout: 60000,
        pool: { max: 3, min: 0, idleTimeoutMillis: 30000 },
        options: {
            encrypt: process.env.DB_ENCRYPT !== 'false',
            trustServerCertificate: process.env.DB_TRUST_SERVER_CERTIFICATE !== 'false'
        }
    };
}

async function connect(serverName, portName, user, password) {
    const pool = new sql.ConnectionPool(
        connectionSettings(serverName, portName, user, password)
    );
    await pool.connect();
    return pool;
}

function addInputs(request, inputs) {
    for (const [name, type, value] of inputs) {
        request.input(name, type, value);
    }

    return request;
}

async function execute(pool, procedure, inputs = []) {
    return addInputs(pool.request(), inputs).execute(procedure);
}

function getErrorNumber(error) {
    return error.number || error.originalError?.info?.number;
}

async function expectSqlError(action, expectedNumber, label) {
    try {
        await action();
    } catch (error) {
        if (getErrorNumber(error) === expectedNumber) {
            return;
        }

        throw new Error(`${label}: error ${getErrorNumber(error) || error.code || 'desconocido'}`);
    }

    throw new Error(`${label}: la operacion debio fallar`);
}

async function waitFor(check, label) {
    for (let attempt = 0; attempt < 45; attempt += 1) {
        if (await check()) {
            return;
        }

        await new Promise((resolve) => setTimeout(resolve, 1000));
    }

    throw new Error(`Tiempo agotado esperando ${label}`);
}

function customerInputs(data, version) {
    const inputs = [
        ['CustomerName', sql.NVarChar(100), data.CustomerName],
        ['CustomerCategoryID', sql.Int, data.CustomerCategoryID],
        ['PrimaryContactPersonID', sql.Int, data.PrimaryContactPersonID],
        ['DeliveryMethodID', sql.Int, data.DeliveryMethodID],
        ['DeliveryCityID', sql.Int, data.DeliveryCityID],
        ['PostalCityID', sql.Int, data.PostalCityID],
        ['AccountOpenedDate', sql.Date, data.AccountOpenedDate],
        ['StandardDiscountPercentage', sql.Decimal(18, 3), data.StandardDiscountPercentage],
        ['IsStatementSent', sql.Bit, data.IsStatementSent],
        ['IsOnCreditHold', sql.Bit, data.IsOnCreditHold],
        ['PaymentDays', sql.Int, data.PaymentDays],
        ['PhoneNumber', sql.NVarChar(20), data.PhoneNumber],
        ['FaxNumber', sql.NVarChar(20), data.FaxNumber],
        ['WebsiteURL', sql.NVarChar(256), data.WebsiteURL],
        ['DeliveryAddressLine1', sql.NVarChar(60), data.DeliveryAddressLine1],
        ['DeliveryPostalCode', sql.NVarChar(10), data.DeliveryPostalCode],
        ['PostalAddressLine1', sql.NVarChar(60), data.PostalAddressLine1],
        ['PostalPostalCode', sql.NVarChar(10), data.PostalPostalCode],
        ['BillToCustomerID', sql.Int, data.BillToCustomerID],
        ['BuyingGroupID', sql.Int, data.BuyingGroupID],
        ['AlternateContactPersonID', sql.Int, data.AlternateContactPersonID],
        ['CreditLimit', sql.Decimal(18, 2), data.CreditLimit],
        ['DeliveryRun', sql.NVarChar(5), data.DeliveryRun],
        ['RunPosition', sql.NVarChar(5), data.RunPosition],
        ['DeliveryAddressLine2', sql.NVarChar(60), data.DeliveryAddressLine2],
        ['DeliveryLatitude', sql.Decimal(9, 6), data.DeliveryLatitude],
        ['DeliveryLongitude', sql.Decimal(9, 6), data.DeliveryLongitude],
        ['PostalAddressLine2', sql.NVarChar(60), data.PostalAddressLine2]
    ];

    if (data.CustomerID !== undefined) {
        inputs.unshift(['CustomerID', sql.Int, data.CustomerID]);
    }

    if (version !== undefined) {
        inputs.push(['VersionEsperada', sql.Int, version]);
    }

    return inputs;
}

function supplierInputs(data, version) {
    const inputs = [
        ['SupplierName', sql.NVarChar(100), data.SupplierName],
        ['SupplierCategoryID', sql.Int, data.SupplierCategoryID],
        ['PrimaryContactPersonID', sql.Int, data.PrimaryContactPersonID],
        ['AlternateContactPersonID', sql.Int, data.AlternateContactPersonID],
        ['DeliveryCityID', sql.Int, data.DeliveryCityID],
        ['PostalCityID', sql.Int, data.PostalCityID],
        ['PaymentDays', sql.Int, data.PaymentDays],
        ['PhoneNumber', sql.NVarChar(20), data.PhoneNumber],
        ['FaxNumber', sql.NVarChar(20), data.FaxNumber],
        ['WebsiteURL', sql.NVarChar(256), data.WebsiteURL],
        ['DeliveryAddressLine1', sql.NVarChar(60), data.DeliveryAddressLine1],
        ['DeliveryPostalCode', sql.NVarChar(10), data.DeliveryPostalCode],
        ['PostalAddressLine1', sql.NVarChar(60), data.PostalAddressLine1],
        ['PostalPostalCode', sql.NVarChar(10), data.PostalPostalCode],
        ['DeliveryMethodID', sql.Int, data.DeliveryMethodID],
        ['SupplierReference', sql.NVarChar(20), data.SupplierReference],
        ['BankAccountName', sql.NVarChar(50), data.BankAccountName],
        ['BankAccountBranch', sql.NVarChar(50), data.BankAccountBranch],
        ['BankAccountCode', sql.NVarChar(20), data.BankAccountCode],
        ['BankAccountNumber', sql.NVarChar(20), data.BankAccountNumber],
        ['BankInternationalCode', sql.NVarChar(20), data.BankInternationalCode],
        ['InternalComments', sql.NVarChar(sql.MAX), data.InternalComments],
        ['DeliveryAddressLine2', sql.NVarChar(60), data.DeliveryAddressLine2],
        ['DeliveryLatitude', sql.Decimal(9, 6), data.DeliveryLatitude],
        ['DeliveryLongitude', sql.Decimal(9, 6), data.DeliveryLongitude],
        ['PostalAddressLine2', sql.NVarChar(60), data.PostalAddressLine2]
    ];

    if (data.SupplierID !== undefined) {
        inputs.unshift(['SupplierID', sql.Int, data.SupplierID]);
    }

    if (version !== undefined) {
        inputs.push(['VersionEsperada', sql.Int, version]);
    }

    return inputs;
}

function productInputs(data, version) {
    const inputs = [
        ['StockItemName', sql.NVarChar(100), data.StockItemName],
        ['SupplierID', sql.Int, data.SupplierID],
        ['UnitPackageID', sql.Int, data.UnitPackageID],
        ['OuterPackageID', sql.Int, data.OuterPackageID],
        ['LeadTimeDays', sql.Int, data.LeadTimeDays],
        ['QuantityPerOuter', sql.Int, data.QuantityPerOuter],
        ['IsChillerStock', sql.Bit, data.IsChillerStock],
        ['TaxRate', sql.Decimal(18, 3), data.TaxRate],
        ['UnitPrice', sql.Decimal(18, 2), data.UnitPrice],
        ['TypicalWeightPerUnit', sql.Decimal(18, 3), data.TypicalWeightPerUnit],
        ['ColorID', sql.Int, data.ColorID],
        ['Brand', sql.NVarChar(50), data.Brand],
        ['Size', sql.NVarChar(20), data.Size],
        ['Barcode', sql.NVarChar(50), data.Barcode],
        ['RecommendedRetailPrice', sql.Decimal(18, 2), data.RecommendedRetailPrice],
        ['MarketingComments', sql.NVarChar(sql.MAX), data.MarketingComments],
        ['InternalComments', sql.NVarChar(sql.MAX), data.InternalComments],
        ['Photo', sql.VarBinary(sql.MAX), data.Photo],
        ['CustomFields', sql.NVarChar(sql.MAX), data.CustomFields]
    ];

    if (data.StockItemID !== undefined) {
        inputs.unshift(['StockItemID', sql.Int, data.StockItemID]);
    } else {
        inputs.push(['StockGroupID', sql.Int, data.StockGroupID]);
    }

    if (version !== undefined) {
        inputs.push(['VersionEsperada', sql.Int, version]);
    }

    return inputs;
}

function saleInputs(data, version) {
    const inputs = [
        ['CustomerID', sql.Int, data.CustomerID],
        ['BillToCustomerID', sql.Int, data.BillToCustomerID],
        ['DeliveryMethodID', sql.Int, data.DeliveryMethodID],
        ['ContactPersonID', sql.Int, data.ContactPersonID],
        ['AccountsPersonID', sql.Int, data.AccountsPersonID],
        ['SalespersonPersonID', sql.Int, data.SalespersonPersonID],
        ['PackedByPersonID', sql.Int, data.PackedByPersonID],
        ['InvoiceDate', sql.Date, data.InvoiceDate],
        ['OrderID', sql.Int, null],
        ['CustomerPurchaseOrderNumber', sql.NVarChar(20), data.CustomerPurchaseOrderNumber],
        ['IsCreditNote', sql.Bit, false],
        ['CreditNoteReason', sql.NVarChar(sql.MAX), null],
        ['Comments', sql.NVarChar(sql.MAX), data.Comments],
        ['DeliveryInstructions', sql.NVarChar(sql.MAX), null],
        ['InternalComments', sql.NVarChar(sql.MAX), null],
        ['DeliveryRun', sql.NVarChar(5), null],
        ['RunPosition', sql.NVarChar(5), null],
        ['ReturnedDeliveryData', sql.NVarChar(sql.MAX), null],
        ['InvoiceLines', sql.NVarChar(sql.MAX), JSON.stringify(data.Lines)]
    ];

    if (data.InvoiceID !== undefined) {
        inputs.unshift(['InvoiceID', sql.Int, data.InvoiceID]);
    }

    if (version !== undefined) {
        inputs.push(['VersionEsperada', sql.Int, version]);
    }

    return inputs;
}

async function main() {
    const stamp = Date.now().toString().slice(-10);
    const adminSjPassword = required('ADMIN_SJ_PASSWORD');
    const adminLimonPassword = required('ADMIN_LIMON_PASSWORD');
    const operatorUser = required('OPERATOR_USER');
    const operatorPassword = required('OPERATOR_PASSWORD');
    const pools = [];

    try {
        const corpSj = await connect('CORP_SERVER', 'CORP_PORT', 'admin_sj', adminSjPassword);
        const corpLi = await connect(
            'CORP_SERVER', 'CORP_PORT', 'admin_limon', adminLimonPassword
        );
        const sjA = await connect('SJ_SERVER', 'SJ_PORT', 'admin_sj', adminSjPassword);
        const sjB = await connect('SJ_SERVER', 'SJ_PORT', 'admin_sj', adminSjPassword);
        const li = await connect('LI_SERVER', 'LI_PORT', 'admin_limon', adminLimonPassword);
        const operatorCorp = await connect(
            'CORP_SERVER', 'CORP_PORT', operatorUser, operatorPassword
        );
        const operatorSj = await connect('SJ_SERVER', 'SJ_PORT', operatorUser, operatorPassword);
        const operatorLi = await connect('LI_SERVER', 'LI_PORT', operatorUser, operatorPassword);

        pools.push(corpSj, corpLi, sjA, sjB, li, operatorCorp, operatorSj, operatorLi);

        const customerCatalogs = await execute(
            corpSj, 'dbo.usp_Clientes_ObtenerCatalogosEdicion'
        );
        const cities = await execute(corpSj, 'dbo.usp_Ciudades_Buscar');
        const customerData = {
            CustomerName: `P2_DEMO_Cliente_${stamp}`,
            CustomerCategoryID: customerCatalogs.recordsets[0][0].Value,
            PrimaryContactPersonID: customerCatalogs.recordsets[2][0].Value,
            DeliveryMethodID: customerCatalogs.recordsets[3][0].Value,
            DeliveryCityID: cities.recordset[0].Value,
            PostalCityID: cities.recordset[0].Value,
            AccountOpenedDate: new Date('2026-11-05'),
            StandardDiscountPercentage: 0,
            IsStatementSent: false,
            IsOnCreditHold: false,
            PaymentDays: 7,
            PhoneNumber: '2222-0001',
            FaxNumber: '2222-0002',
            WebsiteURL: 'https://cliente.demo.local',
            DeliveryAddressLine1: 'Direccion de prueba',
            DeliveryPostalCode: '10101',
            PostalAddressLine1: 'Apartado de prueba',
            PostalPostalCode: '10101',
            BillToCustomerID: null,
            BuyingGroupID: customerCatalogs.recordsets[1][0]?.Value || null,
            AlternateContactPersonID: customerCatalogs.recordsets[2][1]?.Value || null,
            CreditLimit: 1000,
            DeliveryRun: null,
            RunPosition: null,
            DeliveryAddressLine2: null,
            DeliveryLatitude: null,
            DeliveryLongitude: null,
            PostalAddressLine2: null
        };

        const createdCustomer = await execute(
            corpSj, 'dbo.usp_Clientes_Crear', customerInputs(customerData)
        );
        customerData.CustomerID = createdCustomer.recordset[0].CustomerID;
        customerData.BillToCustomerID = customerData.CustomerID;
        customerData.PhoneNumber = '2222-0099';

        await execute(
            corpLi, 'dbo.usp_Clientes_Actualizar', customerInputs(customerData, 1)
        );
        await expectSqlError(
            () => execute(corpSj, 'dbo.usp_Clientes_Actualizar', customerInputs(customerData, 1)),
            50401,
            'Version obsoleta de cliente'
        );
        await execute(corpSj, 'dbo.usp_Clientes_Eliminar', [
            ['CustomerID', sql.Int, customerData.CustomerID],
            ['VersionEsperada', sql.Int, 2]
        ]);

        const supplierCatalogs = await execute(
            corpSj, 'dbo.usp_Proveedores_ObtenerCatalogosEdicion'
        );
        const supplierData = {
            SupplierName: `P2_DEMO_Proveedor_${stamp}`,
            SupplierCategoryID: supplierCatalogs.recordsets[0][0].Value,
            PrimaryContactPersonID: supplierCatalogs.recordsets[1][0].Value,
            AlternateContactPersonID: supplierCatalogs.recordsets[1][1].Value,
            DeliveryCityID: cities.recordset[0].Value,
            PostalCityID: cities.recordset[0].Value,
            PaymentDays: 7,
            PhoneNumber: '2222-1001',
            FaxNumber: '2222-1002',
            WebsiteURL: 'https://proveedor.demo.local',
            DeliveryAddressLine1: 'Direccion de prueba',
            DeliveryPostalCode: '10101',
            PostalAddressLine1: 'Apartado de prueba',
            PostalPostalCode: '10101',
            DeliveryMethodID: supplierCatalogs.recordsets[2][0].Value,
            SupplierReference: 'P2-DEMO',
            BankAccountName: 'Cuenta demo',
            BankAccountBranch: 'Sucursal demo',
            BankAccountCode: null,
            BankAccountNumber: null,
            BankInternationalCode: null,
            InternalComments: 'Dato privado de prueba',
            DeliveryAddressLine2: null,
            DeliveryLatitude: null,
            DeliveryLongitude: null,
            PostalAddressLine2: null
        };

        const createdSupplier = await execute(
            corpSj, 'dbo.usp_Proveedores_Crear', supplierInputs(supplierData)
        );
        supplierData.SupplierID = createdSupplier.recordset[0].SupplierID;
        supplierData.PhoneNumber = '2222-1099';

        await execute(
            corpLi, 'dbo.usp_Proveedores_Actualizar', supplierInputs(supplierData, 1)
        );
        await expectSqlError(
            () => execute(
                corpSj, 'dbo.usp_Proveedores_Actualizar', supplierInputs(supplierData, 1)
            ),
            50401,
            'Version obsoleta de proveedor'
        );
        await execute(corpSj, 'dbo.usp_Proveedores_Eliminar', [
            ['SupplierID', sql.Int, supplierData.SupplierID],
            ['VersionEsperada', sql.Int, 2]
        ]);

        const inventoryCatalogs = await execute(
            corpSj, 'dbo.usp_Inventarios_ObtenerCatalogosEdicion'
        );
        const productData = {
            StockItemName: `P2_DEMO_Producto_${stamp}`,
            SupplierID: inventoryCatalogs.recordsets[0][0].Value,
            UnitPackageID: inventoryCatalogs.recordsets[3][0].Value,
            OuterPackageID: inventoryCatalogs.recordsets[3][0].Value,
            LeadTimeDays: 1,
            QuantityPerOuter: 1,
            IsChillerStock: false,
            TaxRate: 13,
            UnitPrice: 10,
            TypicalWeightPerUnit: 1,
            ColorID: inventoryCatalogs.recordsets[2][0]?.Value || null,
            Brand: 'P2 DEMO',
            Size: 'M',
            Barcode: null,
            RecommendedRetailPrice: 12,
            MarketingComments: 'Producto de prueba del hito',
            InternalComments: null,
            Photo: null,
            CustomFields: null,
            StockGroupID: inventoryCatalogs.recordsets[1][0].Value
        };

        const createdProduct = await execute(
            corpSj, 'dbo.usp_Inventarios_Crear', productInputs(productData)
        );
        productData.StockItemID = createdProduct.recordset[0].StockItemID;

        await waitFor(async () => {
            const [sjResult, liResult] = await Promise.all([
                operatorSj.request()
                    .input('id', sql.Int, productData.StockItemID)
                    .query('SELECT VersionCatalogo FROM Warehouse.StockItems WHERE StockItemID = @id;'),
                operatorLi.request()
                    .input('id', sql.Int, productData.StockItemID)
                    .query('SELECT VersionCatalogo FROM Warehouse.StockItems WHERE StockItemID = @id;')
            ]);
            return sjResult.recordset[0]?.VersionCatalogo === 1
                && liResult.recordset[0]?.VersionCatalogo === 1;
        }, 'el producto en las dos sucursales');

        const productA = { ...productData, UnitPrice: 12.5 };
        const productB = { ...productData, UnitPrice: 13.5 };
        const productRace = await Promise.allSettled([
            execute(corpSj, 'dbo.usp_Inventarios_Actualizar', productInputs(productA, 1)),
            execute(corpLi, 'dbo.usp_Inventarios_Actualizar', productInputs(productB, 1))
        ]);

        const productSuccesses = productRace.filter((result) => result.status === 'fulfilled');
        const productConflicts = productRace.filter((result) =>
            result.status === 'rejected' && getErrorNumber(result.reason) === 50401
        );

        if (productSuccesses.length !== 1 || productConflicts.length !== 1) {
            throw new Error('La concurrencia de catalogo no produjo un exito y un conflicto');
        }

        await waitFor(async () => {
            const result = await operatorSj.request()
                .input('id', sql.Int, productData.StockItemID)
                .query('SELECT VersionCatalogo FROM Warehouse.StockItems WHERE StockItemID = @id;');
            return result.recordset[0]?.VersionCatalogo === 2;
        }, 'la version 2 del producto en San Jose');

        const holdingsInputs = (quantity) => [
            ['StockItemID', sql.Int, productData.StockItemID],
            ['QuantityOnHand', sql.Int, quantity],
            ['BinLocation', sql.NVarChar(20), 'P2-DEMO'],
            ['LastStocktakeQuantity', sql.Int, quantity],
            ['LastCostPrice', sql.Decimal(18, 2), 5],
            ['ReorderLevel', sql.Int, 2],
            ['TargetStockLevel', sql.Int, 20],
            ['VersionEsperada', sql.Int, 0]
        ];

        const holdingsRace = await Promise.allSettled([
            execute(sjA, 'dbo.usp_Inventarios_GuardarExistencias', holdingsInputs(10)),
            execute(sjB, 'dbo.usp_Inventarios_GuardarExistencias', holdingsInputs(20))
        ]);

        const holdingsSuccesses = holdingsRace.filter((result) => result.status === 'fulfilled');
        const holdingsConflicts = holdingsRace.filter((result) =>
            result.status === 'rejected' && getErrorNumber(result.reason) === 50401
        );

        if (holdingsSuccesses.length !== 1 || holdingsConflicts.length !== 1) {
            throw new Error('La primera existencia no produjo un exito y un conflicto');
        }

        await execute(li, 'dbo.usp_Inventarios_GuardarExistencias', holdingsInputs(30));

        const saleCatalogs = await execute(sjA, 'dbo.usp_Ventas_ObtenerCatalogos');
        const customer = saleCatalogs.recordsets[0][0];
        const person = saleCatalogs.recordsets[1][0];
        const delivery = saleCatalogs.recordsets[2][0];
        const saleData = {
            CustomerID: customer.Value,
            BillToCustomerID: customer.Value,
            DeliveryMethodID: delivery.Value,
            ContactPersonID: person.Value,
            AccountsPersonID: person.Value,
            SalespersonPersonID: person.Value,
            PackedByPersonID: person.Value,
            InvoiceDate: new Date('2026-11-05'),
            CustomerPurchaseOrderNumber: `P2-${stamp.slice(-8)}`,
            Comments: `P2_DEMO_Venta_${stamp}`,
            Lines: [{
                StockItemID: productData.StockItemID,
                Quantity: 1,
                UnitPrice: 12.5,
                TaxRate: 13
            }]
        };

        const invalidSale = { ...saleData, Comments: `P2_DEMO_INVALIDA_${stamp}` };
        invalidSale.Lines = [{ ...saleData.Lines[0], Quantity: -1 }];
        await expectSqlError(
            () => execute(sjA, 'dbo.usp_Ventas_Crear', saleInputs(invalidSale)),
            50304,
            'Rollback de venta invalida'
        );

        const invalidCount = await operatorSj.request()
            .input('comment', sql.NVarChar(sql.MAX), invalidSale.Comments)
            .query('SELECT COUNT(*) AS Total FROM Sales.Invoices WHERE Comments = @comment;');

        if (invalidCount.recordset[0].Total !== 0) {
            throw new Error('La venta invalida dejo una cabecera parcial');
        }

        const createdSale = await execute(sjA, 'dbo.usp_Ventas_Crear', saleInputs(saleData));
        saleData.InvoiceID = createdSale.recordset[0].InvoiceID;

        await waitFor(async () => {
            const result = await operatorCorp.request()
                .input('id', sql.Int, saleData.InvoiceID)
                .query('SELECT VersionVenta FROM sj.Invoices WHERE InvoiceID = @id;');
            return result.recordset[0]?.VersionVenta === 1;
        }, 'la venta de San Jose en Corporativo');

        saleData.Lines = [{ ...saleData.Lines[0], Quantity: 2 }];
        await execute(sjA, 'dbo.usp_Ventas_Actualizar', saleInputs(saleData, 1));
        await expectSqlError(
            () => execute(sjB, 'dbo.usp_Ventas_Actualizar', saleInputs(saleData, 1)),
            50401,
            'Version obsoleta de venta'
        );

        await waitFor(async () => {
            const result = await operatorCorp.request()
                .input('id', sql.Int, saleData.InvoiceID)
                .query('SELECT VersionVenta FROM sj.Invoices WHERE InvoiceID = @id;');
            return result.recordset[0]?.VersionVenta === 2;
        }, 'la actualizacion de venta en Corporativo');

        await execute(sjA, 'dbo.usp_Ventas_Eliminar', [
            ['InvoiceID', sql.Int, saleData.InvoiceID],
            ['VersionEsperada', sql.Int, 2]
        ]);

        await waitFor(async () => {
            const result = await operatorCorp.request()
                .input('id', sql.Int, saleData.InvoiceID)
                .query('SELECT COUNT(*) AS Total FROM sj.Invoices WHERE InvoiceID = @id;');
            return result.recordset[0].Total === 0;
        }, 'la baja de venta en Corporativo');

        await execute(corpSj, 'dbo.usp_Inventarios_Eliminar', [
            ['StockItemID', sql.Int, productData.StockItemID],
            ['VersionEsperada', sql.Int, 2]
        ]);

        await waitFor(async () => {
            const [sjResult, liResult] = await Promise.all([
                operatorSj.request()
                    .input('id', sql.Int, productData.StockItemID)
                    .query('SELECT Activo, VersionCatalogo FROM Warehouse.StockItems WHERE StockItemID = @id;'),
                operatorLi.request()
                    .input('id', sql.Int, productData.StockItemID)
                    .query('SELECT Activo, VersionCatalogo FROM Warehouse.StockItems WHERE StockItemID = @id;')
            ]);
            return sjResult.recordset[0]?.Activo === false
                && sjResult.recordset[0]?.VersionCatalogo === 3
                && liResult.recordset[0]?.Activo === false
                && liResult.recordset[0]?.VersionCatalogo === 3;
        }, 'la baja logica del producto');

        const localHoldings = await Promise.all([
            operatorSj.request()
                .input('id', sql.Int, productData.StockItemID)
                .query('SELECT QuantityOnHand FROM Warehouse.StockItemHoldings WHERE StockItemID = @id;'),
            operatorLi.request()
                .input('id', sql.Int, productData.StockItemID)
                .query('SELECT QuantityOnHand FROM Warehouse.StockItemHoldings WHERE StockItemID = @id;')
        ]);

        if (localHoldings[0].recordset[0].QuantityOnHand
            === localHoldings[1].recordset[0].QuantityOnHand) {
            throw new Error('Las existencias de ambas sucursales quedaron iguales');
        }

        console.log('PASS: cliente y proveedor escriben fragmentos publicos/privados con version');
        console.log('PASS: una de dos ediciones simultaneas de producto recibio conflicto');
        console.log('PASS: una de dos altas simultaneas de existencias recibio conflicto');
        console.log('PASS: venta local creo, replico, actualizo, rechazo version vieja y elimino');
        console.log('PASS: venta invalida hizo rollback completo');
        console.log(`EVIDENCIA: CustomerID=${customerData.CustomerID}, SupplierID=${supplierData.SupplierID}, StockItemID=${productData.StockItemID}, InvoiceID=${saleData.InvoiceID}`);
    } finally {
        for (const pool of pools.reverse()) {
            await pool.close().catch(() => {});
        }
    }
}

main().catch((error) => {
    console.error(`FAIL: ${error.message}`);
    process.exitCode = 1;
});

