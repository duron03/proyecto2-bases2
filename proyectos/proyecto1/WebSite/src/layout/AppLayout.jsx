import { CContainer } from '@coreui/react'
import { Outlet } from 'react-router-dom'
import AppHeader from './AppHeader'
import AppSidebar from './AppSidebar'

export default function AppLayout({ session, onLogout }) {
	return (
		<div className="app-shell">
			<AppSidebar session={session} />
			<div className="wrapper d-flex flex-column min-vh-100">
				<AppHeader session={session} onLogout={onLogout} />
				<main className="body flex-grow-1">
					<CContainer fluid className="app-content">
						<Outlet context={{ session }} />
					</CContainer>
				</main>
			</div>
		</div>
	)
}
