import { getConnection, sql } from '../database/connection.js';

function getDatabaseErrorNumber(error) {
    if (error.number) {
        return error.number;
    }

    if (error.originalError && error.originalError.info) {
        return error.originalError.info.number;
    }

    return null;
}

function sendDatabaseError(res, error) {
    const errorNumber = getDatabaseErrorNumber(error);

    if (errorNumber === 50001) {
        return res.status(400).json({ error: error.message });
    }

    if (errorNumber === 50002) {
        return res.status(404).json({ error: error.message });
    }

    if (errorNumber === 50101) {
        return res.status(400).json({ error: error.message });
    }

    if (errorNumber === 50102) {
        return res.status(404).json({ error: error.message });
    }

    if (errorNumber === 50201) {
        return res.status(404).json({ error: error.message });
    }

    if (errorNumber === 50202) {
        return res.status(409).json({ error: error.message });
    }

    if (errorNumber === 50203) {
        return res.status(400).json({ error: error.message });
    }

    if (errorNumber === 50301) {
        return res.status(404).json({ error: error.message });
    }

    if (errorNumber === 50302) {
        return res.status(404).json({ error: error.message });
    }

    if (errorNumber === 50303 || errorNumber === 50304) {
        return res.status(400).json({ error: error.message });
    }

    if (errorNumber === 547) {
        return res.status(409).json({
            error: 'No se puede realizar la operación porque existen registros relacionados.'
        });
    }

    if (errorNumber === 2601 || errorNumber === 2627) {
        return res.status(409).json({ error: 'Ya existe un registro con esos datos.' });
    }

    return res.status(500).json({ error: error.message });
}

// ==================== Peticiones GET ==================== //

// Estado de la API.
export const getApiHealth = async (req, res) => {
    try {
        await getConnection();
        res.json({ message: 'API y base de datos disponibles' });

    } catch (error) {
        console.error('Error:', error);
        sendDatabaseError(res, error);
    }
};

// Clientes.
export const getCustomers = async (req, res) => {
    try {
        const CustomerName = req.query.CustomerName || null;
        const CustomerCategoryID = req.query.CustomerCategoryID || null;
        const DeliveryMethodID = req.query.DeliveryMethodID || null;

        const pool = await getConnection();

        const result = await pool.request()
        .input('CustomerName', sql.NVarChar(100), CustomerName)
        .input('CustomerCategoryID', sql.Int, CustomerCategoryID)
        .input('DeliveryMethodID', sql.Int, DeliveryMethodID)
        .execute('dbo.usp_Clientes_Listar');

        res.json(result.recordset);

    } catch (error) {
        console.error('Error:', error);
        sendDatabaseError(res, error);
    }
};

export const getCustomerCatalogs = async (req, res) => {
    try {
        const pool = await getConnection();

        const result = await pool.request()
        .execute('dbo.usp_Clientes_ObtenerCatalogos');

        res.json({
            customerCategories: result.recordsets[0],
            buyingGroups: result.recordsets[1],
            people: result.recordsets[2],
            deliveryMethods: result.recordsets[3],
            customers: result.recordsets[4]
        });

    } catch (error) {
        console.error('Error:', error);
        sendDatabaseError(res, error);
    }
};

export const getCities = async (req, res) => {
    try {
        const CityName = req.query.name || null;
        const CityID = req.query.id || null;

        const pool = await getConnection();

        const result = await pool.request()
        .input('CityName', sql.NVarChar(50), CityName)
        .input('CityID', sql.Int, CityID)
        .execute('dbo.usp_Ciudades_Buscar');

        res.json(result.recordset);

    } catch (error) {
        console.error('Error:', error);
        sendDatabaseError(res, error);
    }
};

export const getCustomerDetails = async (req, res) => {
    try {
        const { CustomerID } = req.params;

        const pool = await getConnection();

        const result = await pool.request()
        .input('CustomerID', sql.Int, CustomerID)
        .execute('dbo.usp_Clientes_ObtenerDetalle');

        const customer = result.recordset[0];

        if (!customer) {
            return res.status(404).json({ error: 'El cliente no existe.' });
        }

        res.json(customer);

    } catch (error) {
        console.error('Error:', error);
        sendDatabaseError(res, error);
    }
};

// Inventarios.
export const getInventories = async (req, res) => {
    try {
        const StockItemName = req.query.StockItemName || null;
        const StockGroupID = req.query.StockGroupID || null;
        const MinimumQuantityOnHand = req.query.MinimumQuantityOnHand || null;
        const MaximumQuantityOnHand = req.query.MaximumQuantityOnHand || null;

        const pool = await getConnection();

        const result = await pool.request()
        .input('StockItemName', sql.NVarChar(100), StockItemName)
        .input('StockGroupID', sql.Int, StockGroupID)
        .input('MinimumQuantityOnHand', sql.Int, MinimumQuantityOnHand)
        .input('MaximumQuantityOnHand', sql.Int, MaximumQuantityOnHand)
        .execute('dbo.usp_Inventarios_Listar');

        res.json(result.recordset);

    } catch (error) {
        console.error('Error:', error);
        sendDatabaseError(res, error);
    }
};

export const getInventoryCatalogs = async (req, res) => {
    try {
        const pool = await getConnection();

        const result = await pool.request()
        .execute('dbo.usp_Inventarios_ObtenerCatalogos');

        res.json({
            suppliers: result.recordsets[0],
            stockGroups: result.recordsets[1],
            colors: result.recordsets[2],
            packageTypes: result.recordsets[3]
        });

    } catch (error) {
        console.error('Error:', error);
        sendDatabaseError(res, error);
    }
};

export const getInventoryDetails = async (req, res) => {
    try {
        const { StockItemID } = req.params;

        const pool = await getConnection();

        const result = await pool.request()
        .input('StockItemID', sql.Int, StockItemID)
        .execute('dbo.usp_Inventarios_ObtenerDetalle');

        const inventory = result.recordset[0];

        if (!inventory) {
            return res.status(404).json({ error: 'El producto no existe.' });
        }

        res.json(inventory);

    } catch (error) {
        console.error('Error:', error);
        sendDatabaseError(res, error);
    }
};

