import { CCard, CCardBody } from '@coreui/react'

export default function LocationCard({ latitude, longitude }) {
  const hasLocation = latitude !== null
    && latitude !== undefined
    && longitude !== null
    && longitude !== undefined

  let mapUrl = ''

  if (hasLocation) {
    mapUrl = `https://maps.google.com/maps?q=${latitude},${longitude}&z=15&output=embed`
  }

  return (
    <CCard className="detail-card shadow-sm">
      <CCardBody>
        <h2 className="h6 mb-3">Ubicación de entrega</h2>
        {hasLocation ? (
          <iframe
            className="location-map"
            src={mapUrl}
            title="Mapa de ubicación de entrega"
            loading="lazy"
          />
        ) : (
          <div className="location-map d-flex align-items-center justify-content-center text-body-secondary">
            No hay una ubicación registrada.
          </div>
        )}
      </CCardBody>
    </CCard>
  )
}
