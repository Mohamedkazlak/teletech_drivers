import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { describe, expect, it, vi } from 'vitest'
import { EmptyState } from './EmptyState'

describe('EmptyState', () => {
  it('links to the next step', () => {
    render(
      <MemoryRouter>
        <EmptyState
          message="No trips this week."
          action={{ label: 'Show all', to: '/trips?period=all' }}
        />
      </MemoryRouter>,
    )
    expect(screen.getByText('No trips this week.')).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Show all' })).toHaveAttribute(
      'href',
      '/trips?period=all',
    )
  })

  it('runs an action button', async () => {
    const user = userEvent.setup()
    const onClick = vi.fn()
    render(<EmptyState message="Nothing matches." action={{ label: 'Clear filters', onClick }} />)
    await user.click(screen.getByRole('button', { name: 'Clear filters' }))
    expect(onClick).toHaveBeenCalledTimes(1)
  })
})