// Proveedores.
export const getSuppliers = async (req, res) => {
    try {
        const SupplierName = req.query.SupplierName || null;
        const SupplierCategoryID = req.query.SupplierCategoryID || null;
        const DeliveryMethodID = req.query.DeliveryMethodID || null;

        const pool = await getConnection();

        const result = await pool.request()
        .input('SupplierName', sql.NVarChar(100), SupplierName)
        .input('SupplierCategoryID', sql.Int, SupplierCategoryID)
        .input('DeliveryMethodID', sql.Int, DeliveryMethodID)
        .execute('dbo.usp_Proveedores_Listar');

        res.json(result.recordset);

    } catch (error) {
        console.error('Error:', error);
        sendDatabaseError(res, error);
    }
};

export const getSupplierCatalogs = async (req, res) => {
    try {
        const pool = await getConnection();

        const result = await pool.request()
        .execute('dbo.usp_Proveedores_ObtenerCatalogos');

        res.json({
            supplierCategories: result.recordsets[0],
            people: result.recordsets[1],
            deliveryMethods: result.recordsets[2]
        });

    } catch (error) {
        console.error('Error:', error);
        sendDatabaseError(res, error);
    }
};

export const getSupplierDetails = async (req, res) => {
    try {
        const { SupplierID } = req.params;

        const pool = await getConnection();

        const result = await pool.request()
        .input('SupplierID', sql.Int, SupplierID)
        .execute('dbo.usp_Proveedores_ObtenerDetalle');

        const supplier = result.recordset[0];

        if (!supplier) {
            return res.status(404).json({ error: 'El proveedor no existe.' });
        }

        res.json(supplier);

    } catch (error) {
        console.error('Error:', error);
        sendDatabaseError(res, error);
    }
};

// Ventas.
export const getInvoices = async (req, res) => {
    try {
        const CustomerName = req.query.CustomerName || null;
        const InvoiceDateFrom = req.query.InvoiceDateFrom || null;
        const InvoiceDateTo = req.query.InvoiceDateTo || null;
        const MinimumInvoiceAmount = req.query.MinimumInvoiceAmount || null;
        const MaximumInvoiceAmount = req.query.MaximumInvoiceAmount || null;
        const DeliveryMethodID = req.query.DeliveryMethodID || null;

        const pool = await getConnection();

        const result = await pool.request()
        .input('CustomerName', sql.NVarChar(100), CustomerName)
        .input('InvoiceDateFrom', sql.Date, InvoiceDateFrom)
        .input('InvoiceDateTo', sql.Date, InvoiceDateTo)
        .input('MinimumInvoiceAmount', sql.Decimal(18, 2), MinimumInvoiceAmount)
        .input('MaximumInvoiceAmount', sql.Decimal(18, 2), MaximumInvoiceAmount)
        .input('DeliveryMethodID', sql.Int, DeliveryMethodID)
        .execute('dbo.usp_Ventas_Listar');

        res.json(result.recordset);
        
    } catch (error) {
        console.error('Error:', error);
        sendDatabaseError(res, error);
    }
};

export const getSaleCatalogs = async (req, res) => {
    try {
        const pool = await getConnection();

        const result = await pool.request()
        .execute('dbo.usp_Ventas_ObtenerCatalogos');

        res.json({
            customers: result.recordsets[0],
            people: result.recordsets[1],
            deliveryMethods: result.recordsets[2],
            products: result.recordsets[3]
        });

    } catch (error) {
        console.error('Error:', error);
        sendDatabaseError(res, error);
    }
};

export const getInvoiceDetails = async (req, res) => {
    try {
        const { InvoiceID } = req.params;

        const pool = await getConnection();

        const result = await pool.request()
        .input('InvoiceID', sql.Int, InvoiceID)
        .execute('dbo.usp_Ventas_ObtenerDetalle');

        const invoice = result.recordsets[0][0];

        if (!invoice) {
            return res.status(404).json({ error: 'La venta no existe.' });
        }

        res.json({
            invoice: invoice,
            lines: result.recordsets[1]
        });

    } catch (error) {
        console.error('Error:', error);
        sendDatabaseError(res, error);
    }
};

//Reportes.
export const getReport1 = async (req, res) => {
    try {
        const SupplierName = req.query.SupplierName || null;
        const SupplierCategoryName = req.query.SupplierCategoryName || null;

        const pool = await getConnection();
        const result = await pool.request()
            .input('SupplierName', sql.NVarChar(100), SupplierName)
            .input('SupplierCategoryName', sql.NVarChar(50), SupplierCategoryName)
            .execute('dbo.usp_Estadisticas_Reporte1');

        res.json(result.recordset);
    } catch (error) {
        console.error('Error:', error);
        sendDatabaseError(res, error);
    }
};

export const getReport2 = async (req, res) => {
    try {
        const CustomerName = req.query.CustomerName || null;
        const CustomerCategoryName = req.query.CustomerCategoryName || null;

        const pool = await getConnection();
        const result = await pool.request()
            .input('CustomerName', sql.NVarChar(100), CustomerName)
            .input('CustomerCategoryName', sql.NVarChar(50), CustomerCategoryName)
            .execute('dbo.usp_Estadisticas_Reporte2');

        res.json(result.recordset);
    } catch (error) {
        console.error('Error:', error);
        sendDatabaseError(res, error);
    }
};

export const getReport3 = async (req, res) => {
    try {
        const Year = req.query.Year ? parseInt(req.query.Year) : null;
        const StockItemName = req.query.StockItemName || null;

        const pool = await getConnection();
        const result = await pool.request()
            .input('Year', sql.Int, Year)
            .input('StockItemName', sql.NVarChar(100), StockItemName)
            .execute('dbo.usp_Estadisticas_Reporte3');

        res.json(result.recordset);
    } catch (error) {
        console.error('Error:', error);
        sendDatabaseError(res, error);
    }
};

