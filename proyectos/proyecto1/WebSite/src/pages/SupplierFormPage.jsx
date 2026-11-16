import { useEffect, useState } from 'react'
import { CAlert, CButton, CSpinner } from '@coreui/react'
import { CIcon } from '@coreui/icons-react'
import { cilArrowLeft, cilReload } from '@coreui/icons'
import { Link, useNavigate, useParams } from 'react-router-dom'
import {
	createSupplier,
	getSupplierEditCatalogs,
	getSupplierEditData,
	updateSupplier,
} from '../services/supplierApi'
import PageHeader from '../components/PageHeader'
import EntityForm from '../components/EntityForm'

function getEmptyValues(fields) {
	const values = {}
	fields.forEach((field) => {
		values[field.name] = ''
		if (field.type === 'checkbox') {
			values[field.name] = false
		}
	})
	return values
}

function prepareSupplierData(fields, values) {
	const supplier = {}
	fields.forEach((field) => {
		supplier[field.name] = values[field.name]
		if (values[field.name] === '') {
			supplier[field.name] = null
		}
	})
	return supplier
}

export default function SupplierFormPage({ definition, mode }) {
	const { id } = useParams()
	const navigate = useNavigate()
	const isEditing = mode === 'edit'
	const [values, setValues] = useState(getEmptyValues(definition.formFields))
	const [catalogs, setCatalogs] = useState({})
	const [loading, setLoading] = useState(true)
	const [saving, setSaving] = useState(false)
	const [error, setError] = useState('')
	const [conflict, setConflict] = useState(false)

	async function loadForm() {
		try {
			setLoading(true)
			setError('')
			setConflict(false)
			let catalogId = null
			if (isEditing) {
				catalogId = id
			}
			const catalogData = await getSupplierEditCatalogs(catalogId)
			setCatalogs(catalogData)

			if (isEditing) {
				const supplier = await getSupplierEditData(id)
				setValues(supplier)
			}
		} catch (requestError) {
			setError(requestError.message)
		} finally {
			setLoading(false)
		}
	}

	useEffect(() => {
		loadForm()
	}, [id, isEditing])

	function changeValue(name, value) {
		setValues({ ...values, [name]: value })
	}

	async function saveSupplier() {
		try {
			setSaving(true)
			setError('')
			setConflict(false)
			const supplierData = prepareSupplierData(definition.formFields, values)
			let result

			if (isEditing) {
				result = await updateSupplier(id, {
					...supplierData,
					VersionEsperada: values.VersionCatalogo,
				})
				navigate(`/proveedores/${id}?versionEsperada=${result.VersionCatalogo}`)
			} else {
				result = await createSupplier(supplierData)
				navigate(`/proveedores/${result.newId}?versionEsperada=${result.VersionCatalogo}`)
			}
		} catch (requestError) {
			setError(requestError.message)
			setConflict(requestError.code === 'VERSION_OBSOLETA')
		} finally {
			setSaving(false)
		}
	}

	let title = 'Nuevo proveedor'
	let description = 'Registre el proveedor en el catálogo compartido.'
	if (isEditing) {
		title = 'Editar proveedor'
		description = 'Los datos se guardan en Corporativo y luego se propagan a las sucursales.'
	}

	return (
		<>
			<PageHeader
				title={title}
				description={description}
				breadcrumbs={[{ label: definition.title, to: '/proveedores' }, { label: title }]}
				actions={(
					<CButton as={Link} color="secondary" variant="outline" to="/proveedores">
						<CIcon icon={cilArrowLeft} className="me-2" />
						Volver
					</CButton>
				)}
			/>

			{error && (
				<CAlert color="danger">
					{error}
					{conflict && (
						<CButton color="danger" variant="outline" size="sm" className="ms-3" onClick={loadForm}>
							<CIcon icon={cilReload} className="me-2" />
							Recargar datos
						</CButton>
					)}
				</CAlert>
			)}

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
