import { act, fireEvent, render, screen } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { ToastProvider } from './ToastProvider'
import { useToast, type ToastTone } from './toast-context'

function Trigger({ tone }: { tone: ToastTone }) {
  const toast = useToast()
  return (
    <button type="button" onClick={() => toast(`A ${tone} message`, tone)}>
      Show
    </button>
  )
}

describe('ToastProvider', () => {
  beforeEach(() => {
    vi.useFakeTimers()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('keeps an error toast until it is closed', () => {
    render(
      <ToastProvider>
        <Trigger tone="error" />
      </ToastProvider>,
    )
    fireEvent.click(screen.getByRole('button', { name: 'Show' }))
    act(() => {
      vi.advanceTimersByTime(10_000)
    })
    const toast = screen.getByRole('alert')
    expect(toast).toHaveTextContent('A error message')

    fireEvent.click(screen.getByRole('button', { name: 'Close' }))
    act(() => {
      vi.advanceTimersByTime(300)
    })
    expect(screen.queryByText('A error message')).not.toBeInTheDocument()
  })

  it('dismisses a success toast on its own', () => {
    render(
      <ToastProvider>
        <Trigger tone="success" />
      </ToastProvider>,
    )
    fireEvent.click(screen.getByRole('button', { name: 'Show' }))
    expect(screen.getByText('A success message')).toBeInTheDocument()
    act(() => {
      vi.advanceTimersByTime(4_200)
    })
    expect(screen.queryByText('A success message')).not.toBeInTheDocument()
  })

  it('keeps at most three error toasts', () => {
    render(
      <ToastProvider>
        <Trigger tone="error" />
      </ToastProvider>,
    )
    for (let index = 0; index < 5; index += 1) {
      fireEvent.click(screen.getByRole('button', { name: 'Show' }))
    }
    expect(screen.getAllByRole('alert')).toHaveLength(3)
  })
})
