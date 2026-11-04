import { useEffect, useState } from 'react'
import { CAlert, CButton, CCard, CCardBody } from '@coreui/react'
import { CIcon } from '@coreui/icons-react'
import { cilPlus } from '@coreui/icons'
import { Link } from 'react-router-dom'
import { deleteSupplier, getSupplierCatalogs, getSuppliers } from '../services/supplierApi'
import PageHeader from '../components/PageHeader'
import FilterPanel from '../components/FilterPanel'
import DataTable from '../components/DataTable'

const emptyFilters = {
  SupplierName: '',
  SupplierCategoryID: '',
  DeliveryMethodID: '',
}

export default function SupplierListPage({ definition }) {
  const [suppliers, setSuppliers] = useState([])
  const [catalogs, setCatalogs] = useState({})
  const [filters, setFilters] = useState(emptyFilters)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')

  async function loadSuppliers(selectedFilters = filters) {
    try {
      setLoading(true)
      setError('')
      const data = await getSuppliers(selectedFilters)
      setSuppliers(data)
    } catch (requestError) {
      setError(requestError.message)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    async function loadPage() {
      try {
        const supplierData = await getSuppliers(emptyFilters)
        const catalogData = await getSupplierCatalogs()
        setSuppliers(supplierData)
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
    setFilters(emptyFilters)
    setMessage('')
    loadSuppliers(emptyFilters)
  }

  function submitFilters() {
    loadSuppliers(filters)
  }

  async function removeSupplier(supplier) {
    const confirmed = window.confirm(`¿Desea eliminar el proveedor "${supplier.SupplierName}"?`)

    if (!confirmed) {
      return
    }

    try {
      setError('')
      setMessage('')
      const result = await deleteSupplier(supplier.SupplierID)
      setMessage(result.message)
      await loadSuppliers(filters)
    } catch (requestError) {
      setError(requestError.message)
    }
  }

  const createButton = (
    <CButton as={Link} color="primary" to="/proveedores/nuevo">
      <CIcon icon={cilPlus} className="me-2" />
      Nuevo proveedor
    </CButton>
  )

  return (
    <>
      <PageHeader
        title={definition.title}
        description={definition.description}
        actions={createButton}
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

      <CCard className="shadow-sm result-card">
        <CCardBody className="p-0">
          <div className="result-toolbar">
            <strong>Resultados</strong>
            {!loading && <span className="text-body-secondary">{suppliers.length} registros</span>}
          </div>
          <DataTable
            columns={definition.columns}
            rows={suppliers}
            idField={definition.idField}
            basePath="/proveedores"
            loading={loading}
            onDelete={removeSupplier}
          />
        </CCardBody>
      </CCard>
    </>
  )
}
