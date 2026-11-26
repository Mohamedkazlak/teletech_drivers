import { render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import { Counter } from './Counter'

describe('Counter', () => {
  it('shows the first value without marking it as changed', () => {
    render(<Counter value={0} />)
    const counter = screen.getByLabelText('0')
    expect(counter).not.toHaveAttribute('data-changed')
  })

  it('marks a later change so it can flash', async () => {
    const { rerender } = render(<Counter value={0} />)
    rerender(<Counter value={3} />)
    const counter = await screen.findByLabelText('3')
    expect(counter).toHaveAttribute('data-changed', 'true')
  })
})
