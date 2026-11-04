import {
  CButton,
  CCard,
  CCardBody,
  CForm,
  CFormCheck,
  CFormInput,
  CFormLabel,
  CFormSelect,
  CFormTextarea,
} from '@coreui/react'
import { Link } from 'react-router-dom'
import CitySelect from './CitySelect'
import InvoiceLinesEditor from './InvoiceLinesEditor'

function FormField({ field, value, currentLabel, options, onChange }) {
  const inputId = `field-${field.name}`
  const fieldClass = field.fullWidth ? 'form-field-full' : ''
  const isRegularInput = field.type !== 'select'
    && field.type !== 'city'
    && field.type !== 'textarea'

  if (field.type === 'checkbox') {
    return (
      <div className={fieldClass}>
        <CFormCheck
          id={inputId}
          name={field.name}
          label={field.label}
          checked={Boolean(value)}
          onChange={onChange}
        />
      </div>
    )
  }

  return (
    <div className={fieldClass}>
      <CFormLabel htmlFor={inputId}>
        {field.label}
        {field.required && <span className="required-mark"> *</span>}
      </CFormLabel>

      {field.type === 'select' && (
        <CFormSelect
          id={inputId}
          name={field.name}
          value={value ?? ''}
          required={field.required}
          onChange={onChange}
        >
          <option value="">Seleccione…</option>
          {options.map((option) => (
            <option key={option.Value} value={option.Value}>{option.Label}</option>
          ))}
        </CFormSelect>
      )}

      {field.type === 'city' && (
        <CitySelect
          id={inputId}
          name={field.name}
          value={value}
          currentLabel={currentLabel}
          required={field.required}
          onChange={onChange}
        />
      )}

      {field.type === 'textarea' && (
        <CFormTextarea
          id={inputId}
          name={field.name}
          value={value ?? ''}
          rows={3}
          required={field.required}
          maxLength={field.maxLength}
          onChange={onChange}
        />
      )}

      {isRegularInput && (
        <CFormInput
          id={inputId}
          name={field.name}
          type={field.type || 'text'}
          value={value ?? ''}
          required={field.required}
          min={field.min}
          max={field.max}
          step={field.step}
          maxLength={field.maxLength}
          onChange={onChange}
        />
      )}
    </div>
  )
}

function getSections(fields) {
  const sections = []

  fields.forEach((field) => {
    const section = field.section || 'Información'
    if (!sections.includes(section)) sections.push(section)
  })

  return sections
}

function getFieldsForSection(fields, selectedSection, mode) {
  const sectionFields = []

  fields.forEach((field) => {
    const fieldSection = field.section || 'Información'
    const hideOnEdit = mode === 'edit' && field.createOnly

    if (fieldSection === selectedSection && !hideOnEdit) {
      sectionFields.push(field)
    }
  })

  return sectionFields
}

export default function EntityForm({
  definition,
  mode = 'create',
  values = {},
  catalogs = {},
  invoiceLines = [],
  saving = false,
  onChange,
  onInvoiceLinesChange,
  onSubmit,
}) {
  const sections = getSections(definition.formFields)

  function handleChange(event) {
    if (!onChange) return

    const fieldName = event.target.name
    let fieldValue = event.target.value

    if (event.target.type === 'checkbox') {
      fieldValue = event.target.checked
    }

    onChange(fieldName, fieldValue)
  }

  function handleSubmit(event) {
    event.preventDefault()
    if (onSubmit) onSubmit()
  }

  return (
    <CForm onSubmit={handleSubmit}>
      {sections.map((section) => {
        const sectionFields = getFieldsForSection(definition.formFields, section, mode)

        return (
          <CCard className="form-section shadow-sm" key={section}>
            <CCardBody>
              <h2 className="h6 mb-3">{section}</h2>
              <div className="form-grid">
                {sectionFields.map((field) => (
                  <FormField
                    key={field.name}
                    field={field}
                    value={values[field.name]}
                    currentLabel={values[field.labelField]}
                    options={catalogs[field.catalog] || []}
                    onChange={handleChange}
                  />
                ))}
              </div>
            </CCardBody>
          </CCard>
        )
      })}

      {definition.route === 'ventas' && (
        <CCard className="form-section shadow-sm">
          <CCardBody>
            <InvoiceLinesEditor
              lines={invoiceLines}
              products={catalogs.products || []}
              onChange={onInvoiceLinesChange}
            />
          </CCardBody>
        </CCard>
      )}

      <div className="form-actions">
        <CButton as={Link} color="secondary" variant="outline" to={`/${definition.route}`}>
          Cancelar
        </CButton>
        <CButton type="submit" color="primary" disabled={!onSubmit || saving}>
          {saving ? 'Guardando…' : 'Guardar'}
        </CButton>
      </div>
    </CForm>
  )
}
