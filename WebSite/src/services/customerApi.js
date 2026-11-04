const API_URL = '/api'

async function request(path, options = {}) {
  const response = await fetch(`${API_URL}${path}`, options)
  const data = await response.json()

  if (!response.ok) {
    throw new Error(data.error || 'No fue posible completar la solicitud.')
  }

  return data
}

export function getCustomers(filters = {}) {
  const query = new URLSearchParams()

  if (filters.CustomerName) {
    query.append('CustomerName', filters.CustomerName)
  }

  if (filters.CustomerCategoryID) {
    query.append('CustomerCategoryID', filters.CustomerCategoryID)
  }

  if (filters.DeliveryMethodID) {
    query.append('DeliveryMethodID', filters.DeliveryMethodID)
  }

  const queryString = query.toString()
  let path = '/customers'

  if (queryString) {
    path = `/customers?${queryString}`
  }

  return request(path)
}

export function getCustomer(id) {
  return request(`/customers/${id}`)
}

export function getCustomerCatalogs() {
  return request('/customers/catalogs')
}

export function getCities(cityName) {
  const query = new URLSearchParams()
  query.append('name', cityName)

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

export function deleteCustomer(id) {
  const options = {
    method: 'DELETE',
  }

  return request(`/customers/${id}`, options)
}
