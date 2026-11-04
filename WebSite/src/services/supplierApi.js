const API_URL = '/api'

async function request(path, options = {}) {
  const response = await fetch(`${API_URL}${path}`, options)
  const data = await response.json()

  if (!response.ok) {
    throw new Error(data.error || 'No fue posible completar la solicitud.')
  }

  return data
}

export function getSuppliers(filters = {}) {
  const query = new URLSearchParams()

  if (filters.SupplierName) {
    query.append('SupplierName', filters.SupplierName)
  }

  if (filters.SupplierCategoryID) {
    query.append('SupplierCategoryID', filters.SupplierCategoryID)
  }

  if (filters.DeliveryMethodID) {
    query.append('DeliveryMethodID', filters.DeliveryMethodID)
  }

  const queryString = query.toString()
  let path = '/suppliers'

  if (queryString) {
    path = `/suppliers?${queryString}`
  }

  return request(path)
}

export function getSupplier(id) {
  return request(`/suppliers/${id}`)
}

export function getSupplierCatalogs() {
  return request('/suppliers/catalogs')
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

export function deleteSupplier(id) {
  const options = {
    method: 'DELETE',
  }

  return request(`/suppliers/${id}`, options)
}
