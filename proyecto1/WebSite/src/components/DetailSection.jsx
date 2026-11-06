import { CCard, CCardBody } from '@coreui/react'
import { Link } from 'react-router-dom'
import { fieldLabels } from '../config/fieldLabels'

function FieldValue({ field, value, record }) {
  if (value === null || value === undefined || value === '') {
    return '—'
  }

  if (field === 'WebsiteURL') {
    return <a href={value} target="_blank" rel="noreferrer">{value}</a>
  }

  if (field === 'SupplierName' && record.SupplierID && record.StockItemID) {
    return <Link to={`/proveedores/${record.SupplierID}`}>{value}</Link>
  }

  if (field === 'CustomerName' && record.CustomerID && record.InvoiceID) {
    return <Link to={`/clientes/${record.CustomerID}`}>{value}</Link>
  }

  return String(value)
}

export default function DetailSection({ title, fields, record = {} }) {
  return (
    <CCard className="detail-card shadow-sm h-100">
      <CCardBody>
        <h2 className="h6 mb-3">{title}</h2>
        <dl className="detail-list mb-0">
          {fields.map((field) => (
            <div key={field}>
              <dt>{fieldLabels[field] || field}</dt>
              <dd><FieldValue field={field} value={record[field]} record={record} /></dd>
            </div>
          ))}
        </dl>
      </CCardBody>
    </CCard>
  )
}
