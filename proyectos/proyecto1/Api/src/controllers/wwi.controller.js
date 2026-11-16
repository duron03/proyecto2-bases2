import { getConnection, sql } from '../database/connection.js';
import { createHttpError, sendError } from '../errors.js';

function optional(value) {
	if (value === '' || value === undefined) {
		return null;
	}

	return value;
}

function integer(value) {
	if (value === '' || value === undefined || value === null) {
		return null;
	}

	const parsed = Number(value);
	if (!Number.isInteger(parsed)) {
		throw createHttpError(400, 'DATOS_INVALIDOS', 'Uno de los valores numéricos no es válido.');
	}

	return parsed;
}

function positiveInteger(value) {
	const parsed = integer(value);

	if (parsed === null || parsed <= 0) {
		throw createHttpError(400, 'DATOS_INVALIDOS', 'El identificador no es válido.');
	}

	return parsed;
}

function expectedVersion(value, allowZero = false) {
	const parsed = integer(value);
	let minimum = 1;

	if (allowZero) {
		minimum = 0;
	}

	if (parsed === null || parsed < minimum) {
		throw createHttpError(400, 'DATOS_INVALIDOS', 'La versión esperada no es válida.');
	}

	return parsed;
}

function requireProperties(body, properties) {
	if (!body || typeof body !== 'object' || Array.isArray(body)) {
		throw createHttpError(400, 'DATOS_INVALIDOS', 'El cuerpo de la solicitud no es válido.');
	}

	for (const property of properties) {
		if (!Object.prototype.hasOwnProperty.call(body, property)) {
			throw createHttpError(400, 'DATOS_INVALIDOS', `Falta el campo ${property}.`);
		}
	}
}

function getPhotoData(photo) {
	if (!photo) {
		return null;
	}

	if (typeof photo !== 'string') {
		throw createHttpError(400, 'DATOS_INVALIDOS', 'La fotografía no tiene un formato válido.');
	}

	let base64 = photo;
	const commaIndex = photo.indexOf(',');

	if (commaIndex >= 0) {
		base64 = photo.slice(commaIndex + 1);
	}

	if (!/^[A-Za-z0-9+/]*={0,2}$/.test(base64)) {
		throw createHttpError(400, 'DATOS_INVALIDOS', 'La fotografía no tiene un formato válido.');
	}

	const data = Buffer.from(base64, 'base64');

	if (data.length > 1024 * 1024) {
		throw createHttpError(413, 'ARCHIVO_DEMASIADO_GRANDE', 'La fotografía no puede superar 1 MiB.');
	}

	return data;
}

function sendControllerError(res, error, isWrite = false) {
	sendError(res, error, isWrite);
}

function addCustomerInputs(request, body, includeVersion) {
	request
		.input('CustomerName', sql.NVarChar(100), body.CustomerName)
		.input('CustomerCategoryID', sql.Int, body.CustomerCategoryID)
		.input('PrimaryContactPersonID', sql.Int, body.PrimaryContactPersonID)
		.input('DeliveryMethodID', sql.Int, body.DeliveryMethodID)
		.input('DeliveryCityID', sql.Int, body.DeliveryCityID)
		.input('PostalCityID', sql.Int, body.PostalCityID)
		.input('AccountOpenedDate', sql.Date, body.AccountOpenedDate)
		.input('StandardDiscountPercentage', sql.Decimal(18, 3), body.StandardDiscountPercentage)
		.input('IsStatementSent', sql.Bit, Boolean(body.IsStatementSent))
		.input('IsOnCreditHold', sql.Bit, Boolean(body.IsOnCreditHold))
		.input('PaymentDays', sql.Int, body.PaymentDays)
		.input('PhoneNumber', sql.NVarChar(20), body.PhoneNumber)
		.input('FaxNumber', sql.NVarChar(20), body.FaxNumber)
		.input('WebsiteURL', sql.NVarChar(256), body.WebsiteURL)
		.input('DeliveryAddressLine1', sql.NVarChar(60), body.DeliveryAddressLine1)
		.input('DeliveryPostalCode', sql.NVarChar(10), body.DeliveryPostalCode)
		.input('PostalAddressLine1', sql.NVarChar(60), body.PostalAddressLine1)
		.input('PostalPostalCode', sql.NVarChar(10), body.PostalPostalCode)
		.input('LastEditedBy', sql.Int, null)
		.input('BillToCustomerID', sql.Int, optional(body.BillToCustomerID))
		.input('BuyingGroupID', sql.Int, optional(body.BuyingGroupID))
		.input('AlternateContactPersonID', sql.Int, optional(body.AlternateContactPersonID))
		.input('CreditLimit', sql.Decimal(18, 2), optional(body.CreditLimit))
		.input('DeliveryRun', sql.NVarChar(5), optional(body.DeliveryRun))
		.input('RunPosition', sql.NVarChar(5), optional(body.RunPosition))
		.input('DeliveryAddressLine2', sql.NVarChar(60), optional(body.DeliveryAddressLine2))
		.input('DeliveryLatitude', sql.Decimal(9, 6), optional(body.DeliveryLatitude))
		.input('DeliveryLongitude', sql.Decimal(9, 6), optional(body.DeliveryLongitude))
		.input('PostalAddressLine2', sql.NVarChar(60), optional(body.PostalAddressLine2));

	if (includeVersion) {
		request.input('VersionEsperada', sql.Int, expectedVersion(body.VersionEsperada));
	}

	return request;
}

