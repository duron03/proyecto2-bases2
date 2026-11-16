import { useEffect, useState } from 'react'
import { CAlert, CButton, CSpinner } from '@coreui/react'
import { CIcon } from '@coreui/icons-react'
import { cilArrowLeft, cilReload } from '@coreui/icons'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { createSale, getSale, getSaleCatalogs, updateSale } from '../services/salesApi'
import PageHeader from '../components/PageHeader'
import EntityForm from '../components/EntityForm'

function getEmptyValues(fields) {
	const values = {}

	fields.forEach((field) => {
		if (field.type === 'checkbox') {
			values[field.name] = false
		} else {
			values[field.name] = ''
		}
	})

	return values
}

function getEmptyLine() {
	return {
		StockItemID: '',
		Quantity: 1,
		UnitPrice: '',
		TaxRate: '',
	}
}

function prepareSaleData(fields, values, lines) {
	const sale = {}

	fields.forEach((field) => {
		const value = values[field.name]

		if (value === '') {
			sale[field.name] = null
		} else {
			sale[field.name] = value
		}
	})

	sale.Lines = lines
	return sale
}

function linesAreValid(lines) {
	if (lines.length === 0) {
		return false
	}

	for (let index = 0; index < lines.length; index += 1) {
		const line = lines[index]

		if (!line.StockItemID || !line.Quantity || line.UnitPrice === '' || line.TaxRate === '') {
			return false
		}
	}

	return true
}

export default function SaleFormPage({ definition, mode }) {
	const { id } = useParams()
	const navigate = useNavigate()
	const isEditing = mode === 'edit'
	const initialValues = getEmptyValues(definition.formFields)
	const [values, setValues] = useState(initialValues)
	const [lines, setLines] = useState([getEmptyLine()])
	const [catalogs, setCatalogs] = useState({})
	const [loading, setLoading] = useState(true)
	const [saving, setSaving] = useState(false)
	const [error, setError] = useState('')
	const [conflict, setConflict] = useState(false)

	async function loadForm() {
		try {
			setLoading(true)
			setError('')
			setConflict(false)

			if (isEditing) {
				const saleData = await getSale(id)
				const catalogData = await getSaleCatalogs(id)
				setValues({
					...saleData.invoice,
					InvoiceDate: String(saleData.invoice.InvoiceDate || '').slice(0, 10),
				})
				setLines(saleData.lines)
				setCatalogs(catalogData)
			} else {
				const catalogData = await getSaleCatalogs()
				setCatalogs(catalogData)
			}
		} catch (requestError) {
			setError(requestError.message)
		} finally {
			setLoading(false)
		}
	}

	useEffect(() => {
		loadForm()
	}, [id, isEditing])

	function changeValue(name, value) {
		setValues({ ...values, [name]: value })
	}

	function changeLines(updatedLines) {
		setLines(updatedLines)
	}

	async function saveSale() {
		if (!linesAreValid(lines)) {
			setError('La factura debe tener al menos una línea completa.')
			return
		}

		try {
			setSaving(true)
			setError('')
			setConflict(false)
			const saleData = prepareSaleData(definition.formFields, values, lines)

			if (isEditing) {
				await updateSale(id, {
					...saleData,
					VersionEsperada: values.VersionVenta,
				})
				navigate(`/ventas/${id}`)
			} else {
				const result = await createSale(saleData)
				navigate(`/ventas/${result.newId}`)
			}
		} catch (requestError) {
			setError(requestError.message)
			setConflict(requestError.code === 'VERSION_OBSOLETA')
		} finally {
			setSaving(false)
		}
	}

	let title = 'Nueva venta'
	let description = 'Complete el encabezado y agregue el detalle de la factura.'

	if (isEditing) {
		title = 'Editar venta'
		description = 'Modifique el encabezado o las líneas de la factura.'
	}

	const backButton = (
		<CButton as={Link} color="secondary" variant="outline" to="/ventas">
			<CIcon icon={cilArrowLeft} className="me-2" />
			Volver
		</CButton>
	)

	return (
		<>
			<PageHeader
				title={title}
				description={description}
				breadcrumbs={[{ label: definition.title, to: '/ventas' }, { label: title }]}
				actions={backButton}
			/>

			{error && (
				<CAlert color="danger">
					{error}
					{conflict && (
						<CButton color="danger" variant="outline" size="sm" className="ms-3" onClick={loadForm}>
							<CIcon icon={cilReload} className="me-2" />
							Recargar datos
						</CButton>
					)}
				</CAlert>
			)}

			{loading ? (
				<div className="text-center py-5">
					<CSpinner color="primary" />
					<div className="text-body-secondary mt-2">Cargando formulario…</div>
				</div>
			) : (
				<EntityForm
					definition={definition}
					mode={mode}
					values={values}
					catalogs={catalogs}
					invoiceLines={lines}
					saving={saving}
					onChange={changeValue}
					onInvoiceLinesChange={changeLines}
					onSubmit={saveSale}
				/>
			)}
		</>
	)
}
