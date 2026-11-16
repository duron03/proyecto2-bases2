import { useEffect, useState } from 'react'
import { CAlert, CBadge, CButton, CCard, CCardBody } from '@coreui/react'
import { CIcon } from '@coreui/icons-react'
import { cilArrowLeft, cilPrint } from '@coreui/icons'
import { Link, useOutletContext, useParams } from 'react-router-dom'
import { reports } from '../config/reports'
import { getReport, getReportCatalogs } from '../services/reportsApi'
import PageHeader from '../components/PageHeader'
import FilterPanel from '../components/FilterPanel'
import DataTable from '../components/DataTable'

const scopeOptions = [
	{ Value: 'TODAS', Label: 'Consolidado' },
	{ Value: 'SJ', Label: 'San José' },
	{ Value: 'LI', Label: 'Limón' },
]

function formatDate(value) {
	if (!value) {
		return 'Sin información'
	}
	return new Date(value).toLocaleString('es-CR')
}

function StateBadge({ state }) {
	let color = 'secondary'
	if (state === 'reciente') {
		color = 'success'
	}
	if (state === 'atrasado') {
		color = 'warning'
	}
	if (state === 'sin_inicializar') {
		color = 'danger'
	}
	return <CBadge color={color}>{state || 'desconocido'}</CBadge>
}

function getSourceName(source) {
	if (source.sucursal === 'SJ') {
		return 'San José'
	}
	return 'Limón'
}

function ReportMetadata({ result }) {
	if (!result) return null

	return (
		<CCard className="shadow-sm mb-4">
			<CCardBody>
				<div className="d-flex flex-wrap align-items-center justify-content-between gap-2 mb-3">
					<div>
						<strong>Alcance: {result.scope.nombre}</strong>
						<div className="small text-body-secondary">
							Consulta generada: {formatDate(result.generatedAtUtc)}
						</div>
					</div>
					<StateBadge state={result.status} />
				</div>
				{result.sources.map((source) => (
					<div className="status-row" key={source.sucursal}>
						<div>
							<strong>{getSourceName(source)}</strong>
							<div className="small text-body-secondary">
								Última señal replicada: {formatDate(source.ultimoLatidoUtc)}
							</div>
						</div>
						<StateBadge state={source.estado} />
					</div>
				))}
			</CCardBody>
		</CCard>
	)
}

export default function ReportDetailPage() {
	const { reportId } = useParams()
	const { session } = useOutletContext()
	const report = reports[reportId]
	const isCorporate = session.user.rol === 'CORPORATIVO'
	let ownScope = 'LI'
	if (session.user.SucursalID === 1) {
		ownScope = 'SJ'
	}
	let initialScope = ownScope
	if (isCorporate) {
		initialScope = 'TODAS'
	}
	const [result, setResult] = useState(null)
	const [filters, setFilters] = useState({ sucursal: initialScope })
	const [catalogs, setCatalogs] = useState({ scopes: scopeOptions, years: [], months: [] })
	const [loading, setLoading] = useState(false)
	const [error, setError] = useState('')

	async function loadCatalogs(scope) {
		try {
			const data = await getReportCatalogs(scope)
			setCatalogs({ scopes: scopeOptions, years: data.years, months: data.months })
		} catch (requestError) {
			setError(requestError.message)
		}
	}

	async function fetchReportData(selectedFilters = filters) {
		if (!report || report.status !== 'available') return

		try {
			setLoading(true)
			setError('')
			setResult(null)
			const data = await getReport(reportId, selectedFilters)
			setResult(data)
		} catch (requestError) {
			setError(requestError.message || 'Error al cargar los datos del reporte.')
		} finally {
			setLoading(false)
		}
	}

	useEffect(() => {
		const cleanFilters = { sucursal: initialScope }
		setFilters(cleanFilters)
		setResult(null)
		setError('')

		if (report && report.status === 'available') {
			loadCatalogs(initialScope)
			fetchReportData(cleanFilters)
		}
	}, [reportId, initialScope, report])

	function handleFilterChange(name, value) {
		const nextFilters = { ...filters, [name]: value }
		setFilters(nextFilters)

		if (name === 'sucursal') {
			loadCatalogs(value)
		}
	}

	function handleFilterReset() {
		const cleanFilters = { sucursal: initialScope }
		setFilters(cleanFilters)
		loadCatalogs(initialScope)
		fetchReportData(cleanFilters)
	}

	if (!report) {
		return <CAlert color="danger">El reporte solicitado no existe.</CAlert>
	}

	let filterFields = report.filters || []
	if (isCorporate) {
		const scopeField = { name: 'sucursal', label: 'Sucursal', type: 'select', catalog: 'scopes' }
		filterFields = [scopeField]
		for (const field of report.filters || []) {
			filterFields.push(field)
		}
	}

	return (
		<>
			<PageHeader
				title={report.title}
				description={report.description}
				breadcrumbs={[{ label: 'Reportes', to: '/reportes' }, { label: `Reporte ${reportId}` }]}
				actions={(
					<>
						<CButton as={Link} color="secondary" variant="outline" to="/reportes">
							<CIcon icon={cilArrowLeft} className="me-2" />Volver
						</CButton>
						<CButton color="primary" variant="outline" onClick={() => window.print()}>
							<CIcon icon={cilPrint} className="me-2" />Imprimir
						</CButton>
					</>
				)}
			/>

			{error && <CAlert color="danger">{error}</CAlert>}
			{!isCorporate && (
				<CAlert color="info">Alcance autorizado: {session.user.sucursalNombre}.</CAlert>
			)}
			{reportId === '6' && (
				<CAlert color="info">Este reporte conserva la matriz histórica 2013–2016.</CAlert>
			)}

			{report.status === 'pending' ? (
				<CAlert color="warning">El proyecto anterior no incluía un procedimiento para el reporte 9.</CAlert>
			) : (
				<>
					<FilterPanel
						fields={filterFields}
						values={filters}
						catalogs={catalogs}
						loading={loading}
						onChange={handleFilterChange}
						onSubmit={() => fetchReportData(filters)}
						onReset={handleFilterReset}
					/>

					<ReportMetadata result={result} />

					<CCard className="shadow-sm result-card">
						<CCardBody className="p-0">
							<div className="result-toolbar">
								<strong>Resultados</strong>
								{result && <span className="text-body-secondary">{result.rows.length} registros</span>}
							</div>
							<DataTable
								columns={report.columns}
								rows={result ? result.rows : []}
								loading={loading}
								showActions={false}
							/>
						</CCardBody>
					</CCard>
				</>
			)}
		</>
	)
}
