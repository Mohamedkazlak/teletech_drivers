import { render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import { TripPhase } from './TripPhase'

describe('TripPhase', () => {
  it('names the current step out of five', () => {
    render(<TripPhase status="going" />)
    expect(screen.getByRole('img', { name: 'Phase 2 of 5: Going' })).toBeInTheDocument()
    expect(screen.getByText('Going')).toBeInTheDocument()
  })

  it('shows a status chip for trips outside the five steps', () => {
    render(<TripPhase status="unassigned" />)
    expect(screen.queryByRole('img', { name: /Phase/ })).not.toBeInTheDocument()
    expect(screen.getByText('Unassigned')).toBeInTheDocument()
  })

  it('shows awaiting report for a completed trip waiting on confirmation', () => {
    render(<TripPhase status="completed" confirmation="pending" />)
    expect(screen.queryByRole('img', { name: /Phase/ })).not.toBeInTheDocument()
  })

  it('pulses only while the trip is moving', () => {
    const { container, rerender } = render(<TripPhase status="returning" />)
    expect(container.querySelector('[data-live]')).not.toBeNull()
    rerender(<TripPhase status="assigned" />)
    expect(container.querySelector('[data-live]')).toBeNull()
  })
})
