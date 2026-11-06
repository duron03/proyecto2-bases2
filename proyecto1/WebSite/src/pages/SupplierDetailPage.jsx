import { useEffect, useState } from 'react'
import { CAlert, CButton, CSpinner } from '@coreui/react'
import { CIcon } from '@coreui/icons-react'
import { cilArrowLeft, cilPencil, cilTrash } from '@coreui/icons'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { deleteSupplier, getSupplier } from '../services/supplierApi'
import PageHeader from '../components/PageHeader'
import DetailSection from '../components/DetailSection'
import LocationCard from '../components/LocationCard'

export default function SupplierDetailPage({ definition }) {
  const { id } = useParams()
  const navigate = useNavigate()
  const [supplier, setSupplier] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    async function loadSupplier() {
      try {
        const data = await getSupplier(id)
        setSupplier(data)
      } catch (requestError) {
        setError(requestError.message)
      } finally {
        setLoading(false)
      }
    }

    loadSupplier()
  }, [id])

  async function removeSupplier() {
    const confirmed = window.confirm(`¿Desea eliminar el proveedor "${supplier.SupplierName}"?`)

    if (!confirmed) {
      return
    }

    try {
      await deleteSupplier(id)
      navigate('/proveedores')
    } catch (requestError) {
      setError(requestError.message)
    }
  }

  const actions = (
    <>
      <CButton as={Link} color="secondary" variant="outline" to="/proveedores">
        <CIcon icon={cilArrowLeft} className="me-2" />
        Volver
      </CButton>
      <CButton as={Link} color="primary" to={`/proveedores/${id}/editar`} disabled={!supplier}>
        <CIcon icon={cilPencil} className="me-2" />
        Editar
      </CButton>
      <CButton color="danger" variant="outline" onClick={removeSupplier} disabled={!supplier}>
        <CIcon icon={cilTrash} className="me-2" />
        Eliminar
      </CButton>
    </>
  )

  let pageTitle = 'Detalle del proveedor'

  if (supplier) {
    pageTitle = supplier.SupplierName
  }

  return (
    <>
      <PageHeader
        title={pageTitle}
        description="Información registrada para el proveedor."
        breadcrumbs={[{ label: definition.title, to: '/proveedores' }, { label: 'Detalle' }]}
        actions={actions}
      />

      {error && <CAlert color="danger">{error}</CAlert>}

      {loading && (
        <div className="text-center py-5">
          <CSpinner color="primary" />
          <div className="text-body-secondary mt-2">Cargando proveedor…</div>
        </div>
      )}

      {supplier && (
        <>
          <div className="detail-grid mb-4">
            {definition.detailSections.map((section) => (
              <DetailSection
                key={section.title}
                title={section.title}
                fields={section.fields}
                record={supplier}
              />
            ))}
          </div>
          <LocationCard
            latitude={supplier.DeliveryLatitude}
            longitude={supplier.DeliveryLongitude}
          />
        </>
      )}
    </>
  )
}
