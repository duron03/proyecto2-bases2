import { config } from 'dotenv';
import sql from 'mssql';

config();

function required(name) {
    if (!process.env[name]) {
        throw new Error(`Falta ${name} en proyecto2/.env`);
    }

    return process.env[name];
}

function settings(user, password) {
    return {
        server: required('CORP_SERVER'),
        port: Number(required('CORP_PORT')),
        database: process.env.DB_DATABASE || 'WideWorldImporters',
        user,
        password,
        requestTimeout: 120000,
        options: {
            encrypt: process.env.DB_ENCRYPT !== 'false',
            trustServerCertificate: process.env.DB_TRUST_SERVER_CERTIFICATE !== 'false'
        }
    };
}

function closeEnough(first, second) {
    return Math.abs(Number(first) - Number(second)) < 0.01;
}

function sum(rows, column) {
    return rows.reduce((total, row) => total + Number(row[column] || 0), 0);
}

async function main() {
    const operator = new sql.ConnectionPool(
        settings(required('OPERATOR_USER'), required('OPERATOR_PASSWORD'))
    );
    const corporate = new sql.ConnectionPool(
        settings('corporativo', required('CORPORATIVO_PASSWORD'))
    );

    try {
        await operator.connect();
        await corporate.connect();

        const supplierExpected = await operator.request().query(`
            SELECT TOP (1)
                S.SupplierName,
                SC.SupplierCategoryName,
                MAX(ST.TransactionAmount) AS MaxValue,
                MIN(ST.TransactionAmount) AS MinValue,
                AVG(ST.TransactionAmount) AS AvgValue
            FROM Corporativo.v_PurchaseOrders AS PO
            INNER JOIN Corporativo.v_SupplierTransactions AS ST
                ON PO.SucursalID = ST.SucursalID
               AND PO.PurchaseOrderID = ST.PurchaseOrderID
            INNER JOIN Purchasing.Suppliers AS S ON PO.SupplierID = S.SupplierID
            INNER JOIN Purchasing.SupplierCategories AS SC
                ON S.SupplierCategoryID = SC.SupplierCategoryID
            GROUP BY S.SupplierName, SC.SupplierCategoryName
            ORDER BY COUNT_BIG(*) DESC;
        `);
        const supplier = supplierExpected.recordset[0];
        const report1 = await corporate.request()
            .input('SupplierName', sql.NVarChar(100), supplier.SupplierName)
            .input('SupplierCategoryName', sql.NVarChar(50), supplier.SupplierCategoryName)
            .input('SucursalID', sql.Int, null)
            .execute('dbo.usp_Estadisticas_Reporte1');
        const supplierRow = report1.recordset.find((row) =>
            row.SupplierName === supplier.SupplierName
            && row.SupplierCategoryName === supplier.SupplierCategoryName
        );

        if (!supplierRow
            || !closeEnough(supplierRow.MaxSupplierPurchase, supplier.MaxValue)
            || !closeEnough(supplierRow.MinSupplierPurchase, supplier.MinValue)
            || !closeEnough(supplierRow.AvgSupplierPurchase, supplier.AvgValue)) {
            throw new Error('El reporte 1 no coincide con las transacciones base');
        }

        const customerExpected = await operator.request().query(`
            SELECT TOP (1)
                C.CustomerName,
                CC.CustomerCategoryName,
                MAX(CT.TransactionAmount) AS MaxValue,
                MIN(CT.TransactionAmount) AS MinValue,
                AVG(CT.TransactionAmount) AS AvgValue
            FROM Corporativo.v_Invoices AS I
            INNER JOIN Corporativo.v_CustomerTransactions AS CT
                ON I.SucursalID = CT.SucursalID
               AND I.InvoiceID = CT.InvoiceID
            INNER JOIN Sales.Customers AS C ON I.CustomerID = C.CustomerID
            INNER JOIN Sales.CustomerCategories AS CC
                ON C.CustomerCategoryID = CC.CustomerCategoryID
            GROUP BY C.CustomerName, CC.CustomerCategoryName
            ORDER BY COUNT_BIG(*) DESC;
        `);
        const customer = customerExpected.recordset[0];
        const report2 = await corporate.request()
            .input('CustomerName', sql.NVarChar(100), customer.CustomerName)
            .input('CustomerCategoryName', sql.NVarChar(50), customer.CustomerCategoryName)
            .input('SucursalID', sql.Int, null)
            .execute('dbo.usp_Estadisticas_Reporte2');
        const customerRow = report2.recordset.find((row) =>
            row.CustomerName === customer.CustomerName
            && row.CustomerCategoryName === customer.CustomerCategoryName
        );

        if (!customerRow
            || !closeEnough(customerRow.MaxAmount, customer.MaxValue)
            || !closeEnough(customerRow.MinAmount, customer.MinValue)
            || !closeEnough(customerRow.AvgPurchase, customer.AvgValue)) {
            throw new Error('El reporte 2 no coincide con las transacciones base');
        }

        const customerYearExpected = await operator.request().query(`
            SELECT TOP (1)
                C.CustomerName,
                YEAR(I.InvoiceDate) AS InvoiceYear,
                COUNT_BIG(*) AS InvoiceCount,
                SUM(T.Amount) AS TotalAmount
            FROM Corporativo.v_Invoices AS I
            INNER JOIN Sales.Customers AS C ON I.CustomerID = C.CustomerID
            INNER JOIN
            (
                SELECT SucursalID, InvoiceID, SUM(ExtendedPrice) AS Amount
                FROM Corporativo.v_InvoiceLines
                GROUP BY SucursalID, InvoiceID
            ) AS T
                ON I.SucursalID = T.SucursalID AND I.InvoiceID = T.InvoiceID
            GROUP BY C.CustomerName, YEAR(I.InvoiceDate)
            ORDER BY COUNT_BIG(*) DESC;
        `);
        const customerYear = customerYearExpected.recordset[0];
        const report4 = await corporate.request()
            .input('Year', sql.Int, customerYear.InvoiceYear)
            .input('CustomerName', sql.NVarChar(100), customerYear.CustomerName)
            .input('SucursalID', sql.Int, null)
            .execute('dbo.usp_Estadisticas_Reporte4');
        const report4Row = report4.recordset[0];

        if (Number(report4Row.InvoiceCount) !== Number(customerYear.InvoiceCount)
            || !closeEnough(report4Row.TotalAmount, customerYear.TotalAmount)) {
            throw new Error('El reporte 4 conto lineas como facturas');
        }

        const totalsExpected = await operator.request().query(`
            SELECT
                (SELECT SUM(ExtendedPrice) FROM Corporativo.v_InvoiceLines) AS SalesTotal,
                (SELECT SUM(OrderedOuters * ExpectedUnitPricePerOuter)
                 FROM Corporativo.v_PurchaseOrderLines) AS PurchaseTotal,
                (SELECT COUNT_BIG(*) FROM Corporativo.v_Invoices) AS InvoiceCount;
        `);
        const totals = totalsExpected.recordset[0];
        const report7 = await corporate.request()
            .input('SucursalID', sql.Int, null)
            .execute('dbo.usp_Estadisticas_Reporte7');
        const report8 = await corporate.request()
            .input('SucursalID', sql.Int, null)
            .execute('dbo.usp_Estadisticas_Reporte8');
        const report10 = await corporate.request()
            .input('SucursalID', sql.Int, null)
            .execute('dbo.usp_Estadisticas_Reporte10');

        if (!closeEnough(sum(report7.recordset, 'TotalPurchasedAmount'), totals.SalesTotal)) {
            throw new Error('El reporte 7 multiplico ventas por grupos de producto');
        }

        if (!closeEnough(sum(report8.recordset, 'TotalPurchasedAmount'), totals.PurchaseTotal)) {
            throw new Error('El reporte 8 multiplico compras por grupos de producto');
        }

        if (sum(report10.recordset, 'SalesCount') !== Number(totals.InvoiceCount)) {
            throw new Error('El reporte 10 no conto facturas distintas correctamente');
        }

        console.log('PASS: reportes 1 y 2 usan filas base, no promedios por sucursal');
        console.log('PASS: reporte 4 cuenta facturas distintas y conserva montos');
        console.log('PASS: reportes 7 y 8 no multiplican importes por grupos');
        console.log('PASS: reporte 10 cuenta cada factura una sola vez sin filtros');
    } finally {
        await corporate.close().catch(() => {});
        await operator.close().catch(() => {});
    }
}

main().catch((error) => {
    console.error(`FAIL: ${error.message}`);
    process.exitCode = 1;
});

