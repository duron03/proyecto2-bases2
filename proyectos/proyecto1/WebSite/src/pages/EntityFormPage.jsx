import { useEffect, useState } from 'react'
import { CAlert, CButton, CSpinner } from '@coreui/react'
import { CIcon } from '@coreui/icons-react'
import { cilArrowLeft, cilReload } from '@coreui/icons'
import { Link, useNavigate, useOutletContext, useParams } from 'react-router-dom'
import { entities } from '../config/entities'
import {
	createCustomer,
	getCustomerEditCatalogs,
	getCustomerEditData,
	updateCustomer,
} from '../services/customerApi'
import {
	createInventory,
	getInventory,
	getInventoryCentral,
	getInventoryEditCatalogs,
	saveHoldings,
	updateInventory,
} from '../services/inventoryApi'
import PageHeader from '../components/PageHeader'
import EntityForm from '../components/EntityForm'
import SupplierFormPage from './SupplierFormPage'
import SaleFormPage from './SaleFormPage'

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

function prepareFormData(fields, values) {
	const data = {}

	fields.forEach((field) => {
		data[field.name] = values[field.name]
		if (values[field.name] === '') {
			data[field.name] = null
		}
	})

	return data
}

function normalizeDate(value) {
	if (!value) return value
	return String(value).slice(0, 10)
}

function BackButton({ route }) {
	return (
		<CButton as={Link} color="secondary" variant="outline" to={`/${route}`}>
			<CIcon icon={cilArrowLeft} className="me-2" />
			Volver
		</CButton>
	)
}

function LoadingForm() {
	return (
		<div className="text-center py-5">
			<CSpinner color="primary" />
			<div className="text-body-secondary mt-2">Cargando formulario…</div>
		</div>
	)
}