function addSupplierInputs(request, body, includeVersion) {
	request
		.input('SupplierName', sql.NVarChar(100), body.SupplierName)
		.input('SupplierCategoryID', sql.Int, body.SupplierCategoryID)
		.input('PrimaryContactPersonID', sql.Int, body.PrimaryContactPersonID)
		.input('AlternateContactPersonID', sql.Int, body.AlternateContactPersonID)
		.input('DeliveryCityID', sql.Int, body.DeliveryCityID)
		.input('PostalCityID', sql.Int, body.PostalCityID)
		.input('PaymentDays', sql.Int, body.PaymentDays)
		.input('PhoneNumber', sql.NVarChar(20), body.PhoneNumber)
		.input('FaxNumber', sql.NVarChar(20), body.FaxNumber)
		.input('WebsiteURL', sql.NVarChar(256), body.WebsiteURL)
		.input('DeliveryAddressLine1', sql.NVarChar(60), body.DeliveryAddressLine1)
		.input('DeliveryPostalCode', sql.NVarChar(10), body.DeliveryPostalCode)
		.input('PostalAddressLine1', sql.NVarChar(60), body.PostalAddressLine1)
		.input('PostalPostalCode', sql.NVarChar(10), body.PostalPostalCode)
		.input('LastEditedBy', sql.Int, null)
		.input('DeliveryMethodID', sql.Int, optional(body.DeliveryMethodID))
		.input('SupplierReference', sql.NVarChar(20), optional(body.SupplierReference))
		.input('BankAccountName', sql.NVarChar(50), optional(body.BankAccountName))
		.input('BankAccountBranch', sql.NVarChar(50), optional(body.BankAccountBranch))
		.input('BankAccountCode', sql.NVarChar(20), optional(body.BankAccountCode))
		.input('BankAccountNumber', sql.NVarChar(20), optional(body.BankAccountNumber))
		.input('BankInternationalCode', sql.NVarChar(20), optional(body.BankInternationalCode))
		.input('InternalComments', sql.NVarChar(sql.MAX), optional(body.InternalComments))
		.input('DeliveryAddressLine2', sql.NVarChar(60), optional(body.DeliveryAddressLine2))
		.input('DeliveryLatitude', sql.Decimal(9, 6), optional(body.DeliveryLatitude))
		.input('DeliveryLongitude', sql.Decimal(9, 6), optional(body.DeliveryLongitude))
		.input('PostalAddressLine2', sql.NVarChar(60), optional(body.PostalAddressLine2));

	if (includeVersion) {
		request.input('VersionEsperada', sql.Int, expectedVersion(body.VersionEsperada));
	}

	return request;
}

function addInventoryInputs(request, body, includeVersion, includeGroup) {
	request
		.input('StockItemName', sql.NVarChar(100), body.StockItemName)
		.input('SupplierID', sql.Int, body.SupplierID)
		.input('UnitPackageID', sql.Int, body.UnitPackageID)
		.input('OuterPackageID', sql.Int, body.OuterPackageID)
		.input('LeadTimeDays', sql.Int, body.LeadTimeDays)
		.input('QuantityPerOuter', sql.Int, body.QuantityPerOuter)
		.input('IsChillerStock', sql.Bit, Boolean(body.IsChillerStock))
		.input('TaxRate', sql.Decimal(18, 3), body.TaxRate)
		.input('UnitPrice', sql.Decimal(18, 2), body.UnitPrice)
		.input('TypicalWeightPerUnit', sql.Decimal(18, 3), body.TypicalWeightPerUnit)
		.input('LastEditedBy', sql.Int, null)
		.input('ColorID', sql.Int, optional(body.ColorID))
		.input('Brand', sql.NVarChar(50), optional(body.Brand))
		.input('Size', sql.NVarChar(20), optional(body.Size))
		.input('Barcode', sql.NVarChar(50), optional(body.Barcode))
		.input('RecommendedRetailPrice', sql.Decimal(18, 2), optional(body.RecommendedRetailPrice))
		.input('MarketingComments', sql.NVarChar(sql.MAX), optional(body.MarketingComments))
		.input('InternalComments', sql.NVarChar(sql.MAX), optional(body.InternalComments))
		.input('Photo', sql.VarBinary(sql.MAX), getPhotoData(body.Photo))
		.input('CustomFields', sql.NVarChar(sql.MAX), optional(body.CustomFields));

	if (includeVersion) {
		request.input('VersionEsperada', sql.Int, expectedVersion(body.VersionEsperada));
	}

	if (includeGroup) {
		request.input('StockGroupID', sql.Int, optional(body.StockGroupID));
	}

	return request;
}

function addSaleInputs(request, body, includeVersion) {
	if (!Array.isArray(body.Lines) || body.Lines.length === 0) {
		throw createHttpError(400, 'DATOS_INVALIDOS', 'La venta debe tener al menos una línea.');
	}

	let initialItems = 0;
	if (includeVersion) {
		initialItems = null;
	}

	request
		.input('CustomerID', sql.Int, body.CustomerID)
		.input('BillToCustomerID', sql.Int, body.BillToCustomerID)
		.input('DeliveryMethodID', sql.Int, body.DeliveryMethodID)
		.input('ContactPersonID', sql.Int, body.ContactPersonID)
		.input('AccountsPersonID', sql.Int, body.AccountsPersonID)
		.input('SalespersonPersonID', sql.Int, body.SalespersonPersonID)
		.input('PackedByPersonID', sql.Int, body.PackedByPersonID)
		.input('InvoiceDate', sql.Date, body.InvoiceDate)
		.input('LastEditedBy', sql.Int, null)
		.input('OrderID', sql.Int, optional(body.OrderID))
		.input('CustomerPurchaseOrderNumber', sql.NVarChar(20), optional(body.CustomerPurchaseOrderNumber))
		.input('IsCreditNote', sql.Bit, Boolean(body.IsCreditNote))
		.input('CreditNoteReason', sql.NVarChar(sql.MAX), optional(body.CreditNoteReason))
		.input('Comments', sql.NVarChar(sql.MAX), optional(body.Comments))
		.input('DeliveryInstructions', sql.NVarChar(sql.MAX), optional(body.DeliveryInstructions))
		.input('InternalComments', sql.NVarChar(sql.MAX), optional(body.InternalComments))
		.input('TotalDryItems', sql.Int, initialItems)
		.input('TotalChillerItems', sql.Int, initialItems)
		.input('DeliveryRun', sql.NVarChar(5), optional(body.DeliveryRun))
		.input('RunPosition', sql.NVarChar(5), optional(body.RunPosition))
		.input('ReturnedDeliveryData', sql.NVarChar(sql.MAX), optional(body.ReturnedDeliveryData))
		.input('InvoiceLines', sql.NVarChar(sql.MAX), JSON.stringify(body.Lines));

	if (includeVersion) {
		request.input('VersionEsperada', sql.Int, expectedVersion(body.VersionEsperada));
	}

	return request;
}

