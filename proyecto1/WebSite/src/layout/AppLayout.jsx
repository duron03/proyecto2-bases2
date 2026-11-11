import { CContainer } from '@coreui/react'
import { Outlet } from 'react-router-dom'
import AppHeader from './AppHeader'
import AppSidebar from './AppSidebar'

export default function AppLayout() {
  return (
    <div className="app-shell">
      <AppSidebar />
      <div className="wrapper d-flex flex-column min-vh-100">
        <AppHeader />
        <main className="body flex-grow-1">
          <CContainer fluid className="app-content">
            <Outlet />
          </CContainer>
        </main>
      </div>
    </div>
  )
}
