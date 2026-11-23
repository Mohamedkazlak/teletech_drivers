import { lazy, Suspense } from 'react'
import { useTranslation } from 'react-i18next'
import { Route, Routes } from 'react-router-dom'
import { GuestOnly, HomeRedirect, RequireAuth, RoleLayout } from '../auth/guards'
import { AppShell } from '../components/layout/AppShell'
import { ChangePasswordPage } from '../pages/ChangePasswordPage'
import { LoginPage } from '../pages/LoginPage'
import { NotificationsPage } from '../pages/NotificationsPage'
import { ProfilePage } from '../pages/ProfilePage'
import { SettingsPage } from '../pages/SettingsPage'

const DashboardPage = lazy(() =>
  import('../pages/DashboardPage').then((module) => ({ default: module.DashboardPage })),
)
const LiveMapPage = lazy(() =>
  import('../pages/LiveMapPage').then((module) => ({ default: module.LiveMapPage })),
)
const RequestedTripsPage = lazy(() =>
  import('../pages/company-admin/RequestedTripsPage').then((module) => ({
    default: module.RequestedTripsPage,
  })),
)
const MyTripsPage = lazy(() =>
  import('../pages/company-admin/MyTripsPage').then((module) => ({
    default: module.MyTripsPage,
  })),
)
const TripsPage = lazy(() =>
  import('../pages/company-admin/TripsPage').then((module) => ({ default: module.TripsPage })),
)
const PlacesPage = lazy(() =>
  import('../pages/company-admin/PlacesPage').then((module) => ({ default: module.PlacesPage })),
)
const DriverReportsPage = lazy(() =>
  import('../pages/company-admin/DriverReportsPage').then((module) => ({
    default: module.DriverReportsPage,
  })),
)
const DriversRequestsPage = lazy(() =>
  import('../pages/drivers-admin/RequestsPage').then((module) => ({
    default: module.RequestsPage,
  })),
)
const DriversTripsPage = lazy(() =>
  import('../pages/drivers-admin/TripsPage').then((module) => ({ default: module.TripsPage })),
)
const DriversMyTripsPage = lazy(() =>
  import('../pages/drivers-admin/MyTripsPage').then((module) => ({ default: module.MyTripsPage })),
)
const DriversPage = lazy(() =>
  import('../pages/drivers-admin/DriversPage').then((module) => ({ default: module.DriversPage })),
)
const DriverProfilePage = lazy(() =>
  import('../pages/drivers-admin/DriverProfilePage').then((module) => ({
    default: module.DriverProfilePage,
  })),
)
const AdminDriversPage = lazy(() =>
  import('../pages/admin/AdminDriversPage').then((module) => ({
    default: module.AdminDriversPage,
  })),
)
const EmployeesPage = lazy(() =>
  import('../pages/admin/EmployeesPage').then((module) => ({
    default: module.EmployeesPage,
  })),
)
const UsersPage = lazy(() =>
  import('../pages/admin/UsersPage').then((module) => ({
    default: module.UsersPage,
  })),
)
const TripRequestsPage = lazy(() =>
  import('../pages/admin/TripRequestsPage').then((module) => ({
    default: module.TripRequestsPage,
  })),
)
const AttendancePage = lazy(() =>
  import('../pages/drivers-admin/AttendancePage').then((module) => ({
    default: module.AttendancePage,
  })),
)
const AttendanceQrPage = lazy(() =>
  import('../pages/drivers-admin/AttendanceQrPage').then((module) => ({
    default: module.AttendanceQrPage,
  })),
)

function PageFallback() {
  const { t } = useTranslation()
  return <p role="status">{t('common.loading')}</p>
}