const customerFormFields = [
	'CustomerName', 'CustomerCategoryID', 'BuyingGroupID', 'BillToCustomerID',
	'PrimaryContactPersonID', 'AlternateContactPersonID', 'PhoneNumber', 'FaxNumber',
	'WebsiteURL', 'DeliveryMethodID', 'DeliveryCityID', 'PostalCityID',
	'AccountOpenedDate', 'PaymentDays', 'CreditLimit', 'StandardDiscountPercentage',
	'IsStatementSent', 'IsOnCreditHold', 'DeliveryAddressLine1', 'DeliveryAddressLine2',
	'DeliveryPostalCode', 'PostalAddressLine1', 'PostalAddressLine2',
	'PostalPostalCode', 'DeliveryLatitude', 'DeliveryLongitude'
];

const supplierFormFields = [
	'SupplierName', 'SupplierReference', 'SupplierCategoryID', 'PrimaryContactPersonID',
	'AlternateContactPersonID', 'PhoneNumber', 'FaxNumber', 'WebsiteURL',
	'DeliveryMethodID', 'DeliveryCityID', 'PostalCityID', 'PaymentDays',
	'BankAccountName', 'BankAccountNumber', 'BankAccountBranch',
	'DeliveryAddressLine1', 'DeliveryAddressLine2', 'DeliveryPostalCode',
	'PostalAddressLine1', 'PostalAddressLine2', 'PostalPostalCode',
	'DeliveryLatitude', 'DeliveryLongitude'
];

const inventoryCatalogFields = [
	'StockItemName', 'SupplierID', 'ColorID', 'Brand', 'Size', 'UnitPackageID',
	'OuterPackageID', 'QuantityPerOuter', 'LeadTimeDays', 'IsChillerStock',
	'TaxRate', 'UnitPrice', 'RecommendedRetailPrice', 'TypicalWeightPerUnit',
	'Barcode', 'MarketingComments'
];

const saleFormFields = [
	'CustomerID', 'BillToCustomerID', 'InvoiceDate', 'CustomerPurchaseOrderNumber',
	'DeliveryMethodID', 'ContactPersonID', 'SalespersonPersonID', 'AccountsPersonID',
	'PackedByPersonID', 'DeliveryInstructions', 'Comments', 'IsCreditNote', 'Lines'
];

export async function getCustomers(req, res) {
	try {
		const pool = await getConnection(req.session, 'LOCAL');
		const result = await pool.request()
			.input('CustomerName', sql.NVarChar(100), optional(req.query.CustomerName))
			.input('CustomerCategoryID', sql.Int, integer(req.query.CustomerCategoryID))
			.input('DeliveryMethodID', sql.Int, integer(req.query.DeliveryMethodID))
			.execute('dbo.usp_Clientes_Listar');
		res.json(result.recordset);
	} catch (error) {
		sendControllerError(res, error);
	}
}

export async function getCustomerCatalogs(req, res) {
	try {
		const pool = await getConnection(req.session, 'LOCAL');
		const result = await pool.request().execute('dbo.usp_Clientes_ObtenerCatalogos');
		res.json({
			customerCategories: result.recordsets[0],
			buyingGroups: result.recordsets[1],
			people: result.recordsets[2],
			deliveryMethods: result.recordsets[3],
			customers: result.recordsets[4]
		});
	} catch (error) {
		sendControllerError(res, error);
	}
}

export async function getCustomerEditCatalogs(req, res) {
	try {
		const pool = await getConnection(req.session, 'CORP');
		const result = await pool.request()
			.input('CustomerID', sql.Int, integer(req.query.CustomerID))
			.execute('dbo.usp_Clientes_ObtenerCatalogosEdicion');
		res.json({
			customerCategories: result.recordsets[0],
			buyingGroups: result.recordsets[1],
			people: result.recordsets[2],
			deliveryMethods: result.recordsets[3],
			customers: result.recordsets[4]
		});
	} catch (error) {
		sendControllerError(res, error);
	}
}

export async function getCities(req, res) {
	try {
		const pool = await getConnection(req.session, 'CORP');
		const result = await pool.request()
			.input('CityName', sql.NVarChar(50), optional(req.query.name))
			.input('CityID', sql.Int, integer(req.query.id))
			.execute('dbo.usp_Ciudades_Buscar');
		res.json(result.recordset);
	} catch (error) {
		sendControllerError(res, error);
	}
}

async function getOne(session, destination, procedure, inputName, id) {
	const pool = await getConnection(session, destination);
	const result = await pool.request()
		.input(inputName, sql.Int, positiveInteger(id))
		.execute(procedure);
	return result.recordset[0] || null;
}

export async function getCustomerDetails(req, res) {
	try {
		const customer = await getOne(req.session, 'LOCAL', 'dbo.usp_Clientes_ObtenerDetalle', 'CustomerID', req.params.CustomerID);
		if (!customer) throw createHttpError(404, 'NO_ENCONTRADO', 'El cliente no existe.');
		res.json(customer);
	} catch (error) {
		sendControllerError(res, error);
	}
}

export async function getCustomerPrivate(req, res) {
	try {
		const customer = await getOne(req.session, 'CORP', 'dbo.usp_Clientes_ObtenerPrivados', 'CustomerID', req.params.CustomerID);
		if (!customer) throw createHttpError(404, 'NO_ENCONTRADO', 'El cliente no existe.');
		res.json(customer);
	} catch (error) {
		sendControllerError(res, error);
	}
}

