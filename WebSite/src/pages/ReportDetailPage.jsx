import { useEffect, useState } from 'react'
import { CAlert, CButton, CCard, CCardBody } from '@coreui/react'
import { CIcon } from '@coreui/icons-react'
import { cilArrowLeft, cilPrint } from '@coreui/icons'
import { Link, useParams } from 'react-router-dom'
import { reports } from '../config/reports'
import { getReport } from '../services/reportsApi'
import PageHeader from '../components/PageHeader'
import FilterPanel from '../components/FilterPanel'
import DataTable from '../components/DataTable'

export default function ReportDetailPage() {
  const { reportId } = useParams()
  const report = reports[reportId]
  
  const [data, setData] = useState([])
  const [filters, setFilters] = useState({})
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)

  useEffect(() => {
    if (report && report.status === 'available') {
        fetchReportData()
    }
  }, [reportId, report])

  async function fetchReportData() {
    try {
      setLoading(true)
      setError(null)
      const result = await getReport(reportId, filters)
      setData(result)
    } catch (err) {
      setError(err.message || 'Error al cargar los datos del reporte.')
    } finally {
      setLoading(false)
    }
  }

  function handleFilterChange(name, value) {
    setFilters(prev => ({
      ...prev,
      [name]: value
    }))
  }

  function handleFilterSubmit() {
    fetchReportData()
  }

  function handleFilterReset() {
    setFilters({})
    setTimeout(() => {
        fetchReportData()
    }, 0)
  }

  if (!report) {
    return <CAlert color="danger">El reporte solicitado no existe.</CAlert>
  }

  const actions = (
    <>
      <CButton as={Link} color="secondary" variant="outline" to="/reportes">
        <CIcon icon={cilArrowLeft} className="me-2" />
        Volver
      </CButton>
      <CButton color="primary" variant="outline" disabled>
        <CIcon icon={cilPrint} className="me-2" />
        Imprimir
      </CButton>
    </>
  )

  return (
    <>
      <PageHeader
        title={report.title}
        description={report.description}
        breadcrumbs={[{ label: 'Reportes', to: '/reportes' }, { label: `Reporte ${reportId}` }]}
        actions={actions}
      />

      {error && <CAlert color="danger">{error}</CAlert>}

      {report.status === 'pending' ? (
        <CAlert color="warning">
          Este reporte todavía no tiene un procedimiento almacenado definido.
        </CAlert>
      ) : (
        <>
          <FilterPanel 
            fields={report.filters}
            values={filters}
            loading={loading}
            onChange={handleFilterChange}
            onSubmit={handleFilterSubmit}
            onReset={handleFilterReset}
          />
          
          <CCard className="shadow-sm result-card mt-4">
            <CCardBody className="p-0">
              <div className="result-toolbar p-3 border-bottom">
                <strong>Resultados</strong>
              </div>
              
              <DataTable 
                columns={report.columns} 
                rows={data} 
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