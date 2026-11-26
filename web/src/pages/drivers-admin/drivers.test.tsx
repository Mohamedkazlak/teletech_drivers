import { screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { Route, Routes, Link } from 'react-router-dom'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { api } from '../../api/client'
import { ApiError } from '../../api/errors'
import i18n from '../../i18n'
import { driver, paginated, place, renderPage } from '../../test/render-page'
import { DriverProfilePage } from './DriverProfilePage'
import { DriversPage } from './DriversPage'

vi.mock('../../components/charts/BarChartCard', () => ({
  BarChartCard: ({ title }: { title: string }) => <h2>{title}</h2>,
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

function queriesFor(path: string) {
  return http.get.mock.calls
    .filter((call) => call[0] === path)
    .map((call) => (call[1] as { query?: Record<string, unknown> } | undefined)?.query)
}

const statsBody = {
  period: 'week',
  from: '2026-11-07T22:00:00.000Z',
  to: '2026-11-14T22:00:00.000Z',
  trips: 2,
  total_seconds: 3600,
  total_km: 12.5,
  breakdown: [
    {
      label: 'Sat',
      from: null,
      to: null,
      trips: 2,
      total_seconds: 3600,
      total_km: 12.5,
    },
  ],
}

function places(count: number) {
  return Array.from({ length: count }, (_, index) =>
    place({
      id: `place-${index + 1}`,
      name_en: `Place ${index + 1}`,
      name_ar: `مكان ${index + 1}`,
      is_headquarters: false,
    }),
  )
}

describe('drivers admin roster', () => {
  beforeEach(async () => {
    http.get.mockReset()
    http.post.mockReset()
    http.patch.mockReset()
    http.delete.mockReset()
    await i18n.changeLanguage('en')
    http.get.mockImplementation(async (path: string) => {
      if (path === '/drivers') return paginated([driver({ trips_this_week: 1 })])
      if (path === '/places') return paginated([])
      throw new Error(path)
    })
  })

  afterEach(async () => {
    await i18n.changeLanguage('en')
  })

  it('keeps attendance, search, and page in the request', async () => {
    const user = userEvent.setup()
    renderPage(<DriversPage />, '/?attendance=not_checked_in&search=ali')

    await waitFor(() => {
      expect(queriesFor('/drivers')).toContainEqual({
        attendance: 'not_checked_in',
        search: 'ali',
        per_page: 15,
      })
    })

    await user.selectOptions(screen.getByRole('combobox', { name: 'Attendance' }), 'Checked in today')

    await waitFor(() => {
      expect(queriesFor('/drivers')).toContainEqual({
        attendance: 'checked_in',
        search: 'ali',
        per_page: 15,
      })
    })
    expect(queriesFor('/trips')).toEqual([])
    await waitFor(() => {
      const row = screen.getByRole('row', { name: /Nader Ali/ })
      expect(within(row).getByText('1')).toBeInTheDocument()
      expect(within(row).getByText('ط ع ب 9295')).toBeInTheDocument()
      expect(within(row).getByText('نادر علي')).toBeInTheDocument()
      expect(within(row).getByText('Checked in')).toBeInTheDocument()
    })
  })

  it('restores filters from the URL and clears them all at once', async () => {
    const user = userEvent.setup()
    renderPage(<DriversPage />, '/?attendance=checked_in&search=om&page=2')

    expect(screen.getByRole('combobox', { name: 'Attendance' })).toHaveValue('checked_in')
    expect(screen.getByRole('searchbox', { name: 'Search drivers' })).toHaveValue('om')

    await user.click(screen.getByRole('button', { name: 'Clear filters' }))

    expect(screen.getByRole('combobox', { name: 'Attendance' })).toHaveValue('')
    expect(screen.getByRole('searchbox', { name: 'Search drivers' })).toHaveValue('')
    expect(screen.queryByRole('button', { name: 'Clear filters' })).not.toBeInTheDocument()
    await waitFor(() => {
      expect(queriesFor('/drivers').at(-1)).toEqual({ per_page: 15 })
    })
  })

  it('requests the next page', async () => {
    const user = userEvent.setup()
    http.get.mockImplementation(async (path: string) => {
      if (path === '/drivers') {
        return {
          data: [driver()],
          meta: { current_page: 1, per_page: 15, last_page: 2, total: 16 },
        }
      }
      throw new Error(path)
    })
    renderPage(<DriversPage />)
    await user.click(await screen.findByRole('button', { name: 'Next' }))
    await waitFor(() => {
      expect(queriesFor('/drivers')).toContainEqual({ page: 2, per_page: 15 })
    })
  })

  it('shows a 422 field error and stops at five favorite places', async () => {
    const user = userEvent.setup()
    http.get.mockImplementation(async (path: string) => {
      if (path === '/drivers') return paginated([])
      if (path === '/places') return paginated(places(6))
      throw new Error(path)
    })
    http.post.mockRejectedValueOnce(
      new ApiError('The given data was invalid.', 422, {
        errors: { email: ['The email has already been taken.'] },
      }),
    )
    http.post.mockResolvedValue(driver())
    renderPage(<DriversPage />)

    await user.click(screen.getByRole('button', { name: 'Add driver' }))
    const dialog = await screen.findByRole('dialog', { name: 'Add driver' })
    expect(
      within(dialog).getByText(/must change this password on first login/i),
    ).toBeInTheDocument()
    await user.type(within(dialog).getByLabelText('Name (English)'), 'Nader Ali')
    await user.type(within(dialog).getByLabelText('Name (Arabic)'), 'نادر علي')
    await user.type(within(dialog).getByLabelText('Email'), 'nader@example.com')
    await user.type(within(dialog).getByLabelText('Phone'), '01011111111')
    await user.type(within(dialog).getByLabelText('National ID number'), '12345678901234')
    await user.type(within(dialog).getByLabelText('Letters'), 'طعب')
    await user.type(within(dialog).getByLabelText('Numbers'), '9295')
    await user.type(within(dialog).getByLabelText('Personal license'), 'PER-9')
    await user.type(within(dialog).getByLabelText('Temporary password'), 'temporary1')
    const favorites = within(dialog).getByLabelText('Favorite places')
    await waitFor(() => expect(favorites).toBeEnabled())
    for (let index = 1; index <= 5; index += 1) {
      await user.selectOptions(favorites, `place-${index}`)
    }
    expect(favorites).toBeDisabled()
    expect(within(dialog).getAllByRole('button', { name: /^Remove / })).toHaveLength(5)
    await user.click(within(dialog).getByRole('button', { name: 'Save' }))

    await waitFor(() =>
      expect(within(dialog).getByRole('alert')).toHaveTextContent(
        'The email has already been taken.',
      ),
    )
    expect(http.post).toHaveBeenCalledTimes(1)

    http.post.mockResolvedValueOnce(driver())
    await user.clear(within(dialog).getByLabelText('Email'))
    await user.type(within(dialog).getByLabelText('Email'), 'other@example.com')
    await user.click(within(dialog).getByRole('button', { name: 'Save' }))

    await waitFor(() => {
      expect(http.post).toHaveBeenCalledWith(
        '/drivers',
        expect.objectContaining({
          email: 'other@example.com',
          phone: '01011111111',
          car_license: 'ط ع ب 9295',
          favorite_place_ids: ['place-1', 'place-2', 'place-3', 'place-4', 'place-5'],
        }),
      )
    })
    const body = http.post.mock.calls.at(-1)?.[1] as { favorite_place_ids: string[] }
    expect(body.favorite_place_ids).not.toContain('place-6')
  })

  it('sends only the changed fields when a driver is edited', async () => {
    const user = userEvent.setup()
    http.patch.mockResolvedValue(driver({ phone: '01022222222' }))
    renderPage(<DriversPage />)

    await user.click(await screen.findByRole('button', { name: 'Edit' }))
    const dialog = await screen.findByRole('dialog', { name: 'Edit driver' })
    expect(within(dialog).getByLabelText('Email')).toHaveAttribute('readonly')
    const phone = within(dialog).getByLabelText('Phone')
    await user.clear(phone)
    await user.type(phone, '01022222222')
    await user.click(within(dialog).getByRole('button', { name: 'Save' }))

    await waitFor(() => {
      expect(http.patch).toHaveBeenCalledWith('/drivers/driver-1', { phone: '01022222222' })
    })
  })

  it('deletes a driver only after confirmation', async () => {
    const user = userEvent.setup()
    http.delete.mockResolvedValue(driver())
    renderPage(<DriversPage />)

    await user.click(await screen.findByRole('button', { name: 'Delete' }))
    expect(http.delete).not.toHaveBeenCalled()
    const dialog = await screen.findByRole('dialog', { name: 'Delete this driver?' })
    await user.click(within(dialog).getByRole('button', { name: 'Delete' }))

    await waitFor(() => {
      expect(http.delete).toHaveBeenCalledWith('/drivers/driver-1')
    })
    expect(await screen.findByText('Driver deleted.')).toBeInTheDocument()
  })

  it('resets the profile period when the driver changes', async () => {
    const user = userEvent.setup()
    http.get.mockImplementation(async (path: string) => {
      if (path === '/drivers/driver-1/stats' || path === '/drivers/driver-2/stats') return statsBody
      if (path === '/drivers/driver-1/trips' || path === '/drivers/driver-2/trips')
        return paginated([])
      if (path === '/drivers/driver-1') {
        return driver({ totals: { trips: 4, total_seconds: 7200, total_km: 30 } })
      }
      if (path === '/drivers/driver-2') {
        return driver({
          id: 'driver-2',
          name_en: 'Huda Samir',
          name_ar: 'هدى سمير',
          email: 'huda@example.com',
        })
      }
      if (path === '/places') return paginated([])
      if (path.endsWith('/attendance')) {
        return {
          data: [],
          totals: { days_present: 0, days_absent: 0, total_on_site_hours: 0 },
          meta: { current_page: 1, per_page: 15, total: 0, last_page: 1 },
        }
      }
      throw new Error(path)
    })

    function Screen() {
      return (
        <>
          <Link to="/drivers/driver-2">Open Huda</Link>
          <Routes>
            <Route path="/drivers/:driverId" element={<DriverProfilePage />} />
          </Routes>
        </>
      )
    }

    renderPage(<Screen />, '/drivers/driver-1')
    expect(await screen.findByRole('heading', { name: 'Nader Ali' })).toBeInTheDocument()
    await user.click(screen.getByRole('radio', { name: 'Year' }))
    await waitFor(() => {
      expect(queriesFor('/drivers/driver-1/stats').some((query) => query?.period === 'year')).toBe(
        true,
      )
    })

    await user.click(screen.getByRole('link', { name: 'Open Huda' }))
    expect(await screen.findByRole('heading', { name: 'Huda Samir' })).toBeInTheDocument()
    expect(screen.getByRole('radio', { name: 'Week' })).toHaveAttribute('aria-checked', 'true')
    await waitFor(() => {
      expect(queriesFor('/drivers/driver-2/stats').some((query) => query?.period === 'week')).toBe(
        true,
      )
    })
    expect(queriesFor('/drivers/driver-2/stats').every((query) => query?.period !== 'year')).toBe(
      true,
    )
    expect(queriesFor('/drivers/driver-2/trips').some((query) => query?.period === 'week')).toBe(
      true,
    )
  })

  it('renders Arabic with a right-to-left document', async () => {
    await i18n.changeLanguage('ar')
    renderPage(<DriversPage />)
    expect(document.documentElement.dir).toBe('rtl')
    expect(document.documentElement.lang).toBe('ar')
    expect(await screen.findByRole('heading', { name: 'السائقون' })).toBeInTheDocument()
    expect(screen.getByRole('option', { name: 'مسجّل الحضور اليوم' })).toBeInTheDocument()
    expect(screen.queryByRole('switch', { name: 'إظهار المحذوف' })).not.toBeInTheDocument()
  })
})

describe('admin driver restore', () => {
  beforeEach(async () => {
    http.get.mockReset()
    http.post.mockReset()
    await i18n.changeLanguage('en')
    http.get.mockImplementation(
      async (path: string, options?: { query?: { include_deleted?: boolean } }) => {
        if (path === '/drivers') {
          if (options?.query?.include_deleted) {
            return paginated([
              driver({ deleted_at: '2026-11-02T00:00:00.000Z', deleted_by: 'admin-1' }),
            ])
          }
          return paginated([driver()])
        }
        if (path === '/places') return paginated([])
        throw new Error(path)
      },
    )
  })

  it('shows include-deleted and restore only for the system admin', async () => {
    const user = userEvent.setup()
    const fleet = renderPage(<DriversPage />)
    expect(screen.queryByRole('switch', { name: 'Include deleted' })).not.toBeInTheDocument()
    expect(await screen.findByRole('button', { name: 'Edit' })).toBeInTheDocument()
    fleet.unmount()

    renderPage(<DriversPage allowDeleted />)
    await user.click(screen.getByRole('switch', { name: 'Include deleted' }))
    await waitFor(() => {
      expect(queriesFor('/drivers')).toContainEqual(
        expect.objectContaining({ include_deleted: true, per_page: 15 }),
      )
    })
    expect(await screen.findByRole('button', { name: 'Restore' })).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: 'Edit' })).not.toBeInTheDocument()
    expect(screen.getByText('Deleted')).toBeInTheDocument()

    http.post.mockResolvedValue(driver())
    await user.click(screen.getByRole('button', { name: 'Restore' }))
    const dialog = await screen.findByRole('dialog', { name: 'Restore this driver?' })
    await user.click(within(dialog).getByRole('button', { name: 'Restore' }))
    await waitFor(() => {
      expect(http.post).toHaveBeenCalledWith('/drivers/driver-1/restore')
    })
    expect(await screen.findByText('Driver restored.')).toBeInTheDocument()
  })
})
