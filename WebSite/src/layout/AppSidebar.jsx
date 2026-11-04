import { CNavItem, CNavTitle, CSidebar, CSidebarNav } from '@coreui/react'
import { CIcon } from '@coreui/icons-react'
import { cilCart, cilChartLine, cilPeople, cilSpeedometer, cilStorage, cilTruck } from '@coreui/icons'
import { NavLink } from 'react-router-dom'

const navigation = [
  { to: '/', label: 'Resumen', icon: cilSpeedometer, end: true },
  { title: 'Gestión' },
  { to: '/clientes', label: 'Clientes', icon: cilPeople },
  { to: '/proveedores', label: 'Proveedores', icon: cilTruck },
  { to: '/inventario', label: 'Inventario', icon: cilStorage },
  { to: '/ventas', label: 'Ventas', icon: cilCart },
  { title: 'Análisis' },
  { to: '/reportes', label: 'Reportes', icon: cilChartLine },
]

function SidebarItem({ item }) {
  if (item.title) {
    return <CNavTitle>{item.title}</CNavTitle>
  }

  function linkClassName({ isActive }) {
    if (isActive) return 'nav-link active'
    return 'nav-link'
  }

  return (
    <CNavItem>
      <NavLink
        to={item.to}
        end={item.end}
        className={linkClassName}
      >
        <CIcon customClassName="nav-icon" icon={item.icon} />
        {item.label}
      </NavLink>
    </CNavItem>
  )
}

export default function AppSidebar() {
  return (
    <CSidebar
      className="app-sidebar border-end"
      colorScheme="dark"
      position="fixed"
      visible
    >
      <CSidebarNav>
        {navigation.map((item, index) => (
          <SidebarItem
            key={item.to || `${item.title}-${index}`}
            item={item}
          />
        ))}
      </CSidebarNav>
    </CSidebar>
  )
}