export async function getCustomerEditData(req, res) {
	try {
		const customer = await getOne(req.session, 'CORP', 'dbo.usp_Clientes_ObtenerDatosEdicion', 'CustomerID', req.params.CustomerID);
		if (!customer) throw createHttpError(404, 'NO_ENCONTRADO', 'El cliente no existe.');
		res.json(customer);
	} catch (error) {
		sendControllerError(res, error);
	}
}

export async function getSuppliers(req, res) {
	try {
		const pool = await getConnection(req.session, 'LOCAL');
		const result = await pool.request()
			.input('SupplierName', sql.NVarChar(100), optional(req.query.SupplierName))
			.input('SupplierCategoryID', sql.Int, integer(req.query.SupplierCategoryID))
			.input('DeliveryMethodID', sql.Int, integer(req.query.DeliveryMethodID))
			.execute('dbo.usp_Proveedores_Listar');
		res.json(result.recordset);
	} catch (error) {
		sendControllerError(res, error);
	}
}

export async function getSupplierCatalogs(req, res) {
	try {
		const pool = await getConnection(req.session, 'LOCAL');
		const result = await pool.request().execute('dbo.usp_Proveedores_ObtenerCatalogos');
		res.json({
			supplierCategories: result.recordsets[0],
			people: result.recordsets[1],
			deliveryMethods: result.recordsets[2]
		});
	} catch (error) {
		sendControllerError(res, error);
	}
}

export async function getSupplierEditCatalogs(req, res) {
	try {
		const pool = await getConnection(req.session, 'CORP');
		const result = await pool.request()
			.input('SupplierID', sql.Int, integer(req.query.SupplierID))
			.execute('dbo.usp_Proveedores_ObtenerCatalogosEdicion');
		res.json({
			supplierCategories: result.recordsets[0],
			people: result.recordsets[1],
			deliveryMethods: result.recordsets[2]
		});
	} catch (error) {
		sendControllerError(res, error);
	}
}

export async function getSupplierDetails(req, res) {
	try {
		const supplier = await getOne(req.session, 'LOCAL', 'dbo.usp_Proveedores_ObtenerDetalle', 'SupplierID', req.params.SupplierID);
		if (!supplier) throw createHttpError(404, 'NO_ENCONTRADO', 'El proveedor no existe.');
		res.json(supplier);
	} catch (error) {
		sendControllerError(res, error);
	}
}

export async function getSupplierPrivate(req, res) {
	try {
		const supplier = await getOne(req.session, 'CORP', 'dbo.usp_Proveedores_ObtenerPrivados', 'SupplierID', req.params.SupplierID);
		if (!supplier) throw createHttpError(404, 'NO_ENCONTRADO', 'El proveedor no existe.');
		res.json(supplier);
	} catch (error) {
		sendControllerError(res, error);
	}
}

export async function getSupplierEditData(req, res) {
	try {
		const supplier = await getOne(req.session, 'CORP', 'dbo.usp_Proveedores_ObtenerDatosEdicion', 'SupplierID', req.params.SupplierID);
		if (!supplier) throw createHttpError(404, 'NO_ENCONTRADO', 'El proveedor no existe.');
		res.json(supplier);
	} catch (error) {
		sendControllerError(res, error);
	}
}

export async function getInventories(req, res) {
	try {
		const pool = await getConnection(req.session, 'LOCAL');
		const result = await pool.request()
			.input('StockItemName', sql.NVarChar(100), optional(req.query.StockItemName))
			.input('StockGroupID', sql.Int, integer(req.query.StockGroupID))
			.input('MinimumQuantityOnHand', sql.Int, integer(req.query.MinimumQuantityOnHand))
			.input('MaximumQuantityOnHand', sql.Int, integer(req.query.MaximumQuantityOnHand))
			.execute('dbo.usp_Inventarios_Listar');
		res.json(result.recordset);
	} catch (error) {
		sendControllerError(res, error);
	}
}

export async function getInventoryCatalogs(req, res) {
	try {
		const pool = await getConnection(req.session, 'LOCAL');
		const result = await pool.request().execute('dbo.usp_Inventarios_ObtenerCatalogos');
		res.json({
			suppliers: result.recordsets[0],
			stockGroups: result.recordsets[1],
			colors: result.recordsets[2],
			packageTypes: result.recordsets[3]
		});
	} catch (error) {
		sendControllerError(res, error);
	}
}

export async function getInventoryEditCatalogs(req, res) {
	try {
		const pool = await getConnection(req.session, 'CORP');
		const result = await pool.request()
			.input('StockItemID', sql.Int, integer(req.query.StockItemID))
			.execute('dbo.usp_Inventarios_ObtenerCatalogosEdicion');
		res.json({
			suppliers: result.recordsets[0],
			stockGroups: result.recordsets[1],
			colors: result.recordsets[2],
			packageTypes: result.recordsets[3]
		});
	} catch (error) {
		sendControllerError(res, error);
	}
}

export async function getInventoryDetails(req, res) {
	try {
		const inventory = await getOne(req.session, 'LOCAL', 'dbo.usp_Inventarios_ObtenerDetalle', 'StockItemID', req.params.StockItemID);
		if (!inventory) throw createHttpError(404, 'NO_ENCONTRADO', 'El producto no existe.');
		res.json(inventory);
	} catch (error) {
		sendControllerError(res, error);
	}
}

export async function getInventoryCentral(req, res) {
	try {
		const inventory = await getOne(req.session, 'CORP', 'dbo.usp_Inventarios_ObtenerCatalogoCentral', 'StockItemID', req.params.StockItemID);
		if (!inventory) throw createHttpError(404, 'NO_ENCONTRADO', 'El producto no existe.');
		if (Buffer.isBuffer(inventory.Photo)) inventory.Photo = inventory.Photo.toString('base64');
		res.json(inventory);
	} catch (error) {
		sendControllerError(res, error);
	}
}