function CustomerFormPage({ definition, mode }) {
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
			const catalogData = await getCustomerEditCatalogs(catalogId)
			setCatalogs(catalogData)

			if (isEditing) {
				const customer = await getCustomerEditData(id)
				setValues({ ...customer, AccountOpenedDate: normalizeDate(customer.AccountOpenedDate) })
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

	async function saveCustomer() {
		try {
			setSaving(true)
			setError('')
			setConflict(false)
			const customerData = prepareFormData(definition.formFields, values)
			let result

			if (isEditing) {
				result = await updateCustomer(id, {
					...customerData,
					VersionEsperada: values.VersionCatalogo,
				})
				navigate(`/clientes/${id}?versionEsperada=${result.VersionCatalogo}`)
			} else {
				result = await createCustomer(customerData)
				navigate(`/clientes/${result.newId}?versionEsperada=${result.VersionCatalogo}`)
			}
		} catch (requestError) {
			setError(requestError.message)
			setConflict(requestError.code === 'VERSION_OBSOLETA')
		} finally {
			setSaving(false)
		}
	}

	let title = 'Nuevo cliente'
	let description = 'Registre el cliente en el catálogo compartido.'
	if (isEditing) {
		title = 'Editar cliente'
		description = 'Los datos se guardan en Corporativo y luego se propagan a las sucursales.'
	}

	return (
		<>
			<PageHeader
				title={title}
				description={description}
				breadcrumbs={[{ label: definition.title, to: '/clientes' }, { label: title }]}
				actions={<BackButton route={definition.route} />}
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

			{loading ? <LoadingForm /> : (
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
	const { session } = useOutletContext()
	const isEditing = mode === 'edit'
	const [catalogValues, setCatalogValues] = useState(getEmptyValues(definition.formFields))
	const [holdingValues, setHoldingValues] = useState(getEmptyValues(definition.holdingsFields))
	const [catalogs, setCatalogs] = useState({})
	const [holdingAvailable, setHoldingAvailable] = useState(false)
	const [loading, setLoading] = useState(true)
	const [savingCatalog, setSavingCatalog] = useState(false)
	const [savingHolding, setSavingHolding] = useState(false)
	const [catalogError, setCatalogError] = useState('')
	const [holdingError, setHoldingError] = useState('')
	const [catalogMessage, setCatalogMessage] = useState('')
	const [holdingMessage, setHoldingMessage] = useState('')

	async function loadForm() {
		try {
			setLoading(true)
			setCatalogError('')
			setHoldingError('')
			let catalogId = null
			if (isEditing) {
				catalogId = id
			}
			const catalogData = await getInventoryEditCatalogs(catalogId)
			setCatalogs(catalogData)

			if (isEditing) {
				const central = await getInventoryCentral(id)
				setCatalogValues(central)

				try {
					const local = await getInventory(id)
					setHoldingValues(local)
					setHoldingAvailable(true)
				} catch (requestError) {
					if (requestError.status === 404 || requestError.code === 'CATALOGO_PENDIENTE') {
						setHoldingAvailable(false)
						setHoldingError('El producto todavía no llegó a esta sucursal. Compruebe de nuevo en unos segundos.')
					} else {
						setHoldingAvailable(false)
						setHoldingError(requestError.message)
					}
				}
			}
		} catch (requestError) {
			setCatalogError(requestError.message)
		} finally {
			setLoading(false)
		}
	}

	useEffect(() => {
		loadForm()
	}, [id, isEditing])

	function changeCatalogValue(name, value) {
		setCatalogValues({ ...catalogValues, [name]: value })
	}

	function changeHoldingValue(name, value) {
		setHoldingValues({ ...holdingValues, [name]: value })
	}

	async function saveCatalog() {
		try {
			setSavingCatalog(true)
			setCatalogError('')
			setCatalogMessage('')
			const data = prepareFormData(definition.formFields, catalogValues)

			if (isEditing) {
				const result = await updateInventory(id, {
					...data,
					VersionEsperada: catalogValues.VersionCatalogo,
				})
				setCatalogValues({ ...catalogValues, VersionCatalogo: result.VersionCatalogo })
				setCatalogMessage(result.message)
			} else {
				const result = await createInventory(data)
				navigate(`/inventario/${result.newId}?versionEsperada=${result.VersionCatalogo}`)
			}
		} catch (requestError) {
			setCatalogError(requestError.message)
		} finally {
			setSavingCatalog(false)
		}
	}

	async function saveLocalHolding() {
		try {
			setSavingHolding(true)
			setHoldingError('')
			setHoldingMessage('')
			const data = prepareFormData(definition.holdingsFields, holdingValues)
			const result = await saveHoldings(id, {
				...data,
				VersionEsperada: holdingValues.VersionExistencias || 0,
			})
			setHoldingValues({ ...holdingValues, VersionExistencias: result.VersionExistencias })
			setHoldingMessage(result.message)
		} catch (requestError) {
			setHoldingError(requestError.message)
		} finally {
			setSavingHolding(false)
		}
	}

	let title = 'Nuevo producto'
	let description = 'El producto se crea primero en el catálogo compartido.'
	let submitLabel = 'Crear producto'
	if (isEditing) {
		title = 'Editar producto'
		description = 'El catálogo compartido y las existencias locales se guardan por separado.'
		submitLabel = 'Guardar catálogo'
	}

	return (
		<>
			<PageHeader
				title={title}
				description={description}
				breadcrumbs={[{ label: definition.title, to: '/inventario' }, { label: title }]}
				actions={<BackButton route={definition.route} />}
			/>

			{catalogError && <CAlert color="danger">{catalogError}</CAlert>}
			{catalogMessage && <CAlert color="success">{catalogMessage}</CAlert>}

			{loading ? <LoadingForm /> : (
				<>
					<h2 className="h5 mt-2">Catálogo compartido</h2>
					<p className="text-body-secondary">Estos datos se administran en Corporativo.</p>
					<EntityForm
						definition={definition}
						mode={mode}
						fields={definition.formFields}
						values={catalogValues}
						catalogs={catalogs}
						saving={savingCatalog}
						submitLabel={submitLabel}
						cancelTo="/inventario"
						showInvoiceLines={false}
						onChange={changeCatalogValue}
						onSubmit={saveCatalog}
					/>

					{isEditing && (
						<div className="mt-5">
							<h2 className="h5">Existencias de {session.user.sucursalNombre}</h2>
							<p className="text-body-secondary">Estos valores pertenecen únicamente a la sucursal actual.</p>
							{holdingError && (
								<CAlert color="warning">
									{holdingError}
									<CButton color="warning" variant="outline" size="sm" className="ms-3" onClick={loadForm}>
										<CIcon icon={cilReload} className="me-2" />
										Comprobar llegada
									</CButton>
								</CAlert>
							)}
							{holdingMessage && <CAlert color="success">{holdingMessage}</CAlert>}
							{holdingAvailable && (
								<EntityForm
									definition={definition}
									mode="edit"
									fields={definition.holdingsFields}
									values={holdingValues}
									saving={savingHolding}
									submitLabel="Guardar existencias"
									showCancel={false}
									showInvoiceLines={false}
									onChange={changeHoldingValue}
									onSubmit={saveLocalHolding}
								/>
							)}
						</div>
					)}
				</>
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
