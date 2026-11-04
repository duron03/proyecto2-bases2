import { useEffect, useState } from 'react'
import { CAlert, CButton, CSpinner } from '@coreui/react'
import { CIcon } from '@coreui/icons-react'
import { cilArrowLeft, cilPencil, cilTrash } from '@coreui/icons'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { entities } from '../config/entities'
import { deleteCustomer, getCustomer } from '../services/customerApi'
import { deleteInventory, getInventory } from '../services/inventoryApi'
import PageHeader from '../components/PageHeader'
import DetailSection from '../components/DetailSection'
import LocationCard from '../components/LocationCard'
import SupplierDetailPage from './SupplierDetailPage'
import SaleDetailPage from './SaleDetailPage'

function CustomerDetailPage({ definition }) {
  const { id } = useParams()
  const navigate = useNavigate()
  const [customer, setCustomer] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    async function loadCustomer() {
      try {
        const data = await getCustomer(id)
        setCustomer(data)
      } catch (requestError) {
        setError(requestError.message)
      } finally {
        setLoading(false)
      }
    }

    loadCustomer()
  }, [id])

  async function removeCustomer() {
    const confirmed = window.confirm(`¿Desea eliminar al cliente "${customer.CustomerName}"?`)

    if (!confirmed) {
      return
    }

    try {
      await deleteCustomer(id)
      navigate('/clientes')
    } catch (requestError) {
      setError(requestError.message)
    }
  }

  const actions = (
    <>
      <CButton as={Link} color="secondary" variant="outline" to="/clientes">
        <CIcon icon={cilArrowLeft} className="me-2" />
        Volver
      </CButton>
      <CButton as={Link} color="primary" to={`/clientes/${id}/editar`} disabled={!customer}>
        <CIcon icon={cilPencil} className="me-2" />
        Editar
      </CButton>
      <CButton color="danger" variant="outline" onClick={removeCustomer} disabled={!customer}>
        <CIcon icon={cilTrash} className="me-2" />
        Eliminar
      </CButton>
    </>
  )

  let pageTitle = 'Detalle del cliente'

  if (customer) {
    pageTitle = customer.CustomerName
  }

  return (
    <>
      <PageHeader
        title={pageTitle}
        description="Información registrada para el cliente."
        breadcrumbs={[{ label: definition.title, to: '/clientes' }, { label: 'Detalle' }]}
        actions={actions}
      />

      {error && <CAlert color="danger">{error}</CAlert>}

      {loading && (
        <div className="text-center py-5">
          <CSpinner color="primary" />
          <div className="text-body-secondary mt-2">Cargando cliente…</div>
        </div>
      )}

      {customer && (
        <>
          <div className="detail-grid mb-4">
            {definition.detailSections.map((section) => (
              <DetailSection
                key={section.title}
                title={section.title}
                fields={section.fields}
                record={customer}
              />
            ))}
          </div>
          <LocationCard
            latitude={customer.DeliveryLatitude}
            longitude={customer.DeliveryLongitude}
          />
        </>
      )}
    </>
  )
}

function InventoryDetailPage({ definition }) {
  const { id } = useParams()
  const navigate = useNavigate()
  const [inventory, setInventory] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    async function loadInventory() {
      try {
        const data = await getInventory(id)
        setInventory(data)
      } catch (requestError) {
        setError(requestError.message)
      } finally {
        setLoading(false)
      }
    }

    loadInventory()
  }, [id])

  async function removeInventory() {
    const confirmed = window.confirm(`¿Desea eliminar el producto "${inventory.StockItemName}"?`)

    if (!confirmed) {
      return
    }

    try {
      await deleteInventory(id)
      navigate('/inventario')
    } catch (requestError) {
      setError(requestError.message)
    }
  }

  const actions = (
    <>
      <CButton as={Link} color="secondary" variant="outline" to="/inventario">
        <CIcon icon={cilArrowLeft} className="me-2" />
        Volver
      </CButton>
      <CButton as={Link} color="primary" to={`/inventario/${id}/editar`} disabled={!inventory}>
        <CIcon icon={cilPencil} className="me-2" />
        Editar
      </CButton>
      <CButton color="danger" variant="outline" onClick={removeInventory} disabled={!inventory}>
        <CIcon icon={cilTrash} className="me-2" />
        Eliminar
      </CButton>
    </>
  )

  let pageTitle = 'Detalle del producto'

  if (inventory) {
    pageTitle = inventory.StockItemName
  }

  return (
    <>
      <PageHeader
        title={pageTitle}
        description="Información registrada para el producto."
        breadcrumbs={[{ label: definition.title, to: '/inventario' }, { label: 'Detalle' }]}
        actions={actions}
      />

      {error && <CAlert color="danger">{error}</CAlert>}

      {loading && (
        <div className="text-center py-5">
          <CSpinner color="primary" />
          <div className="text-body-secondary mt-2">Cargando producto…</div>
        </div>
      )}

      {inventory && (
        <div className="detail-grid mb-4">
          {definition.detailSections.map((section) => (
            <DetailSection
              key={section.title}
              title={section.title}
              fields={section.fields}
              record={inventory}
            />
          ))}
        </div>
      )}
    </>
  )
}

export default function EntityDetailPage({ entityKey }) {
  const definition = entities[entityKey]

  if (entityKey === 'customers') {
    return <CustomerDetailPage definition={definition} />
  }

  if (entityKey === 'inventory') {
    return <InventoryDetailPage definition={definition} />
  }

  if (entityKey === 'suppliers') {
    return <SupplierDetailPage definition={definition} />
  }

  if (entityKey === 'sales') {
    return <SaleDetailPage definition={definition} />
  }

  return null
}
