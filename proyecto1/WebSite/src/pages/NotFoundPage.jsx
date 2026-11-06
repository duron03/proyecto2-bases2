import { CButton, CCard, CCardBody } from '@coreui/react'
import { Link } from 'react-router-dom'

export default function NotFoundPage() {
  return (
    <CCard className="shadow-sm not-found-card">
      <CCardBody className="text-center py-5">
        <div className="display-3 fw-bold text-primary">404</div>
        <h1 className="h3">Página no encontrada</h1>
        <p className="text-body-secondary">La dirección solicitada no existe dentro de la aplicación.</p>
        <CButton as={Link} to="/" color="primary">Volver al resumen</CButton>
      </CCardBody>
    </CCard>
  )
}
