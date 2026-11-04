import { useEffect, useState } from 'react'
import { CAlert, CButton, CSpinner } from '@coreui/react'
import { CIcon } from '@coreui/icons-react'
import { cilArrowLeft } from '@coreui/icons'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { createSupplier, getSupplier, getSupplierCatalogs, updateSupplier } from '../services/supplierApi'
import PageHeader from '../components/PageHeader'
import EntityForm from '../components/EntityForm'

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

function prepareSupplierData(fields, values) {
  const supplier = {}

  fields.forEach((field) => {
    const value = values[field.name]

    if (value === '') {
      supplier[field.name] = null
    } else {
      supplier[field.name] = value
    }
  })

  return supplier
}

export default function SupplierFormPage({ definition, mode }) {
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
        const catalogData = await getSupplierCatalogs()
        setCatalogs(catalogData)

        if (isEditing) {
          const supplier = await getSupplier(id)
          setValues(supplier)
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

  async function saveSupplier() {
    try {
      setSaving(true)
      setError('')
      const supplierData = prepareSupplierData(definition.formFields, values)

      if (isEditing) {
        await updateSupplier(id, supplierData)
        navigate(`/proveedores/${id}`)
      } else {
        const result = await createSupplier(supplierData)
        navigate(`/proveedores/${result.newId}`)
      }
    } catch (requestError) {
      setError(requestError.message)
    } finally {
      setSaving(false)
    }
  }

  let title = 'Nuevo proveedor'
  let description = 'Complete los datos para registrar un proveedor.'

  if (isEditing) {
    title = 'Editar proveedor'
    description = 'Modifique los datos del proveedor y guarde los cambios.'
  }

  const backButton = (
    <CButton as={Link} color="secondary" variant="outline" to="/proveedores">
      <CIcon icon={cilArrowLeft} className="me-2" />
      Volver
    </CButton>
  )

  return (
    <>
      <PageHeader
        title={title}
        description={description}
        breadcrumbs={[{ label: definition.title, to: '/proveedores' }, { label: title }]}
        actions={backButton}
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
          onSubmit={saveSupplier}
        />
      )}
    </>
  )
}
