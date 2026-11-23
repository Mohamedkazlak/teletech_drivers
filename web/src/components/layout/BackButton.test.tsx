import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { Link, MemoryRouter, Route, Routes, useLocation } from 'react-router-dom'
import { describe, expect, it } from 'vitest'
import { BackButton } from './BackButton'

function Page() {
  const { pathname } = useLocation()
  return (
    <>
      <BackButton />
      <p>{pathname}</p>
      <Link to="/settings">Settings</Link>
      <Link to="/profile">Profile</Link>
    </>
  )
}

function renderAt(path: string) {
  return render(
    <MemoryRouter initialEntries={[path]}>
      <Routes>
        <Route path="*" element={<Page />} />
      </Routes>
    </MemoryRouter>,
  )
}

describe('BackButton', () => {
  it('stays hidden until there is a previous page', () => {
    renderAt('/admin')
    expect(screen.queryByRole('button', { name: 'Back' })).not.toBeInTheDocument()
  })

  it('returns to the previous page and hides again on the first page', async () => {
    const user = userEvent.setup()
    renderAt('/admin')

    await user.click(screen.getByRole('link', { name: 'Settings' }))
    expect(screen.getByText('/settings')).toBeInTheDocument()

    await user.click(screen.getByRole('button', { name: 'Back' }))
    expect(screen.getByText('/admin')).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: 'Back' })).not.toBeInTheDocument()
  })

  it('returns through more than one page', async () => {
    const user = userEvent.setup()
    renderAt('/admin')

    await user.click(screen.getByRole('link', { name: 'Settings' }))
    await user.click(screen.getByRole('link', { name: 'Profile' }))
    expect(screen.getByText('/profile')).toBeInTheDocument()

    await user.click(screen.getByRole('button', { name: 'Back' }))
    expect(screen.getByText('/settings')).toBeInTheDocument()

    await user.click(screen.getByRole('button', { name: 'Back' }))
    expect(screen.getByText('/admin')).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: 'Back' })).not.toBeInTheDocument()
  })
})
