import { Router } from 'express';
import { getCurrentSession, login, logout } from '../controllers/auth.controller.js';
import { getApiHealth, getSystemStatus } from '../controllers/system.controller.js';
import {
	createCustomer,
	createInventory,
	createSale,
	createSupplier,
	deleteCustomer,
	deleteInventory,
	deleteSale,
	deleteSupplier,
	getCities,
	getCorporateSummary,
	getCustomerCatalogs,
	getCustomerDetails,
	getCustomerEditCatalogs,
	getCustomerEditData,
	getCustomerPrivate,
	getCustomerSyncStatus,
	getCustomers,
	getInventories,
	getInventoryCatalogs,
	getInventoryCentral,
	getInventoryDetails,
	getInventoryEditCatalogs,
	getInventorySyncStatus,
	getInvoiceDetails,
	getInvoices,
	getReport1,
	getReport10,
	getReport2,
	getReport3,
	getReport4,
	getReport5,
	getReport6,
	getReport7,
	getReport8,
	getReport9,
	getReportCatalogs,
	getSaleCatalogs,
	getSupplierCatalogs,
	getSupplierDetails,
	getSupplierEditCatalogs,
	getSupplierEditData,
	getSupplierPrivate,
	getSupplierSyncStatus,
	getSuppliers,
	saveHoldings,
	updateCustomer,
	updateInventory,
	updateSale,
	updateSupplier
} from '../controllers/wwi.controller.js';
import { requireAdministrator, requireCorporate, requireSession } from '../middleware/auth.js';

const router = Router();

router.get('/health', getApiHealth);
router.post('/auth/login', login);

router.use(requireSession);
router.get('/auth/session', getCurrentSession);
router.post('/auth/logout', logout);
router.get('/system/status', getSystemStatus);

router.get('/customers/catalogs', requireAdministrator, getCustomerCatalogs);
router.get('/customers/edit-catalogs', requireAdministrator, getCustomerEditCatalogs);
router.get('/customers/:CustomerID/private', requireAdministrator, getCustomerPrivate);
router.get('/customers/:CustomerID/edit-data', requireAdministrator, getCustomerEditData);
router.get('/customers/:CustomerID/sync-status', requireAdministrator, getCustomerSyncStatus);
router.get('/customers/:CustomerID', requireAdministrator, getCustomerDetails);
router.get('/customers', requireAdministrator, getCustomers);
router.post('/customers', requireAdministrator, createCustomer);
router.put('/customers/:CustomerID', requireAdministrator, updateCustomer);
router.delete('/customers/:CustomerID', requireAdministrator, deleteCustomer);

router.get('/suppliers/catalogs', requireAdministrator, getSupplierCatalogs);
router.get('/suppliers/edit-catalogs', requireAdministrator, getSupplierEditCatalogs);
router.get('/suppliers/:SupplierID/private', requireAdministrator, getSupplierPrivate);
router.get('/suppliers/:SupplierID/edit-data', requireAdministrator, getSupplierEditData);
router.get('/suppliers/:SupplierID/sync-status', requireAdministrator, getSupplierSyncStatus);
router.get('/suppliers/:SupplierID', requireAdministrator, getSupplierDetails);
router.get('/suppliers', requireAdministrator, getSuppliers);
router.post('/suppliers', requireAdministrator, createSupplier);
router.put('/suppliers/:SupplierID', requireAdministrator, updateSupplier);
router.delete('/suppliers/:SupplierID', requireAdministrator, deleteSupplier);

router.get('/cities', requireAdministrator, getCities);

router.get('/inventory/catalogs', requireAdministrator, getInventoryCatalogs);
router.get('/inventory/edit-catalogs', requireAdministrator, getInventoryEditCatalogs);
router.get('/inventory/:StockItemID/catalog', requireAdministrator, getInventoryCentral);
router.get('/inventory/:StockItemID/sync-status', requireAdministrator, getInventorySyncStatus);
router.get('/inventory/:StockItemID', requireAdministrator, getInventoryDetails);
router.get('/inventory', requireAdministrator, getInventories);
router.post('/inventory', requireAdministrator, createInventory);
router.put('/inventory/:StockItemID/holdings', requireAdministrator, saveHoldings);
router.put('/inventory/:StockItemID', requireAdministrator, updateInventory);
router.delete('/inventory/:StockItemID', requireAdministrator, deleteInventory);

router.get('/sales/catalogs', requireAdministrator, getSaleCatalogs);
router.get('/sales/:InvoiceID', requireAdministrator, getInvoiceDetails);
router.get('/sales', requireAdministrator, getInvoices);
router.post('/sales', requireAdministrator, createSale);
router.put('/sales/:InvoiceID', requireAdministrator, updateSale);
router.delete('/sales/:InvoiceID', requireAdministrator, deleteSale);

router.get('/reports/catalogs', getReportCatalogs);
router.get('/reports/1', getReport1);
router.get('/reports/2', getReport2);
router.get('/reports/3', getReport3);
router.get('/reports/4', getReport4);
router.get('/reports/5', getReport5);
router.get('/reports/6', getReport6);
router.get('/reports/7', getReport7);
router.get('/reports/8', getReport8);
router.get('/reports/9', getReport9);
router.get('/reports/10', getReport10);

router.get('/corporate/summary', requireCorporate, getCorporateSummary);

export default router;