export const getReport4 = async (req, res) => {
    try {
        const Year = req.query.Year ? parseInt(req.query.Year) : null;
        const CustomerName = req.query.CustomerName || null;

        const pool = await getConnection();
        const result = await pool.request()
            .input('Year', sql.Int, Year)
            .input('CustomerName', sql.NVarChar(100), CustomerName)
            .execute('dbo.usp_Estadisticas_Reporte4');

        res.json(result.recordset);
    } catch (error) {
        console.error('Error:', error);
        sendDatabaseError(res, error);
    }
};

export const getReport5 = async (req, res) => {
    try {
        const Year = req.query.Year ? parseInt(req.query.Year) : null;
        const SupplierName = req.query.SupplierName || null;

        const pool = await getConnection();
        const result = await pool.request()
            .input('Year', sql.Int, Year)
            .input('SupplierName', sql.NVarChar(100), SupplierName)
            .execute('dbo.usp_Estadisticas_Reporte5');

        res.json(result.recordset);
    } catch (error) {
        console.error('Error:', error);
        sendDatabaseError(res, error);
    }
};

export const getReport6 = async (req, res) => {
    try {
        const StockGroupName = req.query.StockGroupName || null;

        const pool = await getConnection();
        const result = await pool.request()
            .input('StockGroupName', sql.NVarChar(100), StockGroupName)
            .execute('dbo.usp_Estadisticas_Reporte6');

        res.json(result.recordset);
    } catch (error) {
        console.error('Error:', error);
        sendDatabaseError(res, error);
    }
};

export const getReport7 = async (req, res) => {
    try {
        const Year = req.query.Year ? parseInt(req.query.Year) : null;
        const Month = req.query.Month ? parseInt(req.query.Month) : null;
        const StockGroupName = req.query.StockGroupName || null;

        const pool = await getConnection();
        const result = await pool.request()
            .input('Year', sql.Int, Year)
            .input('Month', sql.Int, Month)
            .input('StockGroupName', sql.NVarChar(100), StockGroupName)
            .execute('dbo.usp_Estadisticas_Reporte7');

        res.json(result.recordset);
    } catch (error) {
        console.error('Error:', error);
        sendDatabaseError(res, error);
    }
};

export const getReport8 = async (req, res) => {
    try {
        const Year = req.query.Year ? parseInt(req.query.Year) : null;
        const Month = req.query.Month ? parseInt(req.query.Month) : null;
        const StockGroupName = req.query.StockGroupName || null;

        const pool = await getConnection();
        const result = await pool.request()
            .input('Year', sql.Int, Year)
            .input('Month', sql.Int, Month)
            .input('StockGroupName', sql.NVarChar(100), StockGroupName)
            .execute('dbo.usp_Estadisticas_Reporte8');

        res.json(result.recordset);
    } catch (error) {
        console.error('Error:', error);
        sendDatabaseError(res, error);
    }
};

export const getReport9 = async (req, res) => {
    try {
        const StockGroupName = req.query.StockGroupName || null;
        const Year = req.query.Year ? parseInt(req.query.Year) : null;
        const SupplierName = req.query.SupplierName || null;

        const pool = await getConnection();
        const result = await pool.request()
            .input('StockGroupName', sql.NVarChar(100), StockGroupName)
            .input('Year', sql.Int, Year)
            .input('SupplierName', sql.NVarChar(100), SupplierName)
            .execute('dbo.usp_Estadisticas_Reporte9');

        res.json(result.recordset);
    } catch (error) {
        console.error('Error:', error);
        sendDatabaseError(res, error);
    }
};

export const getReport10 = async (req, res) => {
    try {
        const Year = req.query.Year ? parseInt(req.query.Year) : null;
        const Month = req.query.Month ? parseInt(req.query.Month) : null;
        const CustomerCategoryName = req.query.CustomerCategoryName || null;
        const StockGroupName = req.query.StockGroupName || null;
        const StockItemName = req.query.StockItemName || null;

        const pool = await getConnection();
        const result = await pool.request()
            .input('Year', sql.Int, Year)
            .input('Month', sql.Int, Month)
            .input('CustomerCategoryName', sql.NVarChar(50), CustomerCategoryName)
            .input('StockGroupName', sql.NVarChar(100), StockGroupName)
            .input('StockItemName', sql.NVarChar(100), StockItemName)
            .execute('dbo.usp_Estadisticas_Reporte10');

        res.json(result.recordset);
    } catch (error) {
        console.error('Error:', error);
        sendDatabaseError(res, error);
    }
};
// ======================================================== //

// ======================================================== //

// ==================== Peticiones POST ==================== //