export async function getInvoices(req, res) {
	try {
		const pool = await getConnection(req.session, 'LOCAL');
		const result = await pool.request()
			.input('CustomerName', sql.NVarChar(100), optional(req.query.CustomerName))
			.input('InvoiceDateFrom', sql.Date, optional(req.query.InvoiceDateFrom))
			.input('InvoiceDateTo', sql.Date, optional(req.query.InvoiceDateTo))
			.input('MinimumInvoiceAmount', sql.Decimal(18, 2), optional(req.query.MinimumInvoiceAmount))
			.input('MaximumInvoiceAmount', sql.Decimal(18, 2), optional(req.query.MaximumInvoiceAmount))
			.input('DeliveryMethodID', sql.Int, integer(req.query.DeliveryMethodID))
			.execute('dbo.usp_Ventas_Listar');
		res.json(result.recordset);
	} catch (error) {
		sendControllerError(res, error);
	}
}

export async function getSaleCatalogs(req, res) {
	try {
		const pool = await getConnection(req.session, 'LOCAL');
		const result = await pool.request()
			.input('InvoiceID', sql.Int, integer(req.query.InvoiceID))
			.execute('dbo.usp_Ventas_ObtenerCatalogos');
		res.json({
			customers: result.recordsets[0],
			people: result.recordsets[1],
			deliveryMethods: result.recordsets[2],
			products: result.recordsets[3]
		});
	} catch (error) {
		sendControllerError(res, error);
	}
}

export async function getInvoiceDetails(req, res) {
	try {
		const pool = await getConnection(req.session, 'LOCAL');
		const result = await pool.request()
			.input('InvoiceID', sql.Int, positiveInteger(req.params.InvoiceID))
			.execute('dbo.usp_Ventas_ObtenerDetalle');
		const invoice = result.recordsets[0][0];
		if (!invoice) throw createHttpError(404, 'NO_ENCONTRADO', 'La venta no existe.');
		res.json({ invoice, lines: result.recordsets[1] });
	} catch (error) {
		sendControllerError(res, error);
	}
}

function calculateSyncStatus(corpResult, localResult) {
	const corpOk = corpResult.status === 'fulfilled';
	const localOk = localResult.status === 'fulfilled';
	let corpRow = null;
	let localRow = null;

	if (corpOk) {
		corpRow = corpResult.value;
	}

	if (localOk) {
		localRow = localResult.value;
	}

	if (!corpOk || !localOk) {
		return 'no_comprobable';
	}
	if (!corpRow && localRow) {
		return 'no_comprobable';
	}
	if (corpRow && !localRow) {
		return 'pendiente';
	}
	if (corpRow && localRow && Number(localRow.VersionCatalogo) < Number(corpRow.VersionCatalogo)) {
		return 'atrasado';
	}
	if (corpRow && localRow) {
		return 'recibido';
	}
	return 'no_comprobable';
}

async function getSyncStatus(req, res, config) {
	const id = req.params[config.param];
	const corpPromise = getOne(req.session, 'CORP', config.corpProcedure, config.input, id);
	const localPromise = getOne(req.session, 'LOCAL', config.localProcedure, config.input, id);
	const [corpResult, localResult] = await Promise.allSettled([corpPromise, localPromise]);
	const corpOk = corpResult.status === 'fulfilled';
	const localOk = localResult.status === 'fulfilled';
	let corpRow = null;
	let localRow = null;

	if (corpOk) {
		corpRow = corpResult.value;
	}

	if (localOk) {
		localRow = localResult.value;
	}

	if (corpOk && localOk && !corpRow && !localRow) {
		return res.status(404).json({ error: 'El registro no existe.', code: 'NO_ENCONTRADO' });
	}

	if (corpOk && !corpRow && localRow) {
		console.error(`Inconsistencia de catálogo en ${config.param} ${id}.`);
	}

	let existsInCorporate = null;
	let corporateVersion = null;
	let localVersion = null;

	if (corpOk) {
		existsInCorporate = Boolean(corpRow);
	}
	if (corpRow) {
		corporateVersion = corpRow.VersionCatalogo;
	}
	if (localRow) {
		localVersion = localRow.VersionCatalogo;
	}

	return res.json({
		id: Number(id),
		existeEnCorporativo: existsInCorporate,
		versionCorporativa: corporateVersion,
		versionLocal: localVersion,
		estado: calculateSyncStatus(corpResult, localResult),
		consultaCorporativoOk: corpOk,
		consultaLocalOk: localOk
	});
}

export async function getCustomerSyncStatus(req, res) {
	try {
		await getSyncStatus(req, res, {
			param: 'CustomerID',
			input: 'CustomerID',
			corpProcedure: 'dbo.usp_Clientes_ObtenerDatosEdicion',
			localProcedure: 'dbo.usp_Clientes_ObtenerDetalle'
		});
	} catch (error) {
		sendControllerError(res, error);
	}
}

export async function getSupplierSyncStatus(req, res) {
	try {
		await getSyncStatus(req, res, {
			param: 'SupplierID',
			input: 'SupplierID',
			corpProcedure: 'dbo.usp_Proveedores_ObtenerDatosEdicion',
			localProcedure: 'dbo.usp_Proveedores_ObtenerDetalle'
		});
	} catch (error) {
		sendControllerError(res, error);
	}
}

export async function getInventorySyncStatus(req, res) {
	try {
		await getSyncStatus(req, res, {
			param: 'StockItemID',
			input: 'StockItemID',
			corpProcedure: 'dbo.usp_Inventarios_ObtenerCatalogoCentral',
			localProcedure: 'dbo.usp_Inventarios_ObtenerDetalle'
		});
	} catch (error) {
		sendControllerError(res, error);
	}
}

