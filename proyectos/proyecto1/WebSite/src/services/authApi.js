import { clearToken, getToken, request, saveToken } from './request'

export async function login(username, password) {
	const data = await request('/auth/login', {
		method: 'POST',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify({ username, password }),
	}, false)

	saveToken(data.token)
	return data
}

export function getSession() {
	if (!getToken()) {
		return Promise.resolve(null)
	}

	return request('/auth/session')
}

export async function logout() {
	try {
		if (getToken()) {
			await request('/auth/logout', { method: 'POST' })
		}
	} finally {
		clearToken()
	}
}
