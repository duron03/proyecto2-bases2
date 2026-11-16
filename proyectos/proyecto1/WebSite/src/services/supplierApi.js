import { request } from './request'

export function getSuppliers(filters = {}) {
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
	return request(`/suppliers${suffix}`)
}

export function getSupplier(id) {
	return request(`/suppliers/${id}`)
}

export function getSupplierPrivate(id) {
	return request(`/suppliers/${id}/private`)
}

export function getSupplierEditData(id) {
	return request(`/suppliers/${id}/edit-data`)
}

export function getSupplierCatalogs() {
	return request('/suppliers/catalogs')
}

export function getSupplierEditCatalogs(id = null) {
	let suffix = ''
	if (id) {
		suffix = `?SupplierID=${id}`
	}
	return request(`/suppliers/edit-catalogs${suffix}`)
}

export function getSupplierSyncStatus(id) {
	return request(`/suppliers/${id}/sync-status`)
}

export function createSupplier(supplier) {
	return request('/suppliers', {
		method: 'POST',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify(supplier),
	})
}

export function updateSupplier(id, supplier) {
	return request(`/suppliers/${id}`, {
		method: 'PUT',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify(supplier),
	})
}

export function deleteSupplier(id, VersionEsperada) {
	return request(`/suppliers/${id}`, {
		method: 'DELETE',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify({ VersionEsperada }),
	})
}