// Clientes.
export const createCustomer = async (req, res) => {
    try {
        const { CustomerName } = req.body;
        const { CustomerCategoryID } = req.body;
        const { PrimaryContactPersonID } = req.body;
        const { DeliveryMethodID } = req.body;
        const { DeliveryCityID } = req.body;
        const { PostalCityID } = req.body;
        const { AccountOpenedDate } = req.body;
        const { StandardDiscountPercentage } = req.body;
        const { IsStatementSent } = req.body;
        const { IsOnCreditHold } = req.body;
        const { PaymentDays } = req.body;
        const { PhoneNumber } = req.body;
        const { FaxNumber } = req.body;
        const { WebsiteURL } = req.body;
        const { DeliveryAddressLine1 } = req.body;
        const { DeliveryPostalCode } = req.body;
        const { PostalAddressLine1 } = req.body;
        const { PostalPostalCode } = req.body;
        const { LastEditedBy } = req.body;
        const { BillToCustomerID } = req.body;
        const { BuyingGroupID } = req.body;
        const { AlternateContactPersonID } = req.body;
        const { CreditLimit } = req.body;
        const { DeliveryRun } = req.body;
        const { RunPosition } = req.body;
        const { DeliveryAddressLine2 } = req.body;
        const { DeliveryLatitude } = req.body;
        const { DeliveryLongitude } = req.body;
        const { PostalAddressLine2 } = req.body;

        const pool = await getConnection();

        const result = await pool.request()
        .input('CustomerName', sql.NVarChar(100), CustomerName)
        .input('CustomerCategoryID', sql.Int, CustomerCategoryID)
        .input('PrimaryContactPersonID', sql.Int, PrimaryContactPersonID)
        .input('DeliveryMethodID', sql.Int, DeliveryMethodID)
        .input('DeliveryCityID', sql.Int, DeliveryCityID)
        .input('PostalCityID', sql.Int, PostalCityID)
        .input('AccountOpenedDate', sql.Date, AccountOpenedDate)
        .input('StandardDiscountPercentage', sql.Decimal(18, 3), StandardDiscountPercentage)
        .input('IsStatementSent', sql.Bit, IsStatementSent)
        .input('IsOnCreditHold', sql.Bit, IsOnCreditHold)
        .input('PaymentDays', sql.Int, PaymentDays)
        .input('PhoneNumber', sql.NVarChar(20), PhoneNumber)
        .input('FaxNumber', sql.NVarChar(20), FaxNumber)
        .input('WebsiteURL', sql.NVarChar(256), WebsiteURL)
        .input('DeliveryAddressLine1', sql.NVarChar(60), DeliveryAddressLine1)
        .input('DeliveryPostalCode', sql.NVarChar(10), DeliveryPostalCode)
        .input('PostalAddressLine1', sql.NVarChar(60), PostalAddressLine1)
        .input('PostalPostalCode', sql.NVarChar(10), PostalPostalCode)
        .input('LastEditedBy', sql.Int, LastEditedBy)
        .input('BillToCustomerID', sql.Int, BillToCustomerID)
        .input('BuyingGroupID', sql.Int, BuyingGroupID)
        .input('AlternateContactPersonID', sql.Int, AlternateContactPersonID)
        .input('CreditLimit', sql.Decimal(18, 2), CreditLimit)
        .input('DeliveryRun', sql.NVarChar(5), DeliveryRun)
        .input('RunPosition', sql.NVarChar(5), RunPosition)
        .input('DeliveryAddressLine2', sql.NVarChar(60), DeliveryAddressLine2)
        .input('DeliveryLatitude', sql.Decimal(9, 6), DeliveryLatitude)
        .input('DeliveryLongitude', sql.Decimal(9, 6), DeliveryLongitude)
        .input('PostalAddressLine2', sql.NVarChar(60), PostalAddressLine2)
        .execute('dbo.usp_Clientes_Crear');

        res.status(201).json({
            message: 'Cliente creado correctamente',
            newId: result.recordset[0].CustomerID
        });

    } catch (error) {
        console.error('Error:', error);
        sendDatabaseError(res, error);
    }
};

// Inventarios.
export const createInventory = async (req, res) => {
    try {
        const { StockItemName } = req.body;
        const { SupplierID } = req.body;
        const { UnitPackageID } = req.body;
        const { OuterPackageID } = req.body;
        const { LeadTimeDays } = req.body;
        const { QuantityPerOuter } = req.body;
        const { IsChillerStock } = req.body;
        const { TaxRate } = req.body;
        const { UnitPrice } = req.body;
        const { TypicalWeightPerUnit } = req.body;
        const { QuantityOnHand } = req.body;
        const { BinLocation } = req.body;
        const { LastStocktakeQuantity } = req.body;
        const { LastCostPrice } = req.body;
        const { ReorderLevel } = req.body;
        const { TargetStockLevel } = req.body;
        const { LastEditedBy } = req.body;
        const { ColorID } = req.body;
        const { Brand } = req.body;
        const { Size } = req.body;
        const { Barcode } = req.body;
        const { RecommendedRetailPrice } = req.body;
        const { MarketingComments } = req.body;
        const { InternalComments } = req.body;
        const { Photo } = req.body;
        const { CustomFields } = req.body;
        const { StockGroupID } = req.body;

        let PhotoData = null;

        if (Photo) {
            PhotoData = Buffer.from(Photo, 'base64');
        }

        const pool = await getConnection();

        const result = await pool.request()
        .input('StockItemName', sql.NVarChar(100), StockItemName)
        .input('SupplierID', sql.Int, SupplierID)
        .input('UnitPackageID', sql.Int, UnitPackageID)
        .input('OuterPackageID', sql.Int, OuterPackageID)
        .input('LeadTimeDays', sql.Int, LeadTimeDays)
        .input('QuantityPerOuter', sql.Int, QuantityPerOuter)
        .input('IsChillerStock', sql.Bit, IsChillerStock)
        .input('TaxRate', sql.Decimal(18, 3), TaxRate)
        .input('UnitPrice', sql.Decimal(18, 2), UnitPrice)
        .input('TypicalWeightPerUnit', sql.Decimal(18, 3), TypicalWeightPerUnit)
        .input('QuantityOnHand', sql.Int, QuantityOnHand)
        .input('BinLocation', sql.NVarChar(20), BinLocation)
        .input('LastStocktakeQuantity', sql.Int, LastStocktakeQuantity)
        .input('LastCostPrice', sql.Decimal(18, 2), LastCostPrice)
        .input('ReorderLevel', sql.Int, ReorderLevel)
        .input('TargetStockLevel', sql.Int, TargetStockLevel)
        .input('LastEditedBy', sql.Int, LastEditedBy)
        .input('ColorID', sql.Int, ColorID)
        .input('Brand', sql.NVarChar(50), Brand)
        .input('Size', sql.NVarChar(20), Size)
        .input('Barcode', sql.NVarChar(50), Barcode)
        .input('RecommendedRetailPrice', sql.Decimal(18, 2), RecommendedRetailPrice)
        .input('MarketingComments', sql.NVarChar(sql.MAX), MarketingComments)
        .input('InternalComments', sql.NVarChar(sql.MAX), InternalComments)
        .input('Photo', sql.VarBinary(sql.MAX), PhotoData)
        .input('CustomFields', sql.NVarChar(sql.MAX), CustomFields)
        .input('StockGroupID', sql.Int, StockGroupID)
        .execute('dbo.usp_Inventarios_Crear');

        res.status(201).json({
            message: 'Producto creado correctamente',
            newId: result.recordset[0].StockItemID
        });

    } catch (error) {
        console.error('Error:', error);
        sendDatabaseError(res, error);
    }
};

