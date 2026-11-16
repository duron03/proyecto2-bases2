import { useEffect, useState } from 'react'
import { CAlert, CSpinner } from '@coreui/react'
import { Navigate, Route, Routes } from 'react-router-dom'
import { getSession, logout } from './services/authApi'
import AppLayout from './layout/AppLayout'
import LoginPage from './pages/LoginPage'
import DashboardPage from './pages/DashboardPage'
import EntityListPage from './pages/EntityListPage'
import EntityDetailPage from './pages/EntityDetailPage'
import EntityFormPage from './pages/EntityFormPage'
import ReportsPage from './pages/ReportsPage'
import ReportDetailPage from './pages/ReportDetailPage'
import NotFoundPage from './pages/NotFoundPage'

function AccessDeniedPage() {
	return (
		<CAlert color="warning">
			Su usuario no tiene permiso para abrir este módulo.
		</CAlert>
	)
}

export default function App() {
	const [session, setSession] = useState(null)
	const [loading, setLoading] = useState(true)

	useEffect(() => {
		async function loadSession() {
			try {
				const data = await getSession()
				setSession(data)
			} catch {
				setSession(null)
			} finally {
				setLoading(false)
			}
		}

		function sessionExpired() {
			setSession(null)
		}

		loadSession()
		window.addEventListener('wwi-session-expired', sessionExpired)

		return () => window.removeEventListener('wwi-session-expired', sessionExpired)
	}, [])

	async function closeSession() {
		await logout()
		setSession(null)
	}

	if (loading) {
		return (
			<div className="login-page">
				<CSpinner color="primary" />
				<span>Comprobando sesión…</span>
			</div>
		)
	}

	if (!session) {
		return (
			<Routes>
				<Route path="/login" element={<LoginPage onLogin={setSession} />} />
				<Route path="*" element={<Navigate to="/login" replace />} />
			</Routes>
		)
	}

	const isAdministrator = session.user.rol === 'ADMINISTRADOR'

	return (
		<Routes>
			<Route path="/login" element={<Navigate to="/" replace />} />
			<Route element={<AppLayout session={session} onLogout={closeSession} />}>
				<Route index element={<DashboardPage />} />

				{isAdministrator ? (
					<>
						<Route path="clientes">
							<Route index element={<EntityListPage entityKey="customers" />} />
							<Route path="nuevo" element={<EntityFormPage entityKey="customers" mode="create" />} />
							<Route path=":id" element={<EntityDetailPage entityKey="customers" />} />
							<Route path=":id/editar" element={<EntityFormPage entityKey="customers" mode="edit" />} />
						</Route>

						<Route path="proveedores">
							<Route index element={<EntityListPage entityKey="suppliers" />} />
							<Route path="nuevo" element={<EntityFormPage entityKey="suppliers" mode="create" />} />
							<Route path=":id" element={<EntityDetailPage entityKey="suppliers" />} />
							<Route path=":id/editar" element={<EntityFormPage entityKey="suppliers" mode="edit" />} />
						</Route>

						<Route path="inventario">
							<Route index element={<EntityListPage entityKey="inventory" />} />
							<Route path="nuevo" element={<EntityFormPage entityKey="inventory" mode="create" />} />
							<Route path=":id" element={<EntityDetailPage entityKey="inventory" />} />
							<Route path=":id/editar" element={<EntityFormPage entityKey="inventory" mode="edit" />} />
						</Route>

						<Route path="ventas">
							<Route index element={<EntityListPage entityKey="sales" />} />
							<Route path="nuevo" element={<EntityFormPage entityKey="sales" mode="create" />} />
							<Route path=":id" element={<EntityDetailPage entityKey="sales" />} />
							<Route path=":id/editar" element={<EntityFormPage entityKey="sales" mode="edit" />} />
						</Route>
					</>
				) : (
					<>
						<Route path="clientes/*" element={<AccessDeniedPage />} />
						<Route path="proveedores/*" element={<AccessDeniedPage />} />
						<Route path="inventario/*" element={<AccessDeniedPage />} />
						<Route path="ventas/*" element={<AccessDeniedPage />} />
					</>
				)}

				<Route path="reportes" element={<ReportsPage />} />
				<Route path="reportes/:reportId" element={<ReportDetailPage />} />
				<Route path="inicio" element={<Navigate to="/" replace />} />
				<Route path="*" element={<NotFoundPage />} />
			</Route>
		</Routes>
	)
}
