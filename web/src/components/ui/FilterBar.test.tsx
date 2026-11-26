import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { useState } from 'react'
import { describe, expect, it, vi } from 'vitest'
import { FilterBar } from './FilterBar'
import { Switch } from './Switch'

function SearchHarness({ onClear = () => {} }: { onClear?: () => void }) {
  const [value, setValue] = useState('')
  return (
    <FilterBar
      search={{ value, onChange: setValue, label: 'Search drivers' }}
      activeCount={value ? 1 : 0}
      onClear={onClear}
    />
  )
}

describe('FilterBar', () => {
  it('hides Clear filters when nothing is filtered', () => {
    render(<FilterBar activeCount={0} onClear={() => {}} />)
    expect(screen.queryByRole('button', { name: 'Clear filters' })).not.toBeInTheDocument()
  })

  it('clears every filter from one button', async () => {
    const user = userEvent.setup()
    const onClear = vi.fn()
    render(<FilterBar activeCount={2} onClear={onClear} />)
    await user.click(screen.getByRole('button', { name: 'Clear filters' }))
    expect(onClear).toHaveBeenCalledTimes(1)
  })

  it('types into the search box and empties it with the clear button', async () => {
    const user = userEvent.setup()
    render(<SearchHarness />)
    const input = screen.getByRole('searchbox', { name: 'Search drivers' })
    await user.type(input, 'om')
    expect(input).toHaveValue('om')
    await user.click(screen.getByRole('button', { name: 'Clear search' }))
    expect(input).toHaveValue('')
  })
})

describe('Switch', () => {
  it('toggles its checked state', async () => {
    const user = userEvent.setup()
    function Harness() {
      const [on, setOn] = useState(false)
      return <Switch checked={on} onChange={setOn} label="Include deleted" />
    }
    render(<Harness />)
    const toggle = screen.getByRole('switch', { name: 'Include deleted' })
    expect(toggle).toHaveAttribute('aria-checked', 'false')
    await user.click(toggle)
    expect(toggle).toHaveAttribute('aria-checked', 'true')
  })
})