export function AppRoutes() {
  return (
    <Routes>
      <Route
        path="/login"
        element={
          <GuestOnly>
            <LoginPage />
          </GuestOnly>
        }
      />
      <Route
        path="/change-password"
        element={
          <RequireAuth allowPasswordChange>
            <ChangePasswordPage />
          </RequireAuth>
        }
      />
      <Route
        element={
          <RequireAuth>
            <AppShell />
          </RequireAuth>
        }
      >
        <Route path="/notifications" element={<NotificationsPage />} />
        <Route path="/profile" element={<ProfilePage />} />
        <Route path="/settings" element={<SettingsPage />} />
        <Route path="/admin" element={<RoleLayout role="admin" />}>
          <Route
            index
            element={
              <Suspense fallback={<PageFallback />}>
                <DashboardPage />
              </Suspense>
            }
          />
          <Route
            path="drivers"
            element={
              <Suspense fallback={<PageFallback />}>
                <AdminDriversPage />
              </Suspense>
            }
          />
          <Route
            path="drivers/:driverId"
            element={
              <Suspense fallback={<PageFallback />}>
                <DriverProfilePage />
              </Suspense>
            }
          />
          <Route
            path="employees"
            element={
              <Suspense fallback={<PageFallback />}>
                <EmployeesPage />
              </Suspense>
            }
          />
          <Route
            path="users"
            element={
              <Suspense fallback={<PageFallback />}>
                <UsersPage />
              </Suspense>
            }
          />
          <Route
            path="places"
            element={
              <Suspense fallback={<PageFallback />}>
                <PlacesPage />
              </Suspense>
            }
          />
          <Route
            path="trips"
            element={
              <Suspense fallback={<PageFallback />}>
                <TripsPage />
              </Suspense>
            }
          />
          <Route
            path="trip-requests"
            element={
              <Suspense fallback={<PageFallback />}>
                <TripRequestsPage />
              </Suspense>
            }
          />
          <Route
            path="my-trips"
            element={
              <Suspense fallback={<PageFallback />}>
                <MyTripsPage />
              </Suspense>
            }
          />
          <Route
            path="live-map"
            element={
              <Suspense fallback={<PageFallback />}>
                <LiveMapPage />
              </Suspense>
            }
          />
          <Route
            path="attendance"
            element={
              <Suspense fallback={<PageFallback />}>
                <AttendancePage />
              </Suspense>
            }
          />
          <Route
            path="attendance/qr"
            element={
              <Suspense fallback={<PageFallback />}>
                <AttendanceQrPage />
              </Suspense>
            }
          />
        </Route>
        <Route path="/company-admin" element={<RoleLayout role="company_admin" />}>
          <Route
            index
            element={
              <Suspense fallback={<PageFallback />}>
                <RequestedTripsPage />
              </Suspense>
            }
          />
          <Route
            path="my-trips"
            element={
              <Suspense fallback={<PageFallback />}>
                <MyTripsPage />
              </Suspense>
            }
          />
          <Route
            path="trips"
            element={
              <Suspense fallback={<PageFallback />}>
                <TripsPage />
              </Suspense>
            }
          />
          <Route
            path="places"
            element={
              <Suspense fallback={<PageFallback />}>
                <PlacesPage />
              </Suspense>
            }
          />
          <Route
            path="driver-reports"
            element={
              <Suspense fallback={<PageFallback />}>
                <DriverReportsPage />
              </Suspense>
            }
          />
        </Route>
        <Route path="/drivers-admin" element={<RoleLayout role="drivers_admin" />}>
          <Route
            index
            element={
              <Suspense fallback={<PageFallback />}>
                <DriversRequestsPage />
              </Suspense>
            }
          />
          <Route
            path="trips"
            element={
              <Suspense fallback={<PageFallback />}>
                <DriversTripsPage />
              </Suspense>
            }
          />
          <Route
            path="my-trips"
            element={
              <Suspense fallback={<PageFallback />}>
                <DriversMyTripsPage />
              </Suspense>
            }
          />
          <Route
            path="drivers"
            element={
              <Suspense fallback={<PageFallback />}>
                <DriversPage />
              </Suspense>
            }
          />
          <Route
            path="drivers/:driverId"
            element={
              <Suspense fallback={<PageFallback />}>
                <DriverProfilePage />
              </Suspense>
            }
          />
          <Route
            path="attendance"
            element={
              <Suspense fallback={<PageFallback />}>
                <AttendancePage />
              </Suspense>
            }
          />
          <Route
            path="attendance/qr"
            element={
              <Suspense fallback={<PageFallback />}>
                <AttendanceQrPage />
              </Suspense>
            }
          />
          <Route
            path="live-map"
            element={
              <Suspense fallback={<PageFallback />}>
                <LiveMapPage />
              </Suspense>
            }
          />
        </Route>
      </Route>
      <Route path="/" element={<HomeRedirect />} />
      <Route path="*" element={<HomeRedirect />} />
    </Routes>
  )
}
