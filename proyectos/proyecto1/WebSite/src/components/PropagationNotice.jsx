import { useEffect, useRef, useState } from 'react'
import { CAlert, CButton } from '@coreui/react'
import { CIcon } from '@coreui/icons-react'
import { cilReload } from '@coreui/icons'

function getMessage(status) {
	if (!status) {
		return 'Comprobando la llegada del catálogo a la sucursal…'
	}
	if (status.estado === 'pendiente') {
		return 'El cambio fue confirmado en Corporativo y todavía no llegó a esta sucursal.'
	}
	if (status.estado === 'atrasado') {
		return 'La sucursal todavía muestra una versión anterior del catálogo.'
	}
	if (status.estado === 'recibido') {
		return 'La sucursal ya recibió la versión consultada.'
	}
	return 'No se pudo comprobar completamente la propagación en este momento.'
}

export default function PropagationNotice({ active, getStatus, onReceived }) {
	const [status, setStatus] = useState(null)
	const [checking, setChecking] = useState(false)
	const attempts = useRef(0)
	const timer = useRef(null)

	async function check() {
		if (!active || checking) {
			return
		}

		try {
			setChecking(true)
			const result = await getStatus()
			setStatus(result)
			attempts.current += 1

			if (result.estado === 'recibido') {
				onReceived()
			} else if (attempts.current < 5) {
				timer.current = window.setTimeout(check, 2000)
			}
		} catch {
			setStatus({ estado: 'no_comprobable' })
			attempts.current += 1
		} finally {
			setChecking(false)
		}
	}

	useEffect(() => {
		attempts.current = 0
		setStatus(null)
		check()

		return () => {
			if (timer.current) {
				window.clearTimeout(timer.current)
			}
		}
	}, [active])

	if (!active) {
		return null
	}

	let color = 'info'
	if (status && status.estado === 'recibido') {
		color = 'success'
	}

	let buttonText = 'Comprobar llegada'
	if (checking) {
		buttonText = 'Comprobando…'
	}

	return (
		<CAlert color={color}>
			<div className="d-flex flex-wrap align-items-center justify-content-between gap-2">
				<span>{getMessage(status)}</span>
				<CButton color="info" variant="outline" size="sm" onClick={check} disabled={checking}>
					<CIcon icon={cilReload} className="me-2" />
					{buttonText}
				</CButton>
			</div>
		</CAlert>
	)
}
