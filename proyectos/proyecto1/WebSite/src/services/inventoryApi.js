import { request } from './request'

export function getInventories(filters = {}) {
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
	return request(`/inventory${suffix}`)
}

export function getInventory(id) {
	return request(`/inventory/${id}`)
}

export function getInventoryCentral(id) {
	return request(`/inventory/${id}/catalog`)
}

export function getInventoryCatalogs() {
	return request('/inventory/catalogs')
}

export function getInventoryEditCatalogs(id = null) {
	let suffix = ''
	if (id) {
		suffix = `?StockItemID=${id}`
	}
	return request(`/inventory/edit-catalogs${suffix}`)
}

export function getInventorySyncStatus(id) {
	return request(`/inventory/${id}/sync-status`)
}

export function createInventory(inventory) {
	return request('/inventory', {
		method: 'POST',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify(inventory),
	})
}

export function updateInventory(id, inventory) {
	return request(`/inventory/${id}`, {
		method: 'PUT',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify(inventory),
	})
}

export function saveHoldings(id, holdings) {
	return request(`/inventory/${id}/holdings`, {
		method: 'PUT',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify(holdings),
	})
}

export function deleteInventory(id, VersionEsperada) {
	return request(`/inventory/${id}`, {
		method: 'DELETE',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify({ VersionEsperada }),
	})
}
