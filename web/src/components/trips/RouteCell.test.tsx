import { render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import { RouteCell } from './RouteCell'

describe('RouteCell', () => {
  it('shows both ends of the route and the time', () => {
    render(<RouteCell from="Cairo Headquarters" to="New Capital" when="2026-11-26T13:58:00Z" />)
    expect(screen.getByText('Cairo Headquarters')).toBeInTheDocument()
    expect(screen.getByText('New Capital')).toBeInTheDocument()
    expect(screen.getByText(/^Thu 26 Nov, 3:58/)).toBeInTheDocument()
  })

  it('shows a dash for a missing place', () => {
    render(<RouteCell from={null} to="New Capital" />)
    expect(screen.getByText('—')).toBeInTheDocument()
    expect(screen.queryByText('null')).not.toBeInTheDocument()
  })

  it('keeps the full name of a long place in its title', () => {
    const name = 'Smart Village Building B2, Gate 4, Cairo–Alexandria Desert Road'
    render(<RouteCell from={name} to="HQ" />)
    expect(screen.getByText(name)).toHaveAttribute('title', name)
  })

  it('mirrors the connector line in Arabic', () => {
    const { container } = render(<RouteCell from="A" to="B" />)
    expect(container.querySelector('[data-route-line]')).toHaveClass('rtl:-scale-x-100')
  })
})
