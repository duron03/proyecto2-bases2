const API_URL = '/api'

async function request(path, options = {}) {
    const response = await fetch(`${API_URL}${path}`, options)
    const data = await response.json()

    if (!response.ok) {
        throw new Error(data.error || 'No fue posible completar la solicitud.')
    }

    return data
}

export function getReport(id, filters = {}) {
    const query = new URLSearchParams()

    if (filters.CustomerName) {
        query.append('CustomerName', filters.CustomerName)
    }

    if (filters.CustomerCategoryName) {
        query.append('CustomerCategoryName', filters.CustomerCategoryName)
    }

    if (filters.SupplierName) {
        query.append('SupplierName', filters.SupplierName)
    }

    if (filters.SupplierCategoryName) {
        query.append('SupplierCategoryName', filters.SupplierCategoryName)
    }

    if (filters.StockItemName) {
        query.append('StockItemName', filters.StockItemName)
    }

    if (filters.StockGroupName) {
        query.append('StockGroupName', filters.StockGroupName)
    }

    if (filters.Year) {
        query.append('Year', filters.Year)
    }

    if (filters.Month) {
        query.append('Month', filters.Month)
    }

    const queryString = query.toString()
    let path = `/reports/${id}`

    if (queryString) {
        path = `/reports/${id}?${queryString}`
    }

    return request(path)
}
