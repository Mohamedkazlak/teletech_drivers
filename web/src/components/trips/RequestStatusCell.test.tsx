import { render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import { RequestStatusCell } from './RequestStatusCell'

describe('RequestStatusCell', () => {
  it('says a pending request waits on the company admin', () => {
    render(<RequestStatusCell status="pending" tripId={null} />)
    expect(screen.getByText('Pending')).toBeInTheDocument()
    expect(screen.getByText('Waiting on company admin')).toBeInTheDocument()
  })

  it('says an approved request without a trip waits on the drivers admin', () => {
    render(<RequestStatusCell status="approved" tripId={null} />)
    expect(screen.getByText('Waiting on drivers admin')).toBeInTheDocument()
  })

  it('says nothing more once the trip exists', () => {
    render(<RequestStatusCell status="approved" tripId="trip-1" />)
    expect(screen.queryByText(/Waiting on/)).not.toBeInTheDocument()
  })
})
