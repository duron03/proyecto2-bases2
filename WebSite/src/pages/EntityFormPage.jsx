import { useEffect, useState } from 'react'
import { CAlert, CButton, CSpinner } from '@coreui/react'
import { CIcon } from '@coreui/icons-react'
import { cilArrowLeft } from '@coreui/icons'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { entities } from '../config/entities'
import { createCustomer, getCustomer, getCustomerCatalogs, updateCustomer } from '../services/customerApi'
import { createInventory, getInventory, getInventoryCatalogs, updateInventory } from '../services/inventoryApi'
import PageHeader from '../components/PageHeader'
import EntityForm from '../components/EntityForm'
import SupplierFormPage from './SupplierFormPage'
import SaleFormPage from './SaleFormPage'

function getEmptyValues(fields) {
  const values = {}

  fields.forEach((field) => {
    if (field.type === 'checkbox') {
      values[field.name] = false
    } else {
      values[field.name] = ''
    }
  })

  values.LastEditedBy = 1
  return values
}

function prepareFormData(fields, values) {
  const data = {}

  fields.forEach((field) => {
    const value = values[field.name]

    if (value === '') {
      data[field.name] = null
    } else {
      data[field.name] = value
    }
  })

  return data
}

function BackButton({ route }) {
  return (
    <CButton as={Link} color="secondary" variant="outline" to={`/${route}`}>
      <CIcon icon={cilArrowLeft} className="me-2" />
      Volver
    </CButton>
  )
}

function CustomerFormPage({ definition, mode }) {
  const { id } = useParams()
  const navigate = useNavigate()
  const isEditing = mode === 'edit'
  const initialValues = getEmptyValues(definition.formFields)
  const [values, setValues] = useState(initialValues)
  const [catalogs, setCatalogs] = useState({})
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    async function loadForm() {
      try {
        setLoading(true)
        const catalogData = await getCustomerCatalogs()
        setCatalogs(catalogData)

        if (isEditing) {
          const customer = await getCustomer(id)
          setValues(customer)
        }
      } catch (requestError) {
        setError(requestError.message)
      } finally {
        setLoading(false)
      }
    }

    loadForm()
  }, [definition.formFields, id, isEditing])

  function changeValue(name, value) {
    setValues({ ...values, [name]: value })
  }

  async function saveCustomer() {
    try {
      setSaving(true)
      setError('')
      const customerData = prepareFormData(definition.formFields, values)

      if (isEditing) {
        await updateCustomer(id, customerData)
        navigate(`/clientes/${id}`)
      } else {
        const result = await createCustomer(customerData)
        navigate(`/clientes/${result.newId}`)
      }
    } catch (requestError) {
      setError(requestError.message)
    } finally {
      setSaving(false)
    }
  }

  let title = 'Nuevo cliente'
  let description = 'Complete los datos para registrar un cliente.'

  if (isEditing) {
    title = 'Editar cliente'
    description = 'Modifique los datos del cliente y guarde los cambios.'
  }

  return (
    <>
      <PageHeader
        title={title}
        description={description}
        breadcrumbs={[{ label: definition.title, to: '/clientes' }, { label: title }]}
        actions={<BackButton route={definition.route} />}
      />

      {error && <CAlert color="danger">{error}</CAlert>}

      {loading ? (
        <div className="text-center py-5">
          <CSpinner color="primary" />
          <div className="text-body-secondary mt-2">Cargando formulario…</div>
        </div>
      ) : (
        <EntityForm
          definition={definition}
          mode={mode}
          values={values}
          catalogs={catalogs}
          saving={saving}
          onChange={changeValue}
          onSubmit={saveCustomer}
        />
      )}
    </>
  )
}

function InventoryFormPage({ definition, mode }) {
  const { id } = useParams()
  const navigate = useNavigate()
  const isEditing = mode === 'edit'
  const initialValues = getEmptyValues(definition.formFields)
  const [values, setValues] = useState(initialValues)
  const [catalogs, setCatalogs] = useState({})
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    async function loadForm() {
      try {
        setLoading(true)
        const catalogData = await getInventoryCatalogs()
        setCatalogs(catalogData)

        if (isEditing) {
          const inventory = await getInventory(id)
          setValues(inventory)
        }
      } catch (requestError) {
        setError(requestError.message)
      } finally {
        setLoading(false)
      }
    }

    loadForm()
  }, [definition.formFields, id, isEditing])

  function changeValue(name, value) {
    setValues({ ...values, [name]: value })
  }

  async function saveInventory() {
    try {
      setSaving(true)
      setError('')
      const inventoryData = prepareFormData(definition.formFields, values)

      if (isEditing) {
        await updateInventory(id, inventoryData)
        navigate(`/inventario/${id}`)
      } else {
        const result = await createInventory(inventoryData)
        navigate(`/inventario/${result.newId}`)
      }
    } catch (requestError) {
      setError(requestError.message)
    } finally {
      setSaving(false)
    }
  }

  let title = 'Nuevo producto'
  let description = 'Complete los datos para registrar un producto.'

  if (isEditing) {
    title = 'Editar producto'
    description = 'Modifique los datos del producto y guarde los cambios.'
  }

  return (
    <>
      <PageHeader
        title={title}
        description={description}
        breadcrumbs={[{ label: definition.title, to: '/inventario' }, { label: title }]}
        actions={<BackButton route={definition.route} />}
      />

      {error && <CAlert color="danger">{error}</CAlert>}

      {loading ? (
        <div className="text-center py-5">
          <CSpinner color="primary" />
          <div className="text-body-secondary mt-2">Cargando formulario…</div>
        </div>
      ) : (
        <EntityForm
          definition={definition}
          mode={mode}
          values={values}
          catalogs={catalogs}
          saving={saving}
          onChange={changeValue}
          onSubmit={saveInventory}
        />
      )}
    </>
  )
}

export default function EntityFormPage({ entityKey, mode }) {
  const definition = entities[entityKey]

  if (entityKey === 'customers') {
    return <CustomerFormPage definition={definition} mode={mode} />
  }

  if (entityKey === 'inventory') {
    return <InventoryFormPage definition={definition} mode={mode} />
  }

  if (entityKey === 'suppliers') {
    return <SupplierFormPage definition={definition} mode={mode} />
  }

  if (entityKey === 'sales') {
    return <SaleFormPage definition={definition} mode={mode} />
  }

  return null
}
