const API_URL = '/api'

async function request(path, options = {}) {
  const response = await fetch(`${API_URL}${path}`, options)
  const data = await response.json()

  if (!response.ok) {
    throw new Error(data.error || 'No fue posible completar la solicitud.')
  }

  return data
}

export function getSales(filters = {}) {
  const query = new URLSearchParams()

  if (filters.CustomerName) {
    query.append('CustomerName', filters.CustomerName)
  }

  if (filters.InvoiceDateFrom) {
    query.append('InvoiceDateFrom', filters.InvoiceDateFrom)
  }

  if (filters.InvoiceDateTo) {
    query.append('InvoiceDateTo', filters.InvoiceDateTo)
  }

  if (filters.MinimumInvoiceAmount) {
    query.append('MinimumInvoiceAmount', filters.MinimumInvoiceAmount)
  }

  if (filters.MaximumInvoiceAmount) {
    query.append('MaximumInvoiceAmount', filters.MaximumInvoiceAmount)
  }

  if (filters.DeliveryMethodID) {
    query.append('DeliveryMethodID', filters.DeliveryMethodID)
  }

  const queryString = query.toString()
  let path = '/sales'

  if (queryString) {
    path = `/sales?${queryString}`
  }

  return request(path)
}

export function getSale(id) {
  return request(`/sales/${id}`)
}

export function getSaleCatalogs() {
  return request('/sales/catalogs')
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

export function deleteSale(id) {
  const options = {
    method: 'DELETE',
  }

  return request(`/sales/${id}`, options)
}
