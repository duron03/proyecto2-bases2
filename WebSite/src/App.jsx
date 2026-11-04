import { Navigate, Route, Routes } from 'react-router-dom'
import AppLayout from './layout/AppLayout'
import DashboardPage from './pages/DashboardPage'
import EntityListPage from './pages/EntityListPage'
import EntityDetailPage from './pages/EntityDetailPage'
import EntityFormPage from './pages/EntityFormPage'
import ReportsPage from './pages/ReportsPage'
import ReportDetailPage from './pages/ReportDetailPage'
import NotFoundPage from './pages/NotFoundPage'

export default function App() {
  return (
    <Routes>
      <Route element={<AppLayout />}>
        <Route index element={<DashboardPage />} />

        <Route path="clientes">
          <Route index element={<EntityListPage entityKey="customers" />} />
          <Route path="nuevo" element={<EntityFormPage entityKey="customers" mode="create" />} />
          <Route path=":id" element={<EntityDetailPage entityKey="customers" />} />
          <Route path=":id/editar" element={<EntityFormPage entityKey="customers" mode="edit" />} />
        </Route>

        <Route path="proveedores">
          <Route index element={<EntityListPage entityKey="suppliers" />} />
          <Route path="nuevo" element={<EntityFormPage entityKey="suppliers" mode="create" />} />
          <Route path=":id" element={<EntityDetailPage entityKey="suppliers" />} />
          <Route path=":id/editar" element={<EntityFormPage entityKey="suppliers" mode="edit" />} />
        </Route>

        <Route path="inventario">
          <Route index element={<EntityListPage entityKey="inventory" />} />
          <Route path="nuevo" element={<EntityFormPage entityKey="inventory" mode="create" />} />
          <Route path=":id" element={<EntityDetailPage entityKey="inventory" />} />
          <Route path=":id/editar" element={<EntityFormPage entityKey="inventory" mode="edit" />} />
        </Route>

        <Route path="ventas">
          <Route index element={<EntityListPage entityKey="sales" />} />
          <Route path="nuevo" element={<EntityFormPage entityKey="sales" mode="create" />} />
          <Route path=":id" element={<EntityDetailPage entityKey="sales" />} />
          <Route path=":id/editar" element={<EntityFormPage entityKey="sales" mode="edit" />} />
        </Route>

        <Route path="reportes" element={<ReportsPage />} />
        <Route path="reportes/:reportId" element={<ReportDetailPage />} />
        <Route path="inicio" element={<Navigate to="/" replace />} />
        <Route path="*" element={<NotFoundPage />} />
      </Route>
    </Routes>
  )
}
