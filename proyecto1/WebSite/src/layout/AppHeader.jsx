import { CContainer, CHeader, CHeaderToggler } from '@coreui/react'
import { CIcon } from '@coreui/icons-react'
import { cilMenu } from '@coreui/icons'

export default function AppHeader() {
  return (
    <CHeader position="sticky" className="app-header border-bottom">
      <CContainer fluid>
        <CHeaderToggler
          className="px-0"
          aria-label="Navegación disponible en la versión funcional"
          disabled
        >
          <CIcon icon={cilMenu} size="lg" />
        </CHeaderToggler>
      </CContainer>
    </CHeader>
  )
}