// Proveedores.
export const createSupplier = async (req, res) => {
    try {
        const { SupplierName } = req.body;
        const { SupplierCategoryID } = req.body;
        const { PrimaryContactPersonID } = req.body;
        const { AlternateContactPersonID } = req.body;
        const { DeliveryCityID } = req.body;
        const { PostalCityID } = req.body;
        const { PaymentDays } = req.body;
        const { PhoneNumber } = req.body;
        const { FaxNumber } = req.body;
        const { WebsiteURL } = req.body;
        const { DeliveryAddressLine1 } = req.body;
        const { DeliveryPostalCode } = req.body;
        const { PostalAddressLine1 } = req.body;
        const { PostalPostalCode } = req.body;
        const { LastEditedBy } = req.body;
        const { DeliveryMethodID } = req.body;
        const { SupplierReference } = req.body;
        const { BankAccountName } = req.body;
        const { BankAccountBranch } = req.body;
        const { BankAccountCode } = req.body;
        const { BankAccountNumber } = req.body;
        const { BankInternationalCode } = req.body;
        const { InternalComments } = req.body;
        const { DeliveryAddressLine2 } = req.body;
        const { DeliveryLatitude } = req.body;
        const { DeliveryLongitude } = req.body;
        const { PostalAddressLine2 } = req.body;

        const pool = await getConnection();

        const result = await pool.request()
        .input('SupplierName', sql.NVarChar(100), SupplierName)
        .input('SupplierCategoryID', sql.Int, SupplierCategoryID)
        .input('PrimaryContactPersonID', sql.Int, PrimaryContactPersonID)
        .input('AlternateContactPersonID', sql.Int, AlternateContactPersonID)
        .input('DeliveryCityID', sql.Int, DeliveryCityID)
        .input('PostalCityID', sql.Int, PostalCityID)
        .input('PaymentDays', sql.Int, PaymentDays)
        .input('PhoneNumber', sql.NVarChar(20), PhoneNumber)
        .input('FaxNumber', sql.NVarChar(20), FaxNumber)
        .input('WebsiteURL', sql.NVarChar(256), WebsiteURL)
        .input('DeliveryAddressLine1', sql.NVarChar(60), DeliveryAddressLine1)
        .input('DeliveryPostalCode', sql.NVarChar(10), DeliveryPostalCode)
        .input('PostalAddressLine1', sql.NVarChar(60), PostalAddressLine1)
        .input('PostalPostalCode', sql.NVarChar(10), PostalPostalCode)
        .input('LastEditedBy', sql.Int, LastEditedBy)
        .input('DeliveryMethodID', sql.Int, DeliveryMethodID)
        .input('SupplierReference', sql.NVarChar(20), SupplierReference)
        .input('BankAccountName', sql.NVarChar(50), BankAccountName)
        .input('BankAccountBranch', sql.NVarChar(50), BankAccountBranch)
        .input('BankAccountCode', sql.NVarChar(20), BankAccountCode)
        .input('BankAccountNumber', sql.NVarChar(20), BankAccountNumber)
        .input('BankInternationalCode', sql.NVarChar(20), BankInternationalCode)
        .input('InternalComments', sql.NVarChar(sql.MAX), InternalComments)
        .input('DeliveryAddressLine2', sql.NVarChar(60), DeliveryAddressLine2)
        .input('DeliveryLatitude', sql.Decimal(9, 6), DeliveryLatitude)
        .input('DeliveryLongitude', sql.Decimal(9, 6), DeliveryLongitude)
        .input('PostalAddressLine2', sql.NVarChar(60), PostalAddressLine2)
        .execute('dbo.usp_Proveedores_Crear');

        res.status(201).json({
            message: 'Proveedor creado correctamente',
            newId: result.recordset[0].SupplierID
        });

    } catch (error) {
        console.error('Error:', error);
        sendDatabaseError(res, error);
    }
};

// Ventas.
export const createSale = async (req, res) => {
    try {
        const { CustomerID } = req.body;
        const { BillToCustomerID } = req.body;
        const { DeliveryMethodID } = req.body;
        const { ContactPersonID } = req.body;
        const { AccountsPersonID } = req.body;
        const { SalespersonPersonID } = req.body;
        const { PackedByPersonID } = req.body;
        const { InvoiceDate } = req.body;
        const { LastEditedBy } = req.body;
        const { OrderID } = req.body;
        const { CustomerPurchaseOrderNumber } = req.body;
        const { IsCreditNote } = req.body;
        const { CreditNoteReason } = req.body;
        const { Comments } = req.body;
        const { DeliveryInstructions } = req.body;
        const { InternalComments } = req.body;
        const { DeliveryRun } = req.body;
        const { RunPosition } = req.body;
        const { ReturnedDeliveryData } = req.body;
        const { Lines } = req.body;

        let IsCreditNoteValue = false;
        let InvoiceLines = '[]';

        if (IsCreditNote === true || IsCreditNote === 1) {
            IsCreditNoteValue = true;
        }

        if (Array.isArray(Lines)) {
            InvoiceLines = JSON.stringify(Lines);
        }

        const pool = await getConnection();

        const result = await pool.request()
        .input('CustomerID', sql.Int, CustomerID)
        .input('BillToCustomerID', sql.Int, BillToCustomerID)
        .input('DeliveryMethodID', sql.Int, DeliveryMethodID)
        .input('ContactPersonID', sql.Int, ContactPersonID)
        .input('AccountsPersonID', sql.Int, AccountsPersonID)
        .input('SalespersonPersonID', sql.Int, SalespersonPersonID)
        .input('PackedByPersonID', sql.Int, PackedByPersonID)
        .input('InvoiceDate', sql.Date, InvoiceDate)
        .input('LastEditedBy', sql.Int, LastEditedBy)
        .input('OrderID', sql.Int, OrderID)
        .input('CustomerPurchaseOrderNumber', sql.NVarChar(20), CustomerPurchaseOrderNumber)
        .input('IsCreditNote', sql.Bit, IsCreditNoteValue)
        .input('CreditNoteReason', sql.NVarChar(sql.MAX), CreditNoteReason)
        .input('Comments', sql.NVarChar(sql.MAX), Comments)
        .input('DeliveryInstructions', sql.NVarChar(sql.MAX), DeliveryInstructions)
        .input('InternalComments', sql.NVarChar(sql.MAX), InternalComments)
        .input('TotalDryItems', sql.Int, 0)
        .input('TotalChillerItems', sql.Int, 0)
        .input('DeliveryRun', sql.NVarChar(5), DeliveryRun)
        .input('RunPosition', sql.NVarChar(5), RunPosition)
        .input('ReturnedDeliveryData', sql.NVarChar(sql.MAX), ReturnedDeliveryData)
        .input('InvoiceLines', sql.NVarChar(sql.MAX), InvoiceLines)
        .execute('dbo.usp_Ventas_Crear');

        res.status(201).json({
            message: 'Venta creada correctamente',
            newId: result.recordset[0].InvoiceID
        });

    } catch (error) {
        console.error('Error:', error);
        sendDatabaseError(res, error);
    }
};

