import { useEffect, useState } from 'react'
import { CAlert, CButton, CSpinner } from '@coreui/react'
import { CIcon } from '@coreui/icons-react'
import { cilArrowLeft, cilPencil, cilReload, cilTrash } from '@coreui/icons'
import { Link, useNavigate, useParams, useSearchParams } from 'react-router-dom'
import { entities } from '../config/entities'
import {
	deleteCustomer,
	getCustomer,
	getCustomerEditData,
	getCustomerPrivate,
	getCustomerSyncStatus,
} from '../services/customerApi'
import {
	deleteInventory,
	getInventory,
	getInventoryCentral,
	getInventorySyncStatus,
} from '../services/inventoryApi'
import PageHeader from '../components/PageHeader'
import DetailSection from '../components/DetailSection'
import LocationCard from '../components/LocationCard'
import PropagationNotice from '../components/PropagationNotice'
import SupplierDetailPage from './SupplierDetailPage'
import SaleDetailPage from './SaleDetailPage'

function LoadingDetail({ text }) {
	return (
		<div className="text-center py-5">
			<CSpinner color="primary" />
			<div className="text-body-secondary mt-2">{text}</div>
		</div>
	)
}

function CustomerDetailPage({ definition }) {
	const { id } = useParams()
	const [searchParams] = useSearchParams()
	const navigate = useNavigate()
	const expectedVersion = Number(searchParams.get('versionEsperada')) || null
	const [customer, setCustomer] = useState(null)
	const [centralCustomer, setCentralCustomer] = useState(null)
	const [privateData, setPrivateData] = useState(null)
	const [loading, setLoading] = useState(true)
	const [privateLoading, setPrivateLoading] = useState(true)
	const [localMissing, setLocalMissing] = useState(false)
	const [error, setError] = useState('')
	const [privateError, setPrivateError] = useState('')

	async function loadPublicCustomer() {
		try {
			setLoading(true)
			setError('')
			const data = await getCustomer(id)
			setCustomer(data)
			setLocalMissing(false)
		} catch (requestError) {
			setCustomer(null)
			if (requestError.status === 404) {
				setLocalMissing(true)
				try {
					setCentralCustomer(await getCustomerEditData(id))
				} catch (centralError) {
					setError(centralError.message)
				}
			} else {
				setError(requestError.message)
			}
		} finally {
			setLoading(false)
		}
	}

	async function loadPrivateCustomer() {
		try {
			setPrivateLoading(true)
			setPrivateError('')
			setPrivateData(await getCustomerPrivate(id))
		} catch (requestError) {
			setPrivateData(null)
			setPrivateError('No se pudieron cargar los datos privados. ' + requestError.message)
		} finally {
			setPrivateLoading(false)
		}
	}

	useEffect(() => {
		loadPublicCustomer()
		loadPrivateCustomer()
	}, [id])

	async function removeCustomer() {
		const record = customer || centralCustomer
		const version = privateData?.VersionCatalogo || centralCustomer?.VersionCatalogo || customer?.VersionCatalogo
		const confirmed = window.confirm(`¿Desea eliminar al cliente "${record.CustomerName}"?`)
		if (!confirmed) return

		try {
			await deleteCustomer(id, version)
			navigate('/clientes')
		} catch (requestError) {
			setError(requestError.message)
		}
	}

	const record = customer || centralCustomer
	const needsSync = localMissing
		|| Boolean(expectedVersion && customer && customer.VersionCatalogo < expectedVersion)

	const actions = (
		<>
			<CButton as={Link} color="secondary" variant="outline" to="/clientes">
				<CIcon icon={cilArrowLeft} className="me-2" />Volver
			</CButton>
			<CButton as={Link} color="primary" to={`/clientes/${id}/editar`} disabled={!record}>
				<CIcon icon={cilPencil} className="me-2" />Editar
			</CButton>
			<CButton color="danger" variant="outline" onClick={removeCustomer} disabled={!record}>
				<CIcon icon={cilTrash} className="me-2" />Eliminar
			</CButton>
		</>
	)

	return (
		<>
			<PageHeader
				title={record?.CustomerName || 'Detalle del cliente'}
				description="Información pública de la sucursal y datos privados autorizados de Corporativo."
				breadcrumbs={[{ label: definition.title, to: '/clientes' }, { label: 'Detalle' }]}
				actions={actions}
			/>

			{error && <CAlert color="danger">{error}</CAlert>}
			<PropagationNotice
				active={needsSync}
				getStatus={() => getCustomerSyncStatus(id)}
				onReceived={loadPublicCustomer}
			/>

			{loading && <LoadingDetail text="Cargando cliente…" />}

			{customer && (
				<div className="detail-grid mb-4">
					{definition.detailSections.map((section) => (
						<DetailSection key={section.title} title={section.title} fields={section.fields} record={customer} />
					))}
				</div>
			)}

			<h2 className="h5 mt-4">Datos privados</h2>
			{privateLoading && <div className="text-body-secondary mb-3">Cargando datos privados…</div>}
			{privateError && (
				<CAlert color="warning">
					{privateError}
					<CButton color="warning" variant="outline" size="sm" className="ms-3" onClick={loadPrivateCustomer}>
						<CIcon icon={cilReload} className="me-2" />Reintentar
					</CButton>
				</CAlert>
			)}
			{privateData && (
				<>
					<div className="detail-grid mb-4">
						{definition.privateDetailSections.map((section) => (
							<DetailSection key={section.title} title={section.title} fields={section.fields} record={privateData} />
						))}
					</div>
					<LocationCard latitude={privateData.DeliveryLatitude} longitude={privateData.DeliveryLongitude} />
				</>
			)}
		</>
	)
}

