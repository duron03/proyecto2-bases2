import { Router } from 'express';
import {

    // Peticiones GET
    getApiHealth,
    getCustomers,
    getCustomerCatalogs,
    getCities,
    getCustomerDetails,
    getInventories,
    getInventoryCatalogs,
    getInventoryDetails,
    getSuppliers,
    getSupplierCatalogs,
    getSupplierDetails,
    getInvoices,
    getSaleCatalogs,
    getInvoiceDetails,

    // Reportes
    getReport1,
    getReport2,
    getReport3,
    getReport4,
    getReport5,
    getReport6,
    getReport7,
    getReport8,
    getReport9,
    getReport10,

    // Peticiones POST
    createCustomer,
    createInventory,
    createSupplier,
    createSale,

    // Peticiones PUT
    updateCustomer,
    updateInventory,
    updateSupplier,
    updateSale,

    // Peticiones DELETE
    deleteCustomer,
    deleteInventory,
    deleteSupplier,
    deleteSale
} from '../controllers/wwi.controller.js';

const router = Router();

// ==================== Peticiones GET ==================== //

// Estado de la API.
router.get('/health', getApiHealth);

// Clientes.
router.get('/customers', getCustomers);

router.get('/customers/catalogs', getCustomerCatalogs);

router.get('/cities', getCities);

router.get('/customers/:CustomerID', getCustomerDetails);

// Inventarios.
router.get('/inventory', getInventories);

router.get('/inventory/catalogs', getInventoryCatalogs);

router.get('/inventory/:StockItemID', getInventoryDetails);

// Proveedores.
router.get('/suppliers', getSuppliers);

router.get('/suppliers/catalogs', getSupplierCatalogs);

router.get('/suppliers/:SupplierID', getSupplierDetails);

// Ventas.
router.get('/sales', getInvoices);

router.get('/sales/catalogs', getSaleCatalogs);

router.get('/sales/:InvoiceID', getInvoiceDetails);

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
// ======================================================== //

// ==================== Peticiones POST ==================== //

// Clientes.
router.post('/customers', createCustomer);

// Inventarios.
router.post('/inventory', createInventory);

// Proveedores.
router.post('/suppliers', createSupplier);

// Ventas.
router.post('/sales', createSale);

// ========================================================= //

// ==================== Peticiones PUT ==================== //

// Clientes.
router.put('/customers/:CustomerID', updateCustomer);

// Inventarios.
router.put('/inventory/:StockItemID', updateInventory);

// Proveedores.
router.put('/suppliers/:SupplierID', updateSupplier);

// Ventas.
router.put('/sales/:InvoiceID', updateSale);

// ======================================================== //

// ==================== Peticiones DELETE ==================== //

// Clientes.
router.delete('/customers/:CustomerID', deleteCustomer);

// Inventarios.
router.delete('/inventory/:StockItemID', deleteInventory);

// Proveedores.
router.delete('/suppliers/:SupplierID', deleteSupplier);

// Ventas.
router.delete('/sales/:InvoiceID', deleteSale);

// =========================================================== //

export default router;
