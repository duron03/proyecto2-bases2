import { CButton, CContainer, CHeader } from '@coreui/react'

export default function AppHeader({ session, onLogout }) {
	const user = session.user
	let roleName = 'Administrador'
	if (user.rol === 'CORPORATIVO') {
		roleName = 'Corporativo'
	}
	const locationName = user.sucursalNombre || 'Vista corporativa'

	return (
		<CHeader position="sticky" className="app-header border-bottom">
			<CContainer fluid className="justify-content-end gap-3">
				<div className="text-end">
					<div className="fw-semibold">{user.fullname}</div>
					<div className="small text-body-secondary">{roleName} · {locationName}</div>
				</div>
				<CButton color="secondary" variant="outline" size="sm" onClick={onLogout}>
					Cerrar sesión
				</CButton>
			</CContainer>
		</CHeader>
	)
}
