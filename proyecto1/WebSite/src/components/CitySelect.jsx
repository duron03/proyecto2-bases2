import { useState } from 'react'
import { CButton, CFormInput, CFormSelect } from '@coreui/react'
import { getCities } from '../services/customerApi'

export default function CitySelect({ id, name, value, currentLabel, required, onChange }) {
  const [searchText, setSearchText] = useState('')
  const [cities, setCities] = useState([])
  const [message, setMessage] = useState('')
  const [searching, setSearching] = useState(false)
  const [selectedLabel, setSelectedLabel] = useState(currentLabel || '')

  const visibleCities = cities.slice()
  let selectedCityIsVisible = false

  for (let index = 0; index < visibleCities.length; index += 1) {
    const city = visibleCities[index]

    if (String(city.Value) === String(value)) {
      selectedCityIsVisible = true
    }
  }

  if (value && selectedLabel && !selectedCityIsVisible) {
    visibleCities.unshift({ Value: value, Label: selectedLabel })
  }

  function changeCity(event) {
    let newSelectedLabel = ''

    for (let index = 0; index < visibleCities.length; index += 1) {
      const city = visibleCities[index]

      if (String(city.Value) === event.target.value) {
        newSelectedLabel = city.Label
      }
    }

    setSelectedLabel(newSelectedLabel)
    onChange(event)
  }

  function changeSearchText(event) {
    setSearchText(event.target.value)
  }

  async function searchCities() {
    if (searchText.trim().length < 2) {
      setMessage('Escriba al menos dos letras.')
      return
    }

    try {
      setSearching(true)
      setMessage('')
      const cityName = searchText.trim()
      const result = await getCities(cityName)
      setCities(result)

      if (result.length === 0) {
        setMessage('No se encontraron ciudades.')
      }
    } catch (error) {
      setMessage(error.message)
    } finally {
      setSearching(false)
    }
  }

  return (
    <>
      <div className="d-flex gap-2 mb-2">
        <CFormInput
          value={searchText}
          placeholder="Buscar por nombre"
          onChange={changeSearchText}
        />
        <CButton type="button" color="secondary" variant="outline" onClick={searchCities} disabled={searching}>
          {searching ? 'Buscando…' : 'Buscar'}
        </CButton>
      </div>
      <CFormSelect id={id} name={name} value={value || ''} required={required} onChange={changeCity}>
        <option value="">Seleccione una ciudad…</option>
        {visibleCities.map((city) => (
          <option key={city.Value} value={city.Value}>{city.Label}</option>
        ))}
      </CFormSelect>
      {message && <div className="small text-body-secondary mt-1">{message}</div>}
    </>
  )
}
