const API_URL = '/api'

async function request(path, options = {}) {
  const response = await fetch(`${API_URL}${path}`, options)
  const data = await response.json()

  if (!response.ok) {
    throw new Error(data.error || 'No fue posible completar la solicitud.')
  }

  return data
}

export function getInventories(filters = {}) {
  const query = new URLSearchParams()

  if (filters.StockItemName) {
    query.append('StockItemName', filters.StockItemName)
  }

  if (filters.StockGroupID) {
    query.append('StockGroupID', filters.StockGroupID)
  }

  if (filters.MinimumQuantityOnHand) {
    query.append('MinimumQuantityOnHand', filters.MinimumQuantityOnHand)
  }

  if (filters.MaximumQuantityOnHand) {
    query.append('MaximumQuantityOnHand', filters.MaximumQuantityOnHand)
  }

  const queryString = query.toString()
  let path = '/inventory'

  if (queryString) {
    path = `/inventory?${queryString}`
  }

  return request(path)
}

export function getInventory(id) {
  return request(`/inventory/${id}`)
}

export function getInventoryCatalogs() {
  return request('/inventory/catalogs')
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

export function deleteInventory(id) {
  const options = {
    method: 'DELETE',
  }

  return request(`/inventory/${id}`, options)
}