function getRequestedScope(req) {
	const requested = String(req.query.sucursal || '').toUpperCase();
	const user = req.session.user;

	if (user.rol === 'ADMINISTRADOR') {
		let ownScope = 'LI';
		if (user.SucursalID === 1) {
			ownScope = 'SJ';
		}
		if (requested && requested !== ownScope) {
			throw createHttpError(403, 'ACCESO_DENEGADO', 'No puede consultar otra sucursal.');
		}
		return { code: ownScope, id: user.SucursalID, name: user.sucursalNombre };
	}

	const scope = requested || 'TODAS';
	if (!['SJ', 'LI', 'TODAS'].includes(scope)) {
		throw createHttpError(400, 'DATOS_INVALIDOS', 'La sucursal solicitada no es válida.');
	}

	if (scope === 'SJ') {
		return { code: 'SJ', id: 1, name: 'San José' };
	}
	if (scope === 'LI') {
		return { code: 'LI', id: 2, name: 'Limón' };
	}
	return { code: 'TODAS', id: null, name: 'Consolidado' };
}

const reportDefinitions = {
	1: {
		procedure: 'dbo.usp_Estadisticas_Reporte1',
		inputs: [['SupplierName', sql.NVarChar(100)], ['SupplierCategoryName', sql.NVarChar(50)]]
	},
	2: {
		procedure: 'dbo.usp_Estadisticas_Reporte2',
		inputs: [['CustomerName', sql.NVarChar(100)], ['CustomerCategoryName', sql.NVarChar(50)]]
	},
	3: {
		procedure: 'dbo.usp_Estadisticas_Reporte3',
		inputs: [['Year', sql.Int], ['StockItemName', sql.NVarChar(100)]]
	},
	4: {
		procedure: 'dbo.usp_Estadisticas_Reporte4',
		inputs: [['Year', sql.Int], ['CustomerName', sql.NVarChar(100)]]
	},
	5: {
		procedure: 'dbo.usp_Estadisticas_Reporte5',
		inputs: [['Year', sql.Int], ['SupplierName', sql.NVarChar(100)]]
	},
	6: {
		procedure: 'dbo.usp_Estadisticas_Reporte6',
		inputs: [['StockGroupName', sql.NVarChar(100)]]
	},
	7: {
		procedure: 'dbo.usp_Estadisticas_Reporte7',
		inputs: [['Year', sql.Int], ['Month', sql.Int], ['StockGroupName', sql.NVarChar(100)]]
	},
	8: {
		procedure: 'dbo.usp_Estadisticas_Reporte8',
		inputs: [['Year', sql.Int], ['Month', sql.Int], ['StockGroupName', sql.NVarChar(100)]]
	},
	10: {
		procedure: 'dbo.usp_Estadisticas_Reporte10',
		inputs: [
			['Year', sql.Int], ['Month', sql.Int], ['CustomerCategoryName', sql.NVarChar(50)],
			['StockGroupName', sql.NVarChar(100)], ['StockItemName', sql.NVarChar(100)]
		]
	}
};

async function getReport(req, res, reportNumber) {
	try {
		const definition = reportDefinitions[reportNumber];
		const scope = getRequestedScope(req);
		const pool = await getConnection(req.session, 'CORP');
		const request = pool.request();
		request.timeout = 30000;

		for (const [name, type] of definition.inputs) {
			let value = optional(req.query[name]);
			if (type === sql.Int) {
				value = integer(req.query[name]);
			}
			request.input(name, type, value);
		}

		request.input('SucursalID', sql.Int, scope.id);
		const result = await request.execute(definition.procedure);
		const sourcesResult = await pool.request().execute('Corporativo.usp_ObtenerEstadoFuentes');
		let sources = sourcesResult.recordset;

		if (scope.id) {
			sources = sources.filter((source) => source.SucursalID === scope.id);
		}

		let allSourcesReady = true;
		let reportStatus = 'reciente';
		const sourceList = [];

		for (const source of sources) {
			if (!source.inicializada) {
				allSourcesReady = false;
			}
			if (source.estado !== 'reciente') {
				reportStatus = 'atrasado';
			}

			let sourceCode = 'LI';
			if (source.SucursalID === 1) {
				sourceCode = 'SJ';
			}

			sourceList.push({
				sucursal: sourceCode,
				inicializada: Boolean(source.inicializada),
				ultimoLatidoUtc: source.ultimoLatidoUtc,
				estado: source.estado
			});
		}

		if (!allSourcesReady) {
			throw createHttpError(503, 'SIN_INICIALIZAR', 'La fuente solicitada todavía no fue inicializada.');
		}

		res.json({
			rows: result.recordset,
			scope: { sucursal: scope.code, nombre: scope.name },
			sources: sourceList,
			generatedAtUtc: new Date().toISOString(),
			status: reportStatus
		});
	} catch (error) {
		sendControllerError(res, error);
	}
}

export function getReport1(req, res) {
	return getReport(req, res, 1);
}
export function getReport2(req, res) {
	return getReport(req, res, 2);
}
export function getReport3(req, res) {
	return getReport(req, res, 3);
}
export function getReport4(req, res) {
	return getReport(req, res, 4);
}
export function getReport5(req, res) {
	return getReport(req, res, 5);
}
export function getReport6(req, res) {
	return getReport(req, res, 6);
}
export function getReport7(req, res) {
	return getReport(req, res, 7);
}
export function getReport8(req, res) {
	return getReport(req, res, 8);
}
export function getReport10(req, res) {
	return getReport(req, res, 10);
}

export function getReport9(req, res) {
	res.status(501).json({
		error: 'El reporte 9 no está implementado en el proyecto anterior.',
		code: 'REPORTE_NO_IMPLEMENTADO'
	});
}

export async function getReportCatalogs(req, res) {
	try {
		const scope = getRequestedScope(req);
		const pool = await getConnection(req.session, 'CORP');
		const result = await pool.request()
			.input('SucursalID', sql.Int, scope.id)
			.execute('Corporativo.usp_ObtenerCatalogosReportes');
		res.json({ years: result.recordsets[0], months: result.recordsets[1] });
	} catch (error) {
		sendControllerError(res, error);
	}
}

