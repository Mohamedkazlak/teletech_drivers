import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'
import { formatDateParam } from '../../lib/period'
import { PeriodControl } from './PeriodBar'

describe('PeriodControl', () => {
  it('selects a period with its anchor date', async () => {
    const user = userEvent.setup()
    const onChange = vi.fn()
    render(
      <PeriodControl
        value={{ period: 'week', date: '2026-11-26' }}
        onChange={onChange}
        periods={['week', 'month', 'year', 'all']}
      />,
    )
    expect(screen.getByRole('radio', { name: 'Week' })).toHaveAttribute('aria-checked', 'true')
    await user.click(screen.getByRole('radio', { name: 'Month' }))
    expect(onChange).toHaveBeenCalledWith({ period: 'month', date: '2026-11-26' })
  })

  it('hides the stepper when the period is All', () => {
    render(
      <PeriodControl
        value={{ period: 'all' }}
        onChange={() => {}}
        periods={['week', 'month', 'year', 'all']}
      />,
    )
    expect(screen.queryByRole('button', { name: 'Previous period' })).not.toBeInTheDocument()
  })

  it('only offers the periods it is given', () => {
    render(
      <PeriodControl
        value={{ period: 'day' }}
        onChange={() => {}}
        periods={['day', 'week', 'month', 'year']}
      />,
    )
    expect(screen.queryByRole('radio', { name: 'All' })).not.toBeInTheDocument()
    expect(screen.getByRole('radio', { name: 'Day' })).toBeInTheDocument()
  })

  it('calls the current day Today', () => {
    render(
      <PeriodControl
        value={{ period: 'day', date: formatDateParam(new Date()) }}
        onChange={() => {}}
        periods={['day', 'week']}
      />,
    )
    expect(screen.getByText('Today')).toBeInTheDocument()
  })

  it('moves the selection with arrow keys', async () => {
    const user = userEvent.setup()
    const onChange = vi.fn()
    render(
      <PeriodControl
        value={{ period: 'week', date: '2026-11-26' }}
        onChange={onChange}
        periods={['week', 'month']}
      />,
    )
    screen.getByRole('radio', { name: 'Week' }).focus()
    await user.keyboard('{ArrowRight}')
    expect(onChange).toHaveBeenCalledWith({ period: 'month', date: '2026-11-26' })
  })
})