function InventoryDetailPage({ definition }) {
	const { id } = useParams()
	const [searchParams] = useSearchParams()
	const navigate = useNavigate()
	const expectedVersion = Number(searchParams.get('versionEsperada')) || null
	const [inventory, setInventory] = useState(null)
	const [centralInventory, setCentralInventory] = useState(null)
	const [loading, setLoading] = useState(true)
	const [localMissing, setLocalMissing] = useState(false)
	const [error, setError] = useState('')
	const [centralError, setCentralError] = useState('')

	async function loadInventory() {
		setLoading(true)
		setError('')
		setCentralError('')

		try {
			const localData = await getInventory(id)
			setInventory(localData)
			setLocalMissing(false)
		} catch (requestError) {
			setInventory(null)
			if (requestError.status === 404) {
				setLocalMissing(true)
			} else {
				setError(requestError.message)
			}
		}

		try {
			const centralData = await getInventoryCentral(id)
			setCentralInventory(centralData)
		} catch (requestError) {
			setCentralError(requestError.message)
		}

		setLoading(false)
	}

	useEffect(() => {
		loadInventory()
	}, [id])

	async function removeInventory() {
		const record = inventory || centralInventory
		const version = centralInventory?.VersionCatalogo || inventory?.VersionCatalogo
		const confirmed = window.confirm(`¿Desea eliminar el producto "${record.StockItemName}"?`)
		if (!confirmed) return

		try {
			await deleteInventory(id, version)
			navigate('/inventario')
		} catch (requestError) {
			setError(requestError.message)
		}
	}

	const record = inventory || centralInventory
	const needsSync = localMissing
		|| Boolean(expectedVersion && inventory && inventory.VersionCatalogo < expectedVersion)

	return (
		<>
			<PageHeader
				title={record?.StockItemName || 'Detalle del producto'}
				description="Catálogo compartido y existencias propias de la sucursal actual."
				breadcrumbs={[{ label: definition.title, to: '/inventario' }, { label: 'Detalle' }]}
				actions={(
					<>
						<CButton as={Link} color="secondary" variant="outline" to="/inventario">
							<CIcon icon={cilArrowLeft} className="me-2" />Volver
						</CButton>
						<CButton as={Link} color="primary" to={`/inventario/${id}/editar`} disabled={!centralInventory}>
							<CIcon icon={cilPencil} className="me-2" />Editar
						</CButton>
						<CButton color="danger" variant="outline" onClick={removeInventory} disabled={!record}>
							<CIcon icon={cilTrash} className="me-2" />Eliminar
						</CButton>
					</>
				)}
			/>

			{error && <CAlert color="danger">{error}</CAlert>}
			{centralError && <CAlert color="warning">No se pudo consultar el catálogo central. {centralError}</CAlert>}
			<PropagationNotice
				active={needsSync}
				getStatus={() => getInventorySyncStatus(id)}
				onReceived={loadInventory}
			/>

			{loading && <LoadingDetail text="Cargando producto…" />}

			{record && (
				<>
					<h2 className="h5">Catálogo compartido</h2>
					<div className="detail-grid mb-4">
						{definition.detailSections.map((section) => (
							<DetailSection key={section.title} title={section.title} fields={section.fields} record={record} />
						))}
					</div>
				</>
			)}

			{inventory && (
				<>
					<h2 className="h5 mt-4">Existencias de la sucursal</h2>
					<div className="detail-grid mb-4">
						{definition.holdingsDetailSections.map((section) => (
							<DetailSection key={section.title} title={section.title} fields={section.fields} record={inventory} />
						))}
					</div>
				</>
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
