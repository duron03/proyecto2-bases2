import { request } from './request'

export function getCustomers(filters = {}) {
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
	return request(`/customers${suffix}`)
}

export function getCustomer(id) {
	return request(`/customers/${id}`)
}

export function getCustomerPrivate(id) {
	return request(`/customers/${id}/private`)
}

export function getCustomerEditData(id) {
	return request(`/customers/${id}/edit-data`)
}

export function getCustomerCatalogs() {
	return request('/customers/catalogs')
}

export function getCustomerEditCatalogs(id = null) {
	let suffix = ''
	if (id) {
		suffix = `?CustomerID=${id}`
	}
	return request(`/customers/edit-catalogs${suffix}`)
}

export function getCustomerSyncStatus(id) {
	return request(`/customers/${id}/sync-status`)
}

export function getCities(cityName) {
	const query = new URLSearchParams({ name: cityName })
	return request(`/cities?${query.toString()}`)
}

export function createCustomer(customer) {
	return request('/customers', {
		method: 'POST',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify(customer),
	})
}

export function updateCustomer(id, customer) {
	return request(`/customers/${id}`, {
		method: 'PUT',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify(customer),
	})
}

export function deleteCustomer(id, VersionEsperada) {
	return request(`/customers/${id}`, {
		method: 'DELETE',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify({ VersionEsperada }),
	})
}
