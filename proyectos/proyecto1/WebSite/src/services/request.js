const API_URL = '/api'
const TOKEN_KEY = 'wwi_token'

export function getToken() {
	return sessionStorage.getItem(TOKEN_KEY)
}

export function saveToken(token) {
	sessionStorage.setItem(TOKEN_KEY, token)
}

export function clearToken() {
	sessionStorage.removeItem(TOKEN_KEY)
}

export async function request(path, options = {}, handleInvalidSession = true) {
	const headers = Object.assign({}, options.headers || {})
	const token = getToken()

	if (token) {
		headers.Authorization = `Bearer ${token}`
	}

	let response

	try {
		const requestOptions = Object.assign({}, options)
		requestOptions.headers = headers
		response = await fetch(`${API_URL}${path}`, requestOptions)
	} catch {
		const error = new Error('No fue posible comunicarse con la API.')
		error.status = 0
		error.code = 'API_NO_DISPONIBLE'
		throw error
	}
	const text = await response.text()
	let data = null

	if (text) {
		try {
			data = JSON.parse(text)
		} catch {
			data = { error: 'El servidor devolvió una respuesta que no se pudo leer.' }
		}
	}

	if (!response.ok) {
		if (response.status === 401 && handleInvalidSession) {
			clearToken()
			window.dispatchEvent(new Event('wwi-session-expired'))
		}

		let message = 'No fue posible completar la solicitud.'
		let code = 'ERROR_SOLICITUD'
		if (data && data.error) {
			message = data.error
		}
		if (data && data.code) {
			code = data.code
		}

		const error = new Error(message)
		error.status = response.status
		error.code = code
		throw error
	}

	return data
}
