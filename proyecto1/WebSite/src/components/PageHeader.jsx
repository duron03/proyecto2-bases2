import { CBreadcrumb, CBreadcrumbItem } from '@coreui/react'
import { Link } from 'react-router-dom'

export default function PageHeader({ title, description, breadcrumbs = [], actions }) {
  return (
    <div className="page-heading">
      <div className="min-w-0">
        {breadcrumbs.length > 0 && (
          <CBreadcrumb className="mb-2 small">
            <CBreadcrumbItem><Link to="/">Inicio</Link></CBreadcrumbItem>
            {breadcrumbs.map((item) => (
              <CBreadcrumbItem key={item.label} active={!item.to}>
                {item.to ? <Link to={item.to}>{item.label}</Link> : item.label}
              </CBreadcrumbItem>
            ))}
          </CBreadcrumb>
        )}
        <h1 className="h3 mb-1">{title}</h1>
        {description && <p className="text-body-secondary mb-0">{description}</p>}
      </div>
      {actions && <div className="page-heading-actions">{actions}</div>}
    </div>
  )
}
