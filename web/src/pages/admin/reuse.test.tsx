import { screen } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { api } from '../../api/client'
import i18n from '../../i18n'
import { paginated, renderPage } from '../../test/render-page'
import { LiveMapPage } from '../LiveMapPage'
import { MyTripsPage } from '../company-admin/MyTripsPage'
import { PlacesPage } from '../company-admin/PlacesPage'
import { TripsPage } from '../company-admin/TripsPage'
import { DriversPage } from '../drivers-admin/DriversPage'

vi.mock('../../components/map/MapView', () => ({
  MapView: () => null,
}))

vi.mock('../../components/charts/BarChartCard', () => ({
  BarChartCard: () => null,
}))

vi.mock('../../api/client', () => ({
  api: { get: vi.fn(), post: vi.fn(), patch: vi.fn(), delete: vi.fn() },
}))

const http = vi.mocked(api)

describe('shared screens reused by system admin', () => {
  beforeEach(async () => {
    http.get.mockReset()
    await i18n.changeLanguage('en')
    http.get.mockImplementation(async (path: string) => {
      if (
        path === '/places' ||
        path === '/drivers' ||
        path === '/trips' ||
        path === '/my-trips' ||
        path === '/live-map'
      ) {
        return path === '/live-map' ? { data: [] } : paginated([])
      }
      throw new Error(path)
    })
  })

  it('mounts the shared places, drivers, trips, and my-trips screens', async () => {
    const places = renderPage(<PlacesPage />)
    expect(await screen.findByRole('heading', { name: 'Places' })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Add place' })).toBeInTheDocument()
    places.unmount()

    const drivers = renderPage(<DriversPage allowDeleted />)
    expect(await screen.findByRole('heading', { name: 'Drivers' })).toBeInTheDocument()
    expect(screen.getByRole('checkbox', { name: 'Include deleted' })).toBeInTheDocument()
    drivers.unmount()

    const fleet = renderPage(<DriversPage />)
    expect(await screen.findByRole('heading', { name: 'Drivers' })).toBeInTheDocument()
    expect(screen.queryByRole('checkbox', { name: 'Include deleted' })).not.toBeInTheDocument()
    fleet.unmount()

    const trips = renderPage(<TripsPage />)
    expect(await screen.findByRole('heading', { name: 'Trips' })).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: 'Assign driver' })).not.toBeInTheDocument()
    trips.unmount()

    renderPage(<MyTripsPage />)
    expect(await screen.findByRole('heading', { name: 'My Trips' })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Request a trip' })).toBeInTheDocument()
  })

  it('loads the shared live map for system admin', async () => {
    renderPage(<LiveMapPage />)
    expect(await screen.findByRole('heading', { name: 'Live Map' })).toBeInTheDocument()
    expect(await screen.findByText('No drivers to show.')).toBeInTheDocument()
    expect(screen.queryByRole('alert')).not.toBeInTheDocument()
    expect(http.get).toHaveBeenCalledWith('/live-map', expect.anything())
  })
})
