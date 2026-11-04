import { CButton, CFormInput, CFormLabel, CFormSelect } from '@coreui/react'
import { CIcon } from '@coreui/icons-react'
import { cilPlus, cilTrash } from '@coreui/icons'

function getNewLine() {
  return {
    StockItemID: '',
    Quantity: 1,
    UnitPrice: '',
    TaxRate: '',
  }
}

function calculateTotal(line) {
  if (line.UnitPrice === '' || line.TaxRate === '') {
    return '—'
  }

  const quantity = Number(line.Quantity)
  const unitPrice = Number(line.UnitPrice)
  const taxRate = Number(line.TaxRate)

  if (!quantity || Number.isNaN(unitPrice) || Number.isNaN(taxRate)) {
    return '—'
  }

  const subtotal = quantity * unitPrice
  const taxAmount = subtotal * taxRate / 100
  return (subtotal + taxAmount).toFixed(2)
}

export default function InvoiceLinesEditor({ lines = [], products = [], onChange }) {
  function addLine() {
    if (!onChange) {
      return
    }

    const updatedLines = lines.slice()
    updatedLines.push(getNewLine())
    onChange(updatedLines)
  }

  function removeLine(lineIndex) {
    if (!onChange) {
      return
    }

    const updatedLines = lines.slice()
    updatedLines.splice(lineIndex, 1)
    onChange(updatedLines)
  }

  function changeLine(lineIndex, fieldName, value) {
    if (!onChange) {
      return
    }

    const updatedLines = lines.slice()
    const updatedLine = { ...updatedLines[lineIndex] }
    updatedLine[fieldName] = value
    updatedLines[lineIndex] = updatedLine
    onChange(updatedLines)
  }

  function changeProduct(lineIndex, productID) {
    let selectedProduct = null

    for (let index = 0; index < products.length; index += 1) {
      const product = products[index]

      if (String(product.Value) === productID) {
        selectedProduct = product
      }
    }

    const updatedLines = lines.slice()
    const updatedLine = { ...updatedLines[lineIndex] }
    updatedLine.StockItemID = productID

    if (selectedProduct) {
      updatedLine.UnitPrice = selectedProduct.UnitPrice
      updatedLine.TaxRate = selectedProduct.TaxRate
    } else {
      updatedLine.UnitPrice = ''
      updatedLine.TaxRate = ''
    }

    updatedLines[lineIndex] = updatedLine
    onChange(updatedLines)
  }

  return (
    <div className="invoice-lines">
      <div className="d-flex align-items-center justify-content-between gap-3 mb-3">
        <div>
          <h3 className="h6 mb-1">Detalle de factura</h3>
          <p className="small text-body-secondary mb-0">
            El impuesto y el total definitivo se calculan en SQL Server.
          </p>
        </div>
        <CButton type="button" color="primary" variant="outline" size="sm" onClick={addLine} disabled={!onChange}>
          <CIcon icon={cilPlus} className="me-2" />
          Agregar línea
        </CButton>
      </div>

      {lines.length === 0 && (
        <div className="text-body-secondary py-3">
          Agregue al menos una línea a la factura.
        </div>
      )}

      {lines.map((line, lineIndex) => (
        <div className="invoice-line" key={line.InvoiceLineID || lineIndex}>
          <div>
            <CFormLabel htmlFor={`line-product-${lineIndex}`}>Producto</CFormLabel>
            <CFormSelect
              id={`line-product-${lineIndex}`}
              value={line.StockItemID || ''}
              required
              onChange={(event) => changeProduct(lineIndex, event.target.value)}
            >
              <option value="">Seleccione…</option>
              {products.map((product) => (
                <option key={product.Value} value={product.Value}>{product.Label}</option>
              ))}
            </CFormSelect>
          </div>
          <div>
            <CFormLabel htmlFor={`line-quantity-${lineIndex}`}>Cantidad</CFormLabel>
            <CFormInput
              id={`line-quantity-${lineIndex}`}
              type="number"
              value={line.Quantity}
              min="1"
              required
              onChange={(event) => changeLine(lineIndex, 'Quantity', event.target.value)}
            />
          </div>
          <div>
            <CFormLabel htmlFor={`line-price-${lineIndex}`}>Precio unitario</CFormLabel>
            <CFormInput
              id={`line-price-${lineIndex}`}
              type="number"
              value={line.UnitPrice}
              min="0"
              step="0.01"
              required
              onChange={(event) => changeLine(lineIndex, 'UnitPrice', event.target.value)}
            />
          </div>
          <div>
            <CFormLabel htmlFor={`line-tax-${lineIndex}`}>Impuesto (%)</CFormLabel>
            <CFormInput
              id={`line-tax-${lineIndex}`}
              type="number"
              value={line.TaxRate}
              min="0"
              step="0.001"
              required
              onChange={(event) => changeLine(lineIndex, 'TaxRate', event.target.value)}
            />
          </div>
          <div className="invoice-line-total">
            <span className="small text-body-secondary">Total estimado</span>
            <strong>{calculateTotal(line)}</strong>
          </div>
          <CButton type="button" color="danger" variant="ghost" onClick={() => removeLine(lineIndex)}>
            <CIcon icon={cilTrash} />
          </CButton>
        </div>
      ))}
    </div>
  )
}
