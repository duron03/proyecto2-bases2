import {
  CButton,
  CButtonGroup,
  CTable,
  CTableBody,
  CTableDataCell,
  CTableHead,
  CTableHeaderCell,
  CTableRow,
} from '@coreui/react'
import { CIcon } from '@coreui/icons-react'
import { cilPencil, cilTrash, cilZoomIn } from '@coreui/icons'
import { Link } from 'react-router-dom'

function getAlignmentClass(column) {
  if (column.align) {
    return `text-${column.align}`
  }

  return ''
}

function getCellValue(row, column) {
  const value = row[column.key]

  if (value === null || value === undefined || value === '') {
    return '—'
  }

  if (column.type === 'date') {
    return String(value).slice(0, 10)
  }

  if (column.type === 'currency') {
    return Number(value).toFixed(2)
  }

  return value
}

function getRowKey(row, idField, rowIndex) {
  return `${row[idField]}-${rowIndex}`
}

function getCellContent(row, column) {
  const value = getCellValue(row, column)

  if (column.linkBasePath && row[column.linkIdField]) {
    const destination = `${column.linkBasePath}/${row[column.linkIdField]}`
    return <Link to={destination}>{value}</Link>
  }

  return value
}

export default function DataTable({
  columns,
  rows = [],
  idField,
  basePath,
  loading = false,
  showActions = true,
  onDelete,
}) {
  let columnCount = columns.length

  if (showActions) {
    columnCount += 1
  }

  return (
    <div className="table-responsive">
      <CTable align="middle" className="data-table mb-0">
        <CTableHead>
          <CTableRow>
            {columns.map((column) => (
              <CTableHeaderCell key={column.key} className={getAlignmentClass(column)} scope="col">
                {column.label}
              </CTableHeaderCell>
            ))}
            {showActions && (
              <CTableHeaderCell className="text-end action-column" scope="col">
                Acciones
              </CTableHeaderCell>
            )}
          </CTableRow>
        </CTableHead>
        <CTableBody>
          {loading && (
            <CTableRow>
              <CTableDataCell colSpan={columnCount} className="text-center text-body-secondary py-5">
                Cargando datos…
              </CTableDataCell>
            </CTableRow>
          )}

          {!loading && rows.length === 0 && (
            <CTableRow>
              <CTableDataCell colSpan={columnCount} className="text-center text-body-secondary py-5">
                No hay datos para mostrar.
              </CTableDataCell>
            </CTableRow>
          )}

          {!loading && rows.map((row, rowIndex) => (
            <CTableRow key={getRowKey(row, idField, rowIndex)}>
              {columns.map((column) => (
                <CTableDataCell key={column.key} className={getAlignmentClass(column)}>
                  {getCellContent(row, column)}
                </CTableDataCell>
              ))}
              {showActions && (
                <CTableDataCell className="text-end">
                  {basePath && (
                    <CButtonGroup size="sm">
                      <CButton as={Link} color="primary" variant="ghost" to={`${basePath}/${row[idField]}`} title="Ver detalle">
                        <CIcon icon={cilZoomIn} />
                      </CButton>
                      <CButton as={Link} color="primary" variant="ghost" to={`${basePath}/${row[idField]}/editar`} title="Editar">
                        <CIcon icon={cilPencil} />
                      </CButton>
                      <CButton color="danger" variant="ghost" title="Eliminar" onClick={() => onDelete(row)}>
                        <CIcon icon={cilTrash} />
                      </CButton>
                    </CButtonGroup>
                  )}
                </CTableDataCell>
              )}
            </CTableRow>
          ))}
        </CTableBody>
      </CTable>
    </div>
  )
}
