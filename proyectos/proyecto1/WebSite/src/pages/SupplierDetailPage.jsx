import { useEffect, useState } from 'react'
import { CAlert, CButton, CSpinner } from '@coreui/react'
import { CIcon } from '@coreui/icons-react'
import { cilArrowLeft, cilPencil, cilReload, cilTrash } from '@coreui/icons'
import { Link, useNavigate, useParams, useSearchParams } from 'react-router-dom'
import {
	deleteSupplier,
	getSupplier,
	getSupplierEditData,
	getSupplierPrivate,
	getSupplierSyncStatus,
} from '../services/supplierApi'
import PageHeader from '../components/PageHeader'
import DetailSection from '../components/DetailSection'
import LocationCard from '../components/LocationCard'
import PropagationNotice from '../components/PropagationNotice'

export default function SupplierDetailPage({ definition }) {
	const { id } = useParams()
	const [searchParams] = useSearchParams()
	const navigate = useNavigate()
	const expectedVersion = Number(searchParams.get('versionEsperada')) || null
	const [supplier, setSupplier] = useState(null)
	const [centralSupplier, setCentralSupplier] = useState(null)
	const [privateData, setPrivateData] = useState(null)
	const [loading, setLoading] = useState(true)
	const [privateLoading, setPrivateLoading] = useState(true)
	const [localMissing, setLocalMissing] = useState(false)
	const [error, setError] = useState('')
	const [privateError, setPrivateError] = useState('')

	async function loadPublicSupplier() {
		try {
			setLoading(true)
			setError('')
			const data = await getSupplier(id)
			setSupplier(data)
			setLocalMissing(false)
		} catch (requestError) {
			setSupplier(null)
			if (requestError.status === 404) {
				setLocalMissing(true)
				try {
					setCentralSupplier(await getSupplierEditData(id))
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

	async function loadPrivateSupplier() {
		try {
			setPrivateLoading(true)
			setPrivateError('')
			setPrivateData(await getSupplierPrivate(id))
		} catch (requestError) {
			setPrivateData(null)
			setPrivateError('No se pudieron cargar los datos privados. ' + requestError.message)
		} finally {
			setPrivateLoading(false)
		}
	}

	useEffect(() => {
		loadPublicSupplier()
		loadPrivateSupplier()
	}, [id])

	async function removeSupplier() {
		const record = supplier || centralSupplier
		const version = privateData?.VersionCatalogo || centralSupplier?.VersionCatalogo || supplier?.VersionCatalogo
		const confirmed = window.confirm(`¿Desea eliminar el proveedor "${record.SupplierName}"?`)
		if (!confirmed) return

		try {
			await deleteSupplier(id, version)
			navigate('/proveedores')
		} catch (requestError) {
			setError(requestError.message)
		}
	}

	const record = supplier || centralSupplier
	const needsSync = localMissing
		|| Boolean(expectedVersion && supplier && supplier.VersionCatalogo < expectedVersion)

	return (
		<>
			<PageHeader
				title={record?.SupplierName || 'Detalle del proveedor'}
				description="Información pública de la sucursal y datos privados autorizados de Corporativo."
				breadcrumbs={[{ label: definition.title, to: '/proveedores' }, { label: 'Detalle' }]}
				actions={(
					<>
						<CButton as={Link} color="secondary" variant="outline" to="/proveedores">
							<CIcon icon={cilArrowLeft} className="me-2" />Volver
						</CButton>
						<CButton as={Link} color="primary" to={`/proveedores/${id}/editar`} disabled={!record}>
							<CIcon icon={cilPencil} className="me-2" />Editar
						</CButton>
						<CButton color="danger" variant="outline" onClick={removeSupplier} disabled={!record}>
							<CIcon icon={cilTrash} className="me-2" />Eliminar
						</CButton>
					</>
				)}
			/>

			{error && <CAlert color="danger">{error}</CAlert>}
			<PropagationNotice
				active={needsSync}
				getStatus={() => getSupplierSyncStatus(id)}
				onReceived={loadPublicSupplier}
			/>

			{loading && (
				<div className="text-center py-5">
					<CSpinner color="primary" />
					<div className="text-body-secondary mt-2">Cargando proveedor…</div>
				</div>
			)}

			{supplier && (
				<div className="detail-grid mb-4">
					{definition.detailSections.map((section) => (
						<DetailSection key={section.title} title={section.title} fields={section.fields} record={supplier} />
					))}
				</div>
			)}

			<h2 className="h5 mt-4">Datos privados</h2>
			{privateLoading && <div className="text-body-secondary mb-3">Cargando datos privados…</div>}
			{privateError && (
				<CAlert color="warning">
					{privateError}
					<CButton color="warning" variant="outline" size="sm" className="ms-3" onClick={loadPrivateSupplier}>
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