function materializedSource(code, date) {
	let status = 'desconocido';

	if (date) {
		const age = Date.now() - new Date(date).getTime();
		if (age <= 60000) {
			status = 'reciente';
		} else {
			status = 'atrasado';
		}
	}

	return { sucursal: code, ultimoLatidoUtc: date, estado: status };
}

export async function getCorporateSummary(req, res) {
	try {
		const scope = getRequestedScope(req);
		const pool = await getConnection(req.session, 'CORP');
		const result = await pool.request()
			.input('SucursalID', sql.Int, scope.id)
			.input('Year', sql.Int, integer(req.query.Year))
			.input('Month', sql.Int, integer(req.query.Month))
			.execute('Corporativo.usp_ObtenerResumenVentas');
		const stateResult = await pool.request().execute('Corporativo.usp_ObtenerEstadoMaterializacion');
		const state = stateResult.recordset[0];

		if (!state || !state.UltimoExitoUtc) {
			throw createHttpError(503, 'SIN_INICIALIZAR', 'El resumen todavía no fue inicializado.');
		}

		let sources = [
			materializedSource('SJ', state.LatidoSJUsadoUtc),
			materializedSource('LI', state.LatidoLIUsadoUtc)
		];

		if (scope.id === 1) sources = sources.filter((source) => source.sucursal === 'SJ');
		if (scope.id === 2) sources = sources.filter((source) => source.sucursal === 'LI');

		const materializationAge = Date.now() - new Date(state.UltimoExitoUtc).getTime();
		let status = 'atrasado';
		let sourcesAreRecent = true;

		for (const source of sources) {
			if (source.estado !== 'reciente') {
				sourcesAreRecent = false;
			}
		}

		if (state.estado === 'correcto' && materializationAge <= 120000 && sourcesAreRecent) {
			status = 'reciente';
		}

		res.json({
			rows: result.recordset,
			scope: { sucursal: scope.code, nombre: scope.name },
			sources,
			materializedAtUtc: state.UltimoExitoUtc,
			status,
			lastAttemptStatus: state.estado,
			lastError: state.UltimoError || null
		});
	} catch (error) {
		sendControllerError(res, error);
	}
}

export async function createCustomer(req, res) {
	try {
		requireProperties(req.body, customerFormFields);
		const pool = await getConnection(req.session, 'CORP');
		const result = await addCustomerInputs(pool.request(), req.body, false).execute('dbo.usp_Clientes_Crear');
		const row = result.recordset[0];
		res.status(201).json({
			message: 'Cliente guardado en el catálogo. Las sucursales se actualizarán en breve.',
			newId: row.CustomerID,
			VersionCatalogo: row.VersionCatalogo,
			replicacion: 'pendiente'
		});
	} catch (error) {
		sendControllerError(res, error, true);
	}
}

export async function updateCustomer(req, res) {
	try {
		requireProperties(req.body, customerFormFields.concat('VersionEsperada'));
		const pool = await getConnection(req.session, 'CORP');
		const request = addCustomerInputs(pool.request(), req.body, true)
			.input('CustomerID', sql.Int, positiveInteger(req.params.CustomerID));
		const result = await request.execute('dbo.usp_Clientes_Actualizar');
		const row = result.recordset[0];
		res.json({
			message: 'Cliente actualizado. Las sucursales se actualizarán en breve.',
			id: row.CustomerID,
			VersionCatalogo: row.VersionCatalogo,
			replicacion: 'pendiente'
		});
	} catch (error) {
		sendControllerError(res, error, true);
	}
}

export async function deleteCustomer(req, res) {
	try {
		requireProperties(req.body, ['VersionEsperada']);
		const pool = await getConnection(req.session, 'CORP');
		const result = await pool.request()
			.input('CustomerID', sql.Int, positiveInteger(req.params.CustomerID))
			.input('VersionEsperada', sql.Int, expectedVersion(req.body.VersionEsperada))
			.execute('dbo.usp_Clientes_Eliminar');
		const row = result.recordset[0];
		res.json({
			message: 'Cliente dado de baja. Las sucursales se actualizarán en breve.',
			id: row.CustomerID,
			VersionCatalogo: row.VersionCatalogo,
			replicacion: 'pendiente'
		});
	} catch (error) {
		sendControllerError(res, error, true);
	}
}

export async function createSupplier(req, res) {
	try {
		requireProperties(req.body, supplierFormFields);
		const pool = await getConnection(req.session, 'CORP');
		const result = await addSupplierInputs(pool.request(), req.body, false).execute('dbo.usp_Proveedores_Crear');
		const row = result.recordset[0];
		res.status(201).json({
			message: 'Proveedor guardado en el catálogo. Las sucursales se actualizarán en breve.',
			newId: row.SupplierID,
			VersionCatalogo: row.VersionCatalogo,
			replicacion: 'pendiente'
		});
	} catch (error) {
		sendControllerError(res, error, true);
	}
}

export async function updateSupplier(req, res) {
	try {
		requireProperties(req.body, supplierFormFields.concat('VersionEsperada'));
		const pool = await getConnection(req.session, 'CORP');
		const request = addSupplierInputs(pool.request(), req.body, true)
			.input('SupplierID', sql.Int, positiveInteger(req.params.SupplierID));
		const result = await request.execute('dbo.usp_Proveedores_Actualizar');
		const row = result.recordset[0];
		res.json({
			message: 'Proveedor actualizado. Las sucursales se actualizarán en breve.',
			id: row.SupplierID,
			VersionCatalogo: row.VersionCatalogo,
			replicacion: 'pendiente'
		});
	} catch (error) {
		sendControllerError(res, error, true);
	}
}

