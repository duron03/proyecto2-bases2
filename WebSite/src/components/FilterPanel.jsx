import { CButton, CCard, CCardBody, CForm, CFormInput, CFormLabel, CFormSelect } from '@coreui/react'
import { CIcon } from '@coreui/icons-react'
import { cilReload, cilSearch } from '@coreui/icons'

function FilterField({ field, value, options, onChange }) {
  const inputId = `filter-${field.name}`

  if (field.type === 'select') {
    return (
      <div>
        <CFormLabel htmlFor={inputId}>{field.label}</CFormLabel>
        <CFormSelect id={inputId} name={field.name} value={value || ''} onChange={onChange}>
          <option value="">Todos</option>
          {options.map((option) => (
            <option key={option.Value} value={option.Value}>{option.Label}</option>
          ))}
        </CFormSelect>
      </div>
    )
  }

  return (
    <div>
      <CFormLabel htmlFor={inputId}>{field.label}</CFormLabel>
      <CFormInput
        id={inputId}
        name={field.name}
        type={field.type || 'text'}
        value={value || ''}
        min={field.min}
        max={field.max}
        maxLength={field.maxLength}
        placeholder={field.placeholder}
        onChange={onChange}
      />
    </div>
  )
}

export default function FilterPanel({
  fields = [],
  values = {},
  catalogs = {},
  loading = false,
  onChange,
  onSubmit,
  onReset,
}) {
  function handleChange(event) {
    if (onChange) {
      onChange(event.target.name, event.target.value)
    }
  }

  function handleSubmit(event) {
    event.preventDefault()

    if (onSubmit) {
      onSubmit()
    }
  }

  return (
    <CCard className="filter-card shadow-sm">
      <CCardBody>
        <CForm className="filter-grid" onSubmit={handleSubmit}>
          {fields.map((field) => (
            <FilterField
              key={field.name}
              field={field}
              value={values[field.name]}
              options={catalogs[field.catalog] || []}
              onChange={handleChange}
            />
          ))}
          <div className="filter-actions">
            <CButton type="submit" color="primary" disabled={!onSubmit || loading}>
              <CIcon icon={cilSearch} className="me-2" />
              Consultar
            </CButton>
            <CButton type="button" color="secondary" variant="outline" disabled={!onReset || loading} onClick={onReset}>
              <CIcon icon={cilReload} className="me-2" />
              Restaurar
            </CButton>
          </div>
        </CForm>
      </CCardBody>
    </CCard>
  )
}