// ========================================================= //

// ==================== Peticiones PUT ==================== //

// Clientes.
export const updateCustomer = async (req, res) => {
    try {
        const { CustomerID } = req.params;
        const { CustomerName } = req.body;
        const { CustomerCategoryID } = req.body;
        const { PrimaryContactPersonID } = req.body;
        const { DeliveryMethodID } = req.body;
        const { DeliveryCityID } = req.body;
        const { PostalCityID } = req.body;
        const { AccountOpenedDate } = req.body;
        const { StandardDiscountPercentage } = req.body;
        const { IsStatementSent } = req.body;
        const { IsOnCreditHold } = req.body;
        const { PaymentDays } = req.body;
        const { PhoneNumber } = req.body;
        const { FaxNumber } = req.body;
        const { WebsiteURL } = req.body;
        const { DeliveryAddressLine1 } = req.body;
        const { DeliveryPostalCode } = req.body;
        const { PostalAddressLine1 } = req.body;
        const { PostalPostalCode } = req.body;
        const { LastEditedBy } = req.body;
        const { BillToCustomerID } = req.body;
        const { BuyingGroupID } = req.body;
        const { AlternateContactPersonID } = req.body;
        const { CreditLimit } = req.body;
        const { DeliveryRun } = req.body;
        const { RunPosition } = req.body;
        const { DeliveryAddressLine2 } = req.body;
        const { DeliveryLatitude } = req.body;
        const { DeliveryLongitude } = req.body;
        const { PostalAddressLine2 } = req.body;

        const pool = await getConnection();

        const result = await pool.request()
        .input('CustomerID', sql.Int, CustomerID)
        .input('CustomerName', sql.NVarChar(100), CustomerName)
        .input('CustomerCategoryID', sql.Int, CustomerCategoryID)
        .input('PrimaryContactPersonID', sql.Int, PrimaryContactPersonID)
        .input('DeliveryMethodID', sql.Int, DeliveryMethodID)
        .input('DeliveryCityID', sql.Int, DeliveryCityID)
        .input('PostalCityID', sql.Int, PostalCityID)
        .input('AccountOpenedDate', sql.Date, AccountOpenedDate)
        .input('StandardDiscountPercentage', sql.Decimal(18, 3), StandardDiscountPercentage)
        .input('IsStatementSent', sql.Bit, IsStatementSent)
        .input('IsOnCreditHold', sql.Bit, IsOnCreditHold)
        .input('PaymentDays', sql.Int, PaymentDays)
        .input('PhoneNumber', sql.NVarChar(20), PhoneNumber)
        .input('FaxNumber', sql.NVarChar(20), FaxNumber)
        .input('WebsiteURL', sql.NVarChar(256), WebsiteURL)
        .input('DeliveryAddressLine1', sql.NVarChar(60), DeliveryAddressLine1)
        .input('DeliveryPostalCode', sql.NVarChar(10), DeliveryPostalCode)
        .input('PostalAddressLine1', sql.NVarChar(60), PostalAddressLine1)
        .input('PostalPostalCode', sql.NVarChar(10), PostalPostalCode)
        .input('LastEditedBy', sql.Int, LastEditedBy)
        .input('BillToCustomerID', sql.Int, BillToCustomerID)
        .input('BuyingGroupID', sql.Int, BuyingGroupID)
        .input('AlternateContactPersonID', sql.Int, AlternateContactPersonID)
        .input('CreditLimit', sql.Decimal(18, 2), CreditLimit)
        .input('DeliveryRun', sql.NVarChar(5), DeliveryRun)
        .input('RunPosition', sql.NVarChar(5), RunPosition)
        .input('DeliveryAddressLine2', sql.NVarChar(60), DeliveryAddressLine2)
        .input('DeliveryLatitude', sql.Decimal(9, 6), DeliveryLatitude)
        .input('DeliveryLongitude', sql.Decimal(9, 6), DeliveryLongitude)
        .input('PostalAddressLine2', sql.NVarChar(60), PostalAddressLine2)
        .execute('dbo.usp_Clientes_Actualizar');

        res.json({
            message: 'Cliente actualizado correctamente',
            id: result.recordset[0].CustomerID
        });

    } catch (error) {
        console.error('Error:', error);
        sendDatabaseError(res, error);
    }
};

