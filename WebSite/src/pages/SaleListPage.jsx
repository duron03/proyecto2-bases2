import { useEffect, useState } from 'react'
import { CAlert, CButton, CCard, CCardBody } from '@coreui/react'
import { CIcon } from '@coreui/icons-react'
import { cilPlus } from '@coreui/icons'
import { Link } from 'react-router-dom'
import { deleteSale, getSaleCatalogs, getSales } from '../services/salesApi'
import PageHeader from '../components/PageHeader'
import FilterPanel from '../components/FilterPanel'
import DataTable from '../components/DataTable'

const emptyFilters = {
  CustomerName: '',
  InvoiceDateFrom: '',
  InvoiceDateTo: '',
  MinimumInvoiceAmount: '',
  MaximumInvoiceAmount: '',
  DeliveryMethodID: '',
}

const pageSize = 100

export default function SaleListPage({ definition }) {
  const [sales, setSales] = useState([])
  const [catalogs, setCatalogs] = useState({})
  const [filters, setFilters] = useState(emptyFilters)
  const [loading, setLoading] = useState(true)
  const [currentPage, setCurrentPage] = useState(1)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')

  async function loadSales(selectedFilters = filters) {
    try {
      setLoading(true)
      setError('')
      const data = await getSales(selectedFilters)
      setSales(data)
      setCurrentPage(1)
    } catch (requestError) {
      setError(requestError.message)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    async function loadPage() {
      try {
        const saleData = await getSales(emptyFilters)
        const catalogData = await getSaleCatalogs()
        setSales(saleData)
        setCatalogs(catalogData)
        setCurrentPage(1)
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
    loadSales(emptyFilters)
  }

  function submitFilters() {
    loadSales(filters)
  }

  async function removeSale(sale) {
    const confirmed = window.confirm(`¿Desea eliminar la factura ${sale.InvoiceID}?`)

    if (!confirmed) {
      return
    }

    try {
      setError('')
      setMessage('')
      const result = await deleteSale(sale.InvoiceID)
      setMessage(result.message)
      await loadSales(filters)
    } catch (requestError) {
      setError(requestError.message)
    }
  }

  function showPreviousPage() {
    if (currentPage > 1) {
      setCurrentPage(currentPage - 1)
    }
  }

  function showNextPage() {
    if (currentPage < totalPages) {
      setCurrentPage(currentPage + 1)
    }
  }

  let totalPages = Math.ceil(sales.length / pageSize)

  if (totalPages === 0) {
    totalPages = 1
  }

  const firstRow = (currentPage - 1) * pageSize
  const lastRow = firstRow + pageSize
  const visibleSales = sales.slice(firstRow, lastRow)

  const createButton = (
    <CButton as={Link} color="primary" to="/ventas/nuevo">
      <CIcon icon={cilPlus} className="me-2" />
      Nueva venta
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
            {!loading && (
              <div className="d-flex align-items-center gap-2">
                <span className="text-body-secondary">{sales.length} registros</span>
                <CButton
                  type="button"
                  color="secondary"
                  variant="outline"
                  size="sm"
                  onClick={showPreviousPage}
                  disabled={currentPage === 1}
                >
                  Anterior
                </CButton>
                <span className="text-body-secondary">Página {currentPage} de {totalPages}</span>
                <CButton
                  type="button"
                  color="secondary"
                  variant="outline"
                  size="sm"
                  onClick={showNextPage}
                  disabled={currentPage === totalPages}
                >
                  Siguiente
                </CButton>
              </div>
            )}
          </div>
          <DataTable
            columns={definition.columns}
            rows={visibleSales}
            idField={definition.idField}
            basePath="/ventas"
            loading={loading}
            onDelete={removeSale}
          />
        </CCardBody>
      </CCard>
    </>
  )
}
