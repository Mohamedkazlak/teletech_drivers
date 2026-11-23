import { screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { api } from '../../api/client'
import i18n from '../../i18n'
import { paginated, place, renderPage } from '../../test/render-page'
import { PlacesPage } from './PlacesPage'

vi.mock('../../components/map/MapView', () => ({
  MapView: () => null,
}))

vi.mock('../../api/client', () => ({
  api: {
    get: vi.fn(),
    post: vi.fn(),
    patch: vi.fn(),
    delete: vi.fn(),
  },
}))

const http = vi.mocked(api)

describe('places', () => {
  beforeEach(async () => {
    http.get.mockReset()
    http.post.mockReset()
    http.patch.mockReset()
    http.delete.mockReset()
    await i18n.changeLanguage('en')
    http.get.mockImplementation(async (path: string) => {
      if (path === '/places') return paginated([place()])
      throw new Error(path)
    })
  })

  it('shows Create and Edit for company admin', async () => {
    renderPage(<PlacesPage />, '/company-admin/places')

    expect(await screen.findByRole('button', { name: 'Add place' })).toBeInTheDocument()
    expect(await screen.findByRole('button', { name: 'Edit' })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Delete' })).toBeInTheDocument()
  })

  it('sends only the changed fields when a place is edited', async () => {
    const user = userEvent.setup()
    http.patch.mockResolvedValue(place({ name_en: 'North gate' }))
    renderPage(<PlacesPage />)

    await user.click(await screen.findByRole('button', { name: 'Edit' }))
    const dialog = await screen.findByRole('dialog', { name: 'Edit place' })
    const name = within(dialog).getByLabelText('Name (English)')
    await user.clear(name)
    await user.type(name, 'North gate')
    await user.click(within(dialog).getByRole('button', { name: 'Save' }))

    await waitFor(() => {
      expect(http.patch).toHaveBeenCalledWith('/places/place-1', { name_en: 'North gate' })
    })
  })

  it('deletes a place only after confirmation', async () => {
    const user = userEvent.setup()
    http.delete.mockResolvedValue(place())
    renderPage(<PlacesPage />)

    await user.click(await screen.findByRole('button', { name: 'Delete' }))
    const dialog = await screen.findByRole('dialog', { name: 'Delete this place?' })
    await user.click(within(dialog).getByRole('button', { name: 'Delete' }))

    await waitFor(() => {
      expect(http.delete).toHaveBeenCalledWith('/places/place-1')
    })
    expect(await screen.findByText('Place deleted.')).toBeInTheDocument()
  })

  it('creates a place from typed coordinates and flags', async () => {
    const user = userEvent.setup()
    http.post.mockResolvedValue(place({ id: 'place-2', name_en: 'North gate' }))
    renderPage(<PlacesPage />)

    await user.click(await screen.findByRole('button', { name: 'Add place' }))
    const dialog = await screen.findByRole('dialog', { name: 'Add place' })
    await user.type(within(dialog).getByLabelText('Name (English)'), 'North gate')
    await user.type(within(dialog).getByLabelText('Name (Arabic)'), 'البوابة')
    await user.type(within(dialog).getByLabelText('Address'), 'North road')
    await user.type(within(dialog).getByLabelText('Latitude'), '30.1')
    await user.type(within(dialog).getByLabelText('Longitude'), '31.2')
    await user.click(within(dialog).getByLabelText('Headquarters'))
    await user.click(within(dialog).getByRole('button', { name: 'Save' }))

    await waitFor(() => {
      expect(http.post).toHaveBeenCalledWith('/places', {
        name_en: 'North gate',
        name_ar: 'البوابة',
        address: 'North road',
        latitude: 30.1,
        longitude: 31.2,
        is_headquarters: true,
        is_active: true,
      })
    })
    expect(await screen.findByText('Place added.')).toBeInTheDocument()
  })

  it('creates a place with an address and no coordinates', async () => {
    const user = userEvent.setup()
    http.post.mockResolvedValue(place({ id: 'place-2', name_en: 'Depot', latitude: null, longitude: null }))
    renderPage(<PlacesPage />)

    await user.click(await screen.findByRole('button', { name: 'Add place' }))
    const dialog = await screen.findByRole('dialog', { name: 'Add place' })
    await user.type(within(dialog).getByLabelText('Name (English)'), 'Depot')
    await user.type(within(dialog).getByLabelText('Name (Arabic)'), 'المستودع')
    await user.type(within(dialog).getByLabelText('Address'), 'Industrial zone')
    await user.click(within(dialog).getByRole('button', { name: 'Save' }))

    await waitFor(() => {
      expect(http.post).toHaveBeenCalledWith('/places', {
        name_en: 'Depot',
        name_ar: 'المستودع',
        address: 'Industrial zone',
        is_headquarters: false,
        is_active: true,
      })
    })
  })
})