// Inventarios.
export const updateInventory = async (req, res) => {
    try {
        const { StockItemID } = req.params;
        const { StockItemName } = req.body;
        const { SupplierID } = req.body;
        const { UnitPackageID } = req.body;
        const { OuterPackageID } = req.body;
        const { LeadTimeDays } = req.body;
        const { QuantityPerOuter } = req.body;
        const { IsChillerStock } = req.body;
        const { TaxRate } = req.body;
        const { UnitPrice } = req.body;
        const { TypicalWeightPerUnit } = req.body;
        const { QuantityOnHand } = req.body;
        const { BinLocation } = req.body;
        const { LastStocktakeQuantity } = req.body;
        const { LastCostPrice } = req.body;
        const { ReorderLevel } = req.body;
        const { TargetStockLevel } = req.body;
        const { LastEditedBy } = req.body;
        const { ColorID } = req.body;
        const { Brand } = req.body;
        const { Size } = req.body;
        const { Barcode } = req.body;
        const { RecommendedRetailPrice } = req.body;
        const { MarketingComments } = req.body;
        const { InternalComments } = req.body;
        const { Photo } = req.body;
        const { CustomFields } = req.body;
        let PhotoData = null;

        if (Photo) {
            PhotoData = Buffer.from(Photo, 'base64');
        }

        const pool = await getConnection();

        const result = await pool.request()
        .input('StockItemID', sql.Int, StockItemID)
        .input('StockItemName', sql.NVarChar(100), StockItemName)
        .input('SupplierID', sql.Int, SupplierID)
        .input('UnitPackageID', sql.Int, UnitPackageID)
        .input('OuterPackageID', sql.Int, OuterPackageID)
        .input('LeadTimeDays', sql.Int, LeadTimeDays)
        .input('QuantityPerOuter', sql.Int, QuantityPerOuter)
        .input('IsChillerStock', sql.Bit, IsChillerStock)
        .input('TaxRate', sql.Decimal(18, 3), TaxRate)
        .input('UnitPrice', sql.Decimal(18, 2), UnitPrice)
        .input('TypicalWeightPerUnit', sql.Decimal(18, 3), TypicalWeightPerUnit)
        .input('QuantityOnHand', sql.Int, QuantityOnHand)
        .input('BinLocation', sql.NVarChar(20), BinLocation)
        .input('LastStocktakeQuantity', sql.Int, LastStocktakeQuantity)
        .input('LastCostPrice', sql.Decimal(18, 2), LastCostPrice)
        .input('ReorderLevel', sql.Int, ReorderLevel)
        .input('TargetStockLevel', sql.Int, TargetStockLevel)
        .input('LastEditedBy', sql.Int, LastEditedBy)
        .input('ColorID', sql.Int, ColorID)
        .input('Brand', sql.NVarChar(50), Brand)
        .input('Size', sql.NVarChar(20), Size)
        .input('Barcode', sql.NVarChar(50), Barcode)
        .input('RecommendedRetailPrice', sql.Decimal(18, 2), RecommendedRetailPrice)
        .input('MarketingComments', sql.NVarChar(sql.MAX), MarketingComments)
        .input('InternalComments', sql.NVarChar(sql.MAX), InternalComments)
        .input('Photo', sql.VarBinary(sql.MAX), PhotoData)
        .input('CustomFields', sql.NVarChar(sql.MAX), CustomFields)
        .execute('dbo.usp_Inventarios_Actualizar');

        res.json({
            message: 'Producto actualizado correctamente',
            id: result.recordset[0].StockItemID
        });

    } catch (error) {
        console.error('Error:', error);
        sendDatabaseError(res, error);
    }
};

// Proveedores.
export const updateSupplier = async (req, res) => {
    try {
        const { SupplierID } = req.params;
        const { SupplierName } = req.body;
        const { SupplierCategoryID } = req.body;
        const { PrimaryContactPersonID } = req.body;
        const { AlternateContactPersonID } = req.body;
        const { DeliveryCityID } = req.body;
        const { PostalCityID } = req.body;
        const { PaymentDays } = req.body;
        const { PhoneNumber } = req.body;
        const { FaxNumber } = req.body;
        const { WebsiteURL } = req.body;
        const { DeliveryAddressLine1 } = req.body;
        const { DeliveryPostalCode } = req.body;
        const { PostalAddressLine1 } = req.body;
        const { PostalPostalCode } = req.body;
        const { LastEditedBy } = req.body;
        const { DeliveryMethodID } = req.body;
        const { SupplierReference } = req.body;
        const { BankAccountName } = req.body;
        const { BankAccountBranch } = req.body;
        const { BankAccountCode } = req.body;
        const { BankAccountNumber } = req.body;
        const { BankInternationalCode } = req.body;
        const { InternalComments } = req.body;
        const { DeliveryAddressLine2 } = req.body;
        const { DeliveryLatitude } = req.body;
        const { DeliveryLongitude } = req.body;
        const { PostalAddressLine2 } = req.body;

        const pool = await getConnection();

        const result = await pool.request()
        .input('SupplierID', sql.Int, SupplierID)
        .input('SupplierName', sql.NVarChar(100), SupplierName)
        .input('SupplierCategoryID', sql.Int, SupplierCategoryID)
        .input('PrimaryContactPersonID', sql.Int, PrimaryContactPersonID)
        .input('AlternateContactPersonID', sql.Int, AlternateContactPersonID)
        .input('DeliveryCityID', sql.Int, DeliveryCityID)
        .input('PostalCityID', sql.Int, PostalCityID)
        .input('PaymentDays', sql.Int, PaymentDays)
        .input('PhoneNumber', sql.NVarChar(20), PhoneNumber)
        .input('FaxNumber', sql.NVarChar(20), FaxNumber)
        .input('WebsiteURL', sql.NVarChar(256), WebsiteURL)
        .input('DeliveryAddressLine1', sql.NVarChar(60), DeliveryAddressLine1)
        .input('DeliveryPostalCode', sql.NVarChar(10), DeliveryPostalCode)
        .input('PostalAddressLine1', sql.NVarChar(60), PostalAddressLine1)
        .input('PostalPostalCode', sql.NVarChar(10), PostalPostalCode)
        .input('LastEditedBy', sql.Int, LastEditedBy)
        .input('DeliveryMethodID', sql.Int, DeliveryMethodID)
        .input('SupplierReference', sql.NVarChar(20), SupplierReference)
        .input('BankAccountName', sql.NVarChar(50), BankAccountName)
        .input('BankAccountBranch', sql.NVarChar(50), BankAccountBranch)
        .input('BankAccountCode', sql.NVarChar(20), BankAccountCode)
        .input('BankAccountNumber', sql.NVarChar(20), BankAccountNumber)
        .input('BankInternationalCode', sql.NVarChar(20), BankInternationalCode)
        .input('InternalComments', sql.NVarChar(sql.MAX), InternalComments)
        .input('DeliveryAddressLine2', sql.NVarChar(60), DeliveryAddressLine2)
        .input('DeliveryLatitude', sql.Decimal(9, 6), DeliveryLatitude)
        .input('DeliveryLongitude', sql.Decimal(9, 6), DeliveryLongitude)
        .input('PostalAddressLine2', sql.NVarChar(60), PostalAddressLine2)
        .execute('dbo.usp_Proveedores_Actualizar');

        res.json({
            message: 'Proveedor actualizado correctamente',
            id: result.recordset[0].SupplierID
        });

    } catch (error) {
        console.error('Error:', error);
        sendDatabaseError(res, error);
    }
};

