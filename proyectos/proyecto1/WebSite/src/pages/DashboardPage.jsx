import { useEffect, useState } from 'react'
import { CAlert, CBadge, CButton, CCard, CCardBody, CCol, CRow } from '@coreui/react'
import { CIcon } from '@coreui/icons-react'
import { cilCart, cilChartLine, cilPeople, cilReload, cilStorage, cilTruck } from '@coreui/icons'
import { Link, useOutletContext } from 'react-router-dom'
import { getCorporateSummary } from '../services/reportsApi'
import { getSystemStatus } from '../services/systemApi'
import PageHeader from '../components/PageHeader'
import DataTable from '../components/DataTable'

const modules = [
	{ key: 'customers', label: 'Clientes', description: 'Directorio y condiciones comerciales', to: '/clientes', icon: cilPeople, color: 'primary' },
	{ key: 'suppliers', label: 'Proveedores', description: 'Contactos, bancos y logística', to: '/proveedores', icon: cilTruck, color: 'info' },
	{ key: 'inventory', label: 'Inventario', description: 'Catálogo compartido y existencias locales', to: '/inventario', icon: cilStorage, color: 'warning' },
	{ key: 'sales', label: 'Ventas', description: 'Facturas de la sucursal actual', to: '/ventas', icon: cilCart, color: 'success' },
]

const summaryColumns = [
	{ key: 'Anio', label: 'Año' },
	{ key: 'Mes', label: 'Mes' },
	{ key: 'CantidadFacturas', label: 'Facturas', type: 'integer', align: 'end' },
	{ key: 'CantidadUnidades', label: 'Unidades', type: 'integer', align: 'end' },
	{ key: 'MontoTotal', label: 'Monto total', type: 'currency', align: 'end' },
	{ key: 'Utilidad', label: 'Utilidad', type: 'currency', align: 'end' },
]

function ModuleCard({ module }) {
	return (
		<CCol xs={12} sm={6} xl={3}>
			<CCard className="module-card shadow-sm h-100">
				<CCardBody>
					<div className={`module-icon text-bg-${module.color}`}>
						<CIcon icon={module.icon} size="xl" />
					</div>
					<h2 className="h5 mb-1">{module.label}</h2>
					<p className="text-body-secondary mb-3">{module.description}</p>
					<Link className="stretched-link" to={module.to}>
						Abrir módulo
						<span className="visually-hidden"> de {module.label}</span>
					</Link>
				</CCardBody>
			</CCard>
		</CCol>
	)
}

function formatDate(value) {
	if (!value) {
		return 'Sin información'
	}
	return new Date(value).toLocaleString('es-CR')
}

function StateBadge({ state }) {
	let color = 'secondary'
	if (state === 'reciente' || state === 'correcto') {
		color = 'success'
	}
	if (state === 'atrasado') {
		color = 'warning'
	}
	if (state === 'sin_inicializar' || state === 'error') {
		color = 'danger'
	}
	return <CBadge color={color}>{state || 'desconocido'}</CBadge>
}

function StatusPanel({ status, isCorporate }) {
	if (!status) return null

	return (
		<CCard className="shadow-sm mb-4">
			<CCardBody>
				<h2 className="h5">Estado de distribución</h2>
				{!isCorporate && (
					<div className="status-row">
						<div>
							<strong>Catálogo compartido en esta sede</strong>
							<div className="small text-body-secondary">
								Última señal replicada: {formatDate(status.catalogo?.ultimoLatidoUtc)}
							</div>
						</div>
						<StateBadge state={status.catalogo?.estado} />
					</div>
				)}

				{status.sources?.map((source) => (
					<div className="status-row" key={source.SucursalID || source.sucursal}>
						<div>
							<strong>{source.SucursalNombre || source.sucursal}</strong>
							<div className="small text-body-secondary">
								Última señal replicada: {formatDate(source.ultimoLatidoUtc)}
							</div>
						</div>
						<StateBadge state={source.estado} />
					</div>
				))}

				{isCorporate && (
					<div className="status-row">
						<div>
							<strong>Resumen mensual materializado</strong>
							<div className="small text-body-secondary">
								Última actualización: {formatDate(status.materializacion?.UltimoExitoUtc)}
							</div>
						</div>
						<StateBadge state={status.materializacion?.estado} />
					</div>
				)}
			</CCardBody>
		</CCard>
	)
}

