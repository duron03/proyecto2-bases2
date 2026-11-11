import { useEffect, useState } from 'react'
import { CAlert, CButton, CCard, CCardBody } from '@coreui/react'
import { CIcon } from '@coreui/icons-react'
import { cilPlus } from '@coreui/icons'
import { Link } from 'react-router-dom'
import { entities } from '../config/entities'
import { deleteCustomer, getCustomerCatalogs, getCustomers } from '../services/customerApi'
import { deleteInventory, getInventories, getInventoryCatalogs } from '../services/inventoryApi'
import PageHeader from '../components/PageHeader'
import FilterPanel from '../components/FilterPanel'
import DataTable from '../components/DataTable'
import SupplierListPage from './SupplierListPage'
import SaleListPage from './SaleListPage'

const emptyCustomerFilters = {
  CustomerName: '',
  CustomerCategoryID: '',
  DeliveryMethodID: '',
}

const emptyInventoryFilters = {
  StockItemName: '',
  StockGroupID: '',
  MinimumQuantityOnHand: '',
  MaximumQuantityOnHand: '',
}

function CreateButton({ definition }) {
  return (
    <CButton as={Link} color="primary" to={`/${definition.route}/nuevo`}>
      <CIcon icon={cilPlus} className="me-2" />
      Nuevo {definition.singular}
    </CButton>
  )
}

function ResultCard({ definition, rows, loading, onDelete }) {
  return (
    <CCard className="shadow-sm result-card">
      <CCardBody className="p-0">
        <div className="result-toolbar">
          <strong>Resultados</strong>
          {!loading && <span className="text-body-secondary">{rows.length} registros</span>}
        </div>
        <DataTable
          columns={definition.columns}
          rows={rows}
          idField={definition.idField}
          basePath={`/${definition.route}`}
          loading={loading}
          onDelete={onDelete}
        />
      </CCardBody>
    </CCard>
  )
}

function CustomerListPage({ definition }) {
  const [customers, setCustomers] = useState([])
  const [catalogs, setCatalogs] = useState({})
  const [filters, setFilters] = useState(emptyCustomerFilters)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')

  async function loadCustomers(selectedFilters = filters) {
    try {
      setLoading(true)
      setError('')
      const data = await getCustomers(selectedFilters)
      setCustomers(data)
    } catch (requestError) {
      setError(requestError.message)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    async function loadPage() {
      try {
        const customerData = await getCustomers(emptyCustomerFilters)
        const catalogData = await getCustomerCatalogs()
        setCustomers(customerData)
        setCatalogs(catalogData)
      } catch (requestError) {
        setError(requestError.message)
      } finally {
        setLoading(false)
      }
    }

    loadPage()
  }, [])

  function changeFilter(name, value) {
    setFilters({ ...filters, [name]: value })
  }

  function resetFilters() {
    setFilters(emptyCustomerFilters)
    setMessage('')
    loadCustomers(emptyCustomerFilters)
  }

  function submitFilters() {
    loadCustomers(filters)
  }

  async function removeCustomer(customer) {
    const confirmed = window.confirm(`¿Desea eliminar al cliente "${customer.CustomerName}"?`)

    if (!confirmed) {
      return
    }

    try {
      setError('')
      setMessage('')
      const result = await deleteCustomer(customer.CustomerID)
      setMessage(result.message)
      await loadCustomers(filters)
    } catch (requestError) {
      setError(requestError.message)
    }
  }

  return (
    <>
      <PageHeader
        title={definition.title}
        description={definition.description}
        actions={<CreateButton definition={definition} />}
      />
      {error && <CAlert color="danger">{error}</CAlert>}
      {message && <CAlert color="success">{message}</CAlert>}
      <FilterPanel
        fields={definition.filters}
        values={filters}
        catalogs={catalogs}
        loading={loading}
        onChange={changeFilter}
        onSubmit={submitFilters}
        onReset={resetFilters}
      />
      <ResultCard
        definition={definition}
        rows={customers}
        loading={loading}
        onDelete={removeCustomer}
      />
    </>
  )
}

function InventoryListPage({ definition }) {
  const [inventories, setInventories] = useState([])
  const [catalogs, setCatalogs] = useState({})
  const [filters, setFilters] = useState(emptyInventoryFilters)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')

  async function loadInventories(selectedFilters = filters) {
    try {
      setLoading(true)
      setError('')
      const data = await getInventories(selectedFilters)
      setInventories(data)
    } catch (requestError) {
      setError(requestError.message)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    async function loadPage() {
      try {
        const inventoryData = await getInventories(emptyInventoryFilters)
        const catalogData = await getInventoryCatalogs()
        setInventories(inventoryData)
        setCatalogs(catalogData)
      } catch (requestError) {
        setError(requestError.message)
      } finally {
        setLoading(false)
      }
    }

    loadPage()
  }, [])

  function changeFilter(name, value) {
    setFilters({ ...filters, [name]: value })
  }

  function resetFilters() {
    setFilters(emptyInventoryFilters)
    setMessage('')
    loadInventories(emptyInventoryFilters)
  }

  function submitFilters() {
    loadInventories(filters)
  }

  async function removeInventory(inventory) {
    const confirmed = window.confirm(`¿Desea eliminar el producto "${inventory.StockItemName}"?`)

    if (!confirmed) {
      return
    }

    try {
      setError('')
      setMessage('')
      const result = await deleteInventory(inventory.StockItemID)
      setMessage(result.message)
      await loadInventories(filters)
    } catch (requestError) {
      setError(requestError.message)
    }
  }

  return (
    <>
      <PageHeader
        title={definition.title}
        description={definition.description}
        actions={<CreateButton definition={definition} />}
      />
      {error && <CAlert color="danger">{error}</CAlert>}
      {message && <CAlert color="success">{message}</CAlert>}
      <FilterPanel
        fields={definition.filters}
        values={filters}
        catalogs={catalogs}
        loading={loading}
        onChange={changeFilter}
        onSubmit={submitFilters}
        onReset={resetFilters}
      />
      <ResultCard
        definition={definition}
        rows={inventories}
        loading={loading}
        onDelete={removeInventory}
      />
    </>
  )
}

export default function EntityListPage({ entityKey }) {
  const definition = entities[entityKey]

  if (entityKey === 'customers') {
    return <CustomerListPage definition={definition} />
  }

  if (entityKey === 'inventory') {
    return <InventoryListPage definition={definition} />
  }

  if (entityKey === 'suppliers') {
    return <SupplierListPage definition={definition} />
  }

  if (entityKey === 'sales') {
    return <SaleListPage definition={definition} />
  }

  return null
}
