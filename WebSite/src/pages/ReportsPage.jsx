import { CBadge, CCard, CCardBody, CCol, CRow } from '@coreui/react'
import { CIcon } from '@coreui/icons-react'
import { cilChartLine } from '@coreui/icons'
import { Link } from 'react-router-dom'
import PageHeader from '../components/PageHeader'
import { reports } from '../config/reports'

function ReportCard({ id, report }) {
  const available = report.status === 'available'
  const cardClass = available
    ? 'report-card shadow-sm h-100'
    : 'report-card shadow-sm h-100 is-pending'
  const badgeColor = available ? 'success' : 'secondary'
  const badgeText = available ? 'Prototipo' : 'Pendiente'

  return (
    <CCol md={6} xl={4}>
      <CCard className={cardClass}>
        <CCardBody>
          <div className="d-flex align-items-start justify-content-between gap-3 mb-3">
            <div className="module-icon text-bg-primary">
              <CIcon icon={cilChartLine} size="xl" />
            </div>
            <CBadge color={badgeColor}>{badgeText}</CBadge>
          </div>
          <span className="small text-body-secondary">Reporte {id}</span>
          <h2 className="h5 mt-1">{report.shortTitle}</h2>
          <p className="text-body-secondary mb-0">{report.description}</p>
          {available && (
            <Link className="stretched-link" to={`/reportes/${id}`}>
              <span className="visually-hidden">Abrir reporte {id}</span>
            </Link>
          )}
        </CCardBody>
      </CCard>
    </CCol>
  )
}

export default function ReportsPage() {
  return (
    <>
      <PageHeader
        title="Reportes estadísticos"
        description="Prototipos de las pantallas para consultar los reportes estadísticos."
      />
      <CRow className="g-4">
        {Object.entries(reports).map(([id, report]) => (
          <ReportCard key={id} id={id} report={report} />
        ))}
      </CRow>
    </>
  )
}