function AdminDashboard({ session, status, loading, error, onRefresh }) {
	return (
		<>
			<PageHeader
				title={`Resumen de ${session.user.sucursalNombre}`}
				description="Acceso a la operación de su sucursal y a los reportes autorizados."
				actions={(
					<CButton color="secondary" variant="outline" onClick={onRefresh} disabled={loading}>
						<CIcon icon={cilReload} className="me-2" />
						Actualizar estado
					</CButton>
				)}
			/>
			{error && <CAlert color="warning">{error}</CAlert>}
			<StatusPanel status={status} isCorporate={false} />
			<CRow className="g-4 mb-4">
				{modules.map((module) => <ModuleCard key={module.key} module={module} />)}
			</CRow>
			<CCard className="shadow-sm">
				<CCardBody className="d-flex align-items-start gap-3">
					<div className="module-icon text-bg-primary"><CIcon icon={cilChartLine} size="xl" /></div>
					<div className="flex-grow-1">
						<h2 className="h5">Reportes estadísticos</h2>
						<p className="text-body-secondary">Consulte los resultados calculados para su propia sucursal.</p>
						<CButton as={Link} to="/reportes" color="primary">Ver reportes</CButton>
					</div>
				</CCardBody>
			</CCard>
		</>
	)
}

function CorporateDashboard({ status, summary, loading, error, onRefresh }) {
	return (
		<>
			<PageHeader
				title="Resumen corporativo"
				description="Resumen mensual consolidado y estado de las fuentes distribuidas."
				actions={(
					<CButton color="primary" variant="outline" onClick={onRefresh} disabled={loading}>
						<CIcon icon={cilReload} className="me-2" />
						Actualizar
					</CButton>
				)}
			/>
			{error && <CAlert color="warning">{error}</CAlert>}
			<StatusPanel status={status} isCorporate />

			{summary && (
				<CCard className="shadow-sm result-card">
					<CCardBody className="p-0">
						<div className="result-toolbar">
							<div>
								<strong>Ventas mensuales · {summary.scope.nombre}</strong>
								<div className="small text-body-secondary">
									Materializado: {formatDate(summary.materializedAtUtc)}
								</div>
							</div>
							<StateBadge state={summary.status} />
						</div>
						<DataTable
							columns={summaryColumns}
							rows={summary.rows}
							idField="Mes"
							loading={loading}
							showActions={false}
						/>
					</CCardBody>
				</CCard>
			)}
		</>
	)
}

export default function DashboardPage() {
	const { session } = useOutletContext()
	const isCorporate = session.user.rol === 'CORPORATIVO'
	const [status, setStatus] = useState(null)
	const [summary, setSummary] = useState(null)
	const [loading, setLoading] = useState(true)
	const [error, setError] = useState('')

	async function loadDashboard() {
		setLoading(true)
		setError('')

		try {
			const statusData = await getSystemStatus()
			setStatus(statusData)
		} catch (requestError) {
			setError(requestError.message)
		}

		if (isCorporate) {
			try {
				const summaryData = await getCorporateSummary({ sucursal: 'TODAS' })
				setSummary(summaryData)
			} catch (requestError) {
				setError(requestError.message)
			}
		}

		setLoading(false)
	}

	useEffect(() => {
		loadDashboard()
	}, [isCorporate])

	if (isCorporate) {
		return (
			<CorporateDashboard
				status={status}
				summary={summary}
				loading={loading}
				error={error}
				onRefresh={loadDashboard}
			/>
		)
	}

	return (
		<AdminDashboard
			session={session}
			status={status}
			loading={loading}
			error={error}
			onRefresh={loadDashboard}
		/>
	)
}
