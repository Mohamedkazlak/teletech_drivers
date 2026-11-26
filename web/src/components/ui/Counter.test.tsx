import { render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import { Counter } from './Counter'

describe('Counter', () => {
  it('shows the first value without marking it as changed', () => {
    render(<Counter value={0} />)
    const counter = screen.getByTestId('counter')
    expect(counter).not.toHaveAttribute('data-changed')
    expect(screen.queryByRole('img')).not.toBeInTheDocument()
    expect(screen.getByText('0', { selector: '.sr-only' })).toBeInTheDocument()
  })

  it('marks a later change so it can flash', async () => {
    const { rerender } = render(<Counter value={0} />)
    rerender(<Counter value={3} />)
    expect(await screen.findByText('3', { selector: '.sr-only' })).toBeInTheDocument()
    expect(screen.getByTestId('counter')).toHaveAttribute('data-changed', 'true')
  })
})