// Ventas.
export const updateSale = async (req, res) => {
    try {
        const { InvoiceID } = req.params;
        const { CustomerID } = req.body;
        const { BillToCustomerID } = req.body;
        const { DeliveryMethodID } = req.body;
        const { ContactPersonID } = req.body;
        const { AccountsPersonID } = req.body;
        const { SalespersonPersonID } = req.body;
        const { PackedByPersonID } = req.body;
        const { InvoiceDate } = req.body;
        const { LastEditedBy } = req.body;
        const { OrderID } = req.body;
        const { CustomerPurchaseOrderNumber } = req.body;
        const { IsCreditNote } = req.body;
        const { CreditNoteReason } = req.body;
        const { Comments } = req.body;
        const { DeliveryInstructions } = req.body;
        const { InternalComments } = req.body;
        const { DeliveryRun } = req.body;
        const { RunPosition } = req.body;
        const { ReturnedDeliveryData } = req.body;
        const { Lines } = req.body;

        let IsCreditNoteValue = false;
        let InvoiceLines = '[]';

        if (IsCreditNote === true || IsCreditNote === 1) {
            IsCreditNoteValue = true;
        }

        if (Array.isArray(Lines)) {
            InvoiceLines = JSON.stringify(Lines);
        }

        const pool = await getConnection();

        const result = await pool.request()
        .input('InvoiceID', sql.Int, InvoiceID)
        .input('CustomerID', sql.Int, CustomerID)
        .input('BillToCustomerID', sql.Int, BillToCustomerID)
        .input('DeliveryMethodID', sql.Int, DeliveryMethodID)
        .input('ContactPersonID', sql.Int, ContactPersonID)
        .input('AccountsPersonID', sql.Int, AccountsPersonID)
        .input('SalespersonPersonID', sql.Int, SalespersonPersonID)
        .input('PackedByPersonID', sql.Int, PackedByPersonID)
        .input('InvoiceDate', sql.Date, InvoiceDate)
        .input('LastEditedBy', sql.Int, LastEditedBy)
        .input('OrderID', sql.Int, OrderID)
        .input('CustomerPurchaseOrderNumber', sql.NVarChar(20), CustomerPurchaseOrderNumber)
        .input('IsCreditNote', sql.Bit, IsCreditNoteValue)
        .input('CreditNoteReason', sql.NVarChar(sql.MAX), CreditNoteReason)
        .input('Comments', sql.NVarChar(sql.MAX), Comments)
        .input('DeliveryInstructions', sql.NVarChar(sql.MAX), DeliveryInstructions)
        .input('InternalComments', sql.NVarChar(sql.MAX), InternalComments)
        .input('TotalDryItems', sql.Int, null)
        .input('TotalChillerItems', sql.Int, null)
        .input('DeliveryRun', sql.NVarChar(5), DeliveryRun)
        .input('RunPosition', sql.NVarChar(5), RunPosition)
        .input('ReturnedDeliveryData', sql.NVarChar(sql.MAX), ReturnedDeliveryData)
        .input('InvoiceLines', sql.NVarChar(sql.MAX), InvoiceLines)
        .execute('dbo.usp_Ventas_Actualizar');

        res.json({
            message: 'Venta actualizada correctamente',
            id: result.recordset[0].InvoiceID
        });

    } catch (error) {
        console.error('Error:', error);
        sendDatabaseError(res, error);
    }
};

// ======================================================== //

// ==================== Peticiones DELETE ==================== //

// Clientes.
export const deleteCustomer = async (req, res) => {
    try {
        const { CustomerID } = req.params;

        const pool = await getConnection();

        const result = await pool.request()
        .input('CustomerID', sql.Int, CustomerID)
        .execute('dbo.usp_Clientes_Eliminar');

        res.json({
            message: 'Cliente eliminado correctamente',
            id: result.recordset[0].CustomerID
        });

    } catch (error) {
        console.error('Error:', error);
        sendDatabaseError(res, error);
    }
};

// Inventarios.
export const deleteInventory = async (req, res) => {
    try {
        const { StockItemID } = req.params;

        const pool = await getConnection();

        const result = await pool.request()
        .input('StockItemID', sql.Int, StockItemID)
        .execute('dbo.usp_Inventarios_Eliminar');

        res.json({
            message: 'Producto eliminado correctamente',
            id: result.recordset[0].StockItemID
        });

    } catch (error) {
        console.error('Error:', error);
        sendDatabaseError(res, error);
    }
};

// Proveedores.
export const deleteSupplier = async (req, res) => {
    try {
        const { SupplierID } = req.params;

        const pool = await getConnection();

        const result = await pool.request()
        .input('SupplierID', sql.Int, SupplierID)
        .execute('dbo.usp_Proveedores_Eliminar');

        res.json({
            message: 'Proveedor eliminado correctamente',
            id: result.recordset[0].SupplierID
        });

    } catch (error) {
        console.error('Error:', error);
        sendDatabaseError(res, error);
    }
};

// Ventas.
export const deleteSale = async (req, res) => {
    try {
        const { InvoiceID } = req.params;

        const pool = await getConnection();

        const result = await pool.request()
        .input('InvoiceID', sql.Int, InvoiceID)
        .execute('dbo.usp_Ventas_Eliminar');

        res.json({
            message: 'Venta eliminada correctamente',
            id: result.recordset[0].InvoiceID
        });

    } catch (error) {
        console.error('Error:', error);
        sendDatabaseError(res, error);
    }
};

// =========================================================== //
