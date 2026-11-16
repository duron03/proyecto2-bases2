import { request } from './request'

export function getSales(filters = {}) {
	const query = new URLSearchParams()
	for (const name in filters) {
		const value = filters[name]
		if (value !== '' && value !== null && value !== undefined) {
			query.append(name, value)
		}
	}
	let suffix = ''
	if (query.toString()) {
		suffix = `?${query.toString()}`
	}
	return request(`/sales${suffix}`)
}

export function getSale(id) {
	return request(`/sales/${id}`)
}

export function getSaleCatalogs(id = null) {
	let suffix = ''
	if (id) {
		suffix = `?InvoiceID=${id}`
	}
	return request(`/sales/catalogs${suffix}`)
}

export function createSale(sale) {
	return request('/sales', {
		method: 'POST',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify(sale),
	})
}

export function updateSale(id, sale) {
	return request(`/sales/${id}`, {
		method: 'PUT',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify(sale),
	})
}

export function deleteSale(id, VersionEsperada) {
	return request(`/sales/${id}`, {
		method: 'DELETE',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify({ VersionEsperada }),
	})
}
