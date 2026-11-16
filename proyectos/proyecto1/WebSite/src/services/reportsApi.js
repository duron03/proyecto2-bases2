import { request } from './request'

function getQuery(filters = {}) {
	const query = new URLSearchParams()
	for (const name in filters) {
		const value = filters[name]
		if (value !== '' && value !== null && value !== undefined) {
			query.append(name, value)
		}
	}
	return query.toString()
}

export function getReport(id, filters = {}) {
	const query = getQuery(filters)
	let suffix = ''
	if (query) {
		suffix = `?${query}`
	}
	return request(`/reports/${id}${suffix}`)
}

export function getReportCatalogs(sucursal) {
	const query = getQuery({ sucursal })
	let suffix = ''
	if (query) {
		suffix = `?${query}`
	}
	return request(`/reports/catalogs${suffix}`)
}

export function getCorporateSummary(filters = {}) {
	const query = getQuery(filters)
	let suffix = ''
	if (query) {
		suffix = `?${query}`
	}
	return request(`/corporate/summary${suffix}`)
}
