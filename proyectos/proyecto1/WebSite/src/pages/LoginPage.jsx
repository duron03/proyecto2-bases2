import { useState } from 'react'
import { CAlert, CButton, CCard, CCardBody, CForm, CFormInput, CFormLabel } from '@coreui/react'
import { login } from '../services/authApi'

export default function LoginPage({ onLogin }) {
	const [username, setUsername] = useState('')
	const [password, setPassword] = useState('')
	const [loading, setLoading] = useState(false)
	const [error, setError] = useState('')

	async function submit(event) {
		event.preventDefault()

		try {
			setLoading(true)
			setError('')
			const data = await login(username.trim(), password)
			setPassword('')
			onLogin({ user: data.user, expiresAt: data.expiresAt })
		} catch (requestError) {
			setPassword('')
			setError(requestError.message)
		} finally {
			setLoading(false)
		}
	}

	return (
		<div className="login-page">
			<CCard className="login-card shadow-sm">
				<CCardBody>
					<div className="mb-4">
						<span className="text-body-secondary small">Wide World Importers</span>
						<h1 className="h3 mb-1">Iniciar sesión</h1>
						<p className="text-body-secondary mb-0">Ingrese con el usuario asignado a su sede.</p>
					</div>

					{error && <CAlert color="danger">{error}</CAlert>}

					<CForm onSubmit={submit}>
						<div className="mb-3">
							<CFormLabel htmlFor="username">Usuario</CFormLabel>
							<CFormInput
								id="username"
								value={username}
								maxLength={50}
								autoComplete="username"
								required
								autoFocus
								onChange={(event) => setUsername(event.target.value)}
							/>
						</div>
						<div className="mb-4">
							<CFormLabel htmlFor="password">Contraseña</CFormLabel>
							<CFormInput
								id="password"
								type="password"
								value={password}
								maxLength={128}
								autoComplete="current-password"
								required
								onChange={(event) => setPassword(event.target.value)}
							/>
						</div>
						<CButton type="submit" color="primary" className="w-100" disabled={loading}>
							{loading ? 'Ingresando…' : 'Ingresar'}
						</CButton>
					</CForm>
				</CCardBody>
			</CCard>
		</div>
	)
}