export async function deleteSupplier(req, res) {
	try {
		requireProperties(req.body, ['VersionEsperada']);
		const pool = await getConnection(req.session, 'CORP');
		const result = await pool.request()
			.input('SupplierID', sql.Int, positiveInteger(req.params.SupplierID))
			.input('VersionEsperada', sql.Int, expectedVersion(req.body.VersionEsperada))
			.execute('dbo.usp_Proveedores_Eliminar');
		const row = result.recordset[0];
		res.json({
			message: 'Proveedor dado de baja. Las sucursales se actualizarán en breve.',
			id: row.SupplierID,
			VersionCatalogo: row.VersionCatalogo,
			replicacion: 'pendiente'
		});
	} catch (error) {
		sendControllerError(res, error, true);
	}
}

export async function createInventory(req, res) {
	try {
		requireProperties(req.body, inventoryCatalogFields.concat('StockGroupID'));
		const pool = await getConnection(req.session, 'CORP');
		const result = await addInventoryInputs(pool.request(), req.body, false, true)
			.execute('dbo.usp_Inventarios_Crear');
		const row = result.recordset[0];
		res.status(201).json({
			message: 'Producto guardado en el catálogo. Las sucursales se actualizarán en breve.',
			newId: row.StockItemID,
			VersionCatalogo: row.VersionCatalogo,
			replicacion: 'pendiente'
		});
	} catch (error) {
		sendControllerError(res, error, true);
	}
}

export async function updateInventory(req, res) {
	try {
		requireProperties(req.body, inventoryCatalogFields.concat('VersionEsperada'));
		const pool = await getConnection(req.session, 'CORP');
		const request = addInventoryInputs(pool.request(), req.body, true, false)
			.input('StockItemID', sql.Int, positiveInteger(req.params.StockItemID));
		const result = await request.execute('dbo.usp_Inventarios_Actualizar');
		const row = result.recordset[0];
		res.json({
			message: 'Producto actualizado. Las sucursales se actualizarán en breve.',
			id: row.StockItemID,
			VersionCatalogo: row.VersionCatalogo,
			replicacion: 'pendiente'
		});
	} catch (error) {
		sendControllerError(res, error, true);
	}
}

export async function deleteInventory(req, res) {
	try {
		requireProperties(req.body, ['VersionEsperada']);
		const pool = await getConnection(req.session, 'CORP');
		const result = await pool.request()
			.input('StockItemID', sql.Int, positiveInteger(req.params.StockItemID))
			.input('VersionEsperada', sql.Int, expectedVersion(req.body.VersionEsperada))
			.execute('dbo.usp_Inventarios_Eliminar');
		const row = result.recordset[0];
		res.json({
			message: 'Producto dado de baja. Las sucursales se actualizarán en breve.',
			id: row.StockItemID,
			VersionCatalogo: row.VersionCatalogo,
			replicacion: 'pendiente'
		});
	} catch (error) {
		sendControllerError(res, error, true);
	}
}

export async function saveHoldings(req, res) {
	try {
		const fields = [
			'QuantityOnHand', 'BinLocation', 'LastStocktakeQuantity', 'LastCostPrice',
			'ReorderLevel', 'TargetStockLevel', 'VersionEsperada'
		];
		requireProperties(req.body, fields);
		const pool = await getConnection(req.session, 'LOCAL');
		const result = await pool.request()
			.input('StockItemID', sql.Int, positiveInteger(req.params.StockItemID))
			.input('QuantityOnHand', sql.Int, req.body.QuantityOnHand)
			.input('BinLocation', sql.NVarChar(20), req.body.BinLocation)
			.input('LastStocktakeQuantity', sql.Int, req.body.LastStocktakeQuantity)
			.input('LastCostPrice', sql.Decimal(18, 2), req.body.LastCostPrice)
			.input('ReorderLevel', sql.Int, req.body.ReorderLevel)
			.input('TargetStockLevel', sql.Int, req.body.TargetStockLevel)
			.input('VersionEsperada', sql.Int, expectedVersion(req.body.VersionEsperada, true))
			.execute('dbo.usp_Inventarios_GuardarExistencias');
		const row = result.recordset[0];
		res.json({
			message: 'Existencias guardadas correctamente.',
			id: row.StockItemID,
			VersionExistencias: row.VersionExistencias
		});
	} catch (error) {
		sendControllerError(res, error, true);
	}
}

export async function createSale(req, res) {
	try {
		requireProperties(req.body, saleFormFields);
		const pool = await getConnection(req.session, 'LOCAL');
		const result = await addSaleInputs(pool.request(), req.body, false).execute('dbo.usp_Ventas_Crear');
		const row = result.recordset[0];
		res.status(201).json({
			message: 'Venta creada correctamente.',
			newId: row.InvoiceID,
			VersionVenta: row.VersionVenta
		});
	} catch (error) {
		sendControllerError(res, error, true);
	}
}

export async function updateSale(req, res) {
	try {
		requireProperties(req.body, saleFormFields.concat('VersionEsperada'));
		const pool = await getConnection(req.session, 'LOCAL');
		const request = addSaleInputs(pool.request(), req.body, true)
			.input('InvoiceID', sql.Int, positiveInteger(req.params.InvoiceID));
		const result = await request.execute('dbo.usp_Ventas_Actualizar');
		const row = result.recordset[0];
		res.json({
			message: 'Venta actualizada correctamente.',
			id: row.InvoiceID,
			VersionVenta: row.VersionVenta
		});
	} catch (error) {
		sendControllerError(res, error, true);
	}
}

export async function deleteSale(req, res) {
	try {
		requireProperties(req.body, ['VersionEsperada']);
		const pool = await getConnection(req.session, 'LOCAL');
		const result = await pool.request()
			.input('InvoiceID', sql.Int, positiveInteger(req.params.InvoiceID))
			.input('VersionEsperada', sql.Int, expectedVersion(req.body.VersionEsperada))
			.execute('dbo.usp_Ventas_Eliminar');
		res.json({
			message: 'Venta eliminada correctamente.',
			id: result.recordset[0].InvoiceID
		});
	} catch (error) {
		sendControllerError(res, error, true);
	}
}
