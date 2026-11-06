import { useEffect, useState } from 'react'
import { CAlert, CButton, CCard, CCardBody, CSpinner } from '@coreui/react'
import { CIcon } from '@coreui/icons-react'
import { cilArrowLeft, cilPencil, cilTrash } from '@coreui/icons'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { deleteSale, getSale } from '../services/salesApi'
import PageHeader from '../components/PageHeader'
import DetailSection from '../components/DetailSection'
import DataTable from '../components/DataTable'

const lineColumns = [
  { key: 'StockItemName', label: 'Producto', linkBasePath: '/inventario', linkIdField: 'StockItemID' },
  { key: 'Quantity', label: 'Cantidad' },
  { key: 'UnitPrice', label: 'Precio unitario' },
  { key: 'TaxRate', label: 'Impuesto (%)' },
  { key: 'TaxAmount', label: 'Monto impuesto' },
  { key: 'ExtendedPrice', label: 'Total' },
]

export default function SaleDetailPage({ definition }) {
  const { id } = useParams()
  const navigate = useNavigate()
  const [invoice, setInvoice] = useState(null)
  const [lines, setLines] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    async function loadSale() {
      try {
        const data = await getSale(id)
        setInvoice(data.invoice)
        setLines(data.lines)
      } catch (requestError) {
        setError(requestError.message)
      } finally {
        setLoading(false)
      }
    }

    loadSale()
  }, [id])

  async function removeSale() {
    const confirmed = window.confirm(`¿Desea eliminar la factura ${id}?`)

    if (!confirmed) {
      return
    }

    try {
      await deleteSale(id)
      navigate('/ventas')
    } catch (requestError) {
      setError(requestError.message)
    }
  }

  const actions = (
    <>
      <CButton as={Link} color="secondary" variant="outline" to="/ventas">
        <CIcon icon={cilArrowLeft} className="me-2" />
        Volver
      </CButton>
      <CButton as={Link} color="primary" to={`/ventas/${id}/editar`} disabled={!invoice}>
        <CIcon icon={cilPencil} className="me-2" />
        Editar
      </CButton>
      <CButton color="danger" variant="outline" onClick={removeSale} disabled={!invoice}>
        <CIcon icon={cilTrash} className="me-2" />
        Eliminar
      </CButton>
    </>
  )

  let pageTitle = `Factura ${id}`

  if (invoice) {
    pageTitle = `Factura ${invoice.InvoiceID}`
  }

  return (
    <>
      <PageHeader
        title={pageTitle}
        description="Encabezado y líneas registradas para la venta."
        breadcrumbs={[{ label: definition.title, to: '/ventas' }, { label: 'Detalle' }]}
        actions={actions}
      />

      {error && <CAlert color="danger">{error}</CAlert>}

      {loading && (
        <div className="text-center py-5">
          <CSpinner color="primary" />
          <div className="text-body-secondary mt-2">Cargando venta…</div>
        </div>
      )}

      {invoice && (
        <>
          <div className="detail-grid mb-4">
            {definition.detailSections.map((section) => (
              <DetailSection
                key={section.title}
                title={section.title}
                fields={section.fields}
                record={invoice}
              />
            ))}
          </div>

          <CCard className="shadow-sm mt-4">
            <CCardBody className="p-0">
              <div className="result-toolbar"><strong>Detalle de factura</strong></div>
              <DataTable
                columns={lineColumns}
                rows={lines}
                idField="InvoiceLineID"
                showActions={false}
              />
            </CCardBody>
          </CCard>
        </>
      )}
    </>
  )
}
