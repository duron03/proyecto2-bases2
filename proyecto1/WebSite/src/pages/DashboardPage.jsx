import { CButton, CCard, CCardBody, CCol, CRow } from '@coreui/react'
import { CIcon } from '@coreui/icons-react'
import { cilCart, cilChartLine, cilPeople, cilStorage, cilTruck } from '@coreui/icons'
import { Link } from 'react-router-dom'
import PageHeader from '../components/PageHeader'

const modules = [
  { key: 'customers', label: 'Clientes', description: 'Directorio y condiciones comerciales', to: '/clientes', icon: cilPeople, color: 'primary' },
  { key: 'suppliers', label: 'Proveedores', description: 'Contactos, bancos y logística', to: '/proveedores', icon: cilTruck, color: 'info' },
  { key: 'inventory', label: 'Inventario', description: 'Productos y existencias', to: '/inventario', icon: cilStorage, color: 'warning' },
  { key: 'sales', label: 'Ventas', description: 'Facturas y líneas de detalle', to: '/ventas', icon: cilCart, color: 'success' },
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

export default function DashboardPage() {
  return (
    <>
      <PageHeader
        title="Resumen"
        description="Acceso rápido a la gestión operativa y los reportes de Wide World Importers."
      />
      <CRow className="g-4 mb-4">
        {modules.map((module) => (
          <ModuleCard key={module.key} module={module} />
        ))}
      </CRow>
      <CRow className="g-4">
        <CCol xs={12}>
          <CCard className="shadow-sm h-100">
            <CCardBody>
              <div className="d-flex align-items-start gap-3">
                <div className="module-icon text-bg-primary"><CIcon icon={cilChartLine} size="xl" /></div>
                <div className="flex-grow-1">
                  <h2 className="h5">Reportes estadísticos</h2>
                  <p className="text-body-secondary">Diseño de las pantallas destinadas a presentar los resultados de los procedimientos almacenados.</p>
                  <CButton as={Link} to="/reportes" color="primary">Ver reportes</CButton>
                </div>
              </div>
            </CCardBody>
          </CCard>
        </CCol>
      </CRow>
    </>
  )
}
