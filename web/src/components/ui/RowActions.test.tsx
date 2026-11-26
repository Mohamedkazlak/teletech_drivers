import { fireEvent, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'
import { RowActions } from './RowActions'

function setup() {
  const onEdit = vi.fn()
  const onDelete = vi.fn()
  render(
    <RowActions
      label="Actions for Nader Ali"
      items={[
        { label: 'Edit', onSelect: onEdit },
        { label: 'Delete', onSelect: onDelete, danger: true },
      ]}
    />,
  )
  return {
    onEdit,
    onDelete,
    trigger: screen.getByRole('button', { name: 'Actions for Nader Ali' }),
  }
}

describe('RowActions', () => {
  it('opens with the keyboard and focuses the first item', async () => {
    const user = userEvent.setup()
    const { trigger } = setup()
    expect(trigger).toHaveAttribute('aria-haspopup', 'menu')
    trigger.focus()
    await user.keyboard('{Enter}')
    expect(trigger).toHaveAttribute('aria-expanded', 'true')
    expect(screen.getByRole('menuitem', { name: 'Edit' })).toHaveFocus()
  })

  it('moves between items with the arrow keys', async () => {
    const user = userEvent.setup()
    const { trigger } = setup()
    await user.click(trigger)
    await user.keyboard('{ArrowDown}')
    expect(screen.getByRole('menuitem', { name: 'Delete' })).toHaveFocus()
    await user.keyboard('{ArrowDown}')
    expect(screen.getByRole('menuitem', { name: 'Edit' })).toHaveFocus()
  })

  it('closes on Escape and returns focus to the trigger', async () => {
    const user = userEvent.setup()
    const { trigger } = setup()
    await user.click(trigger)
    await user.keyboard('{Escape}')
    expect(screen.queryByRole('menu')).not.toBeInTheDocument()
    expect(trigger).toHaveFocus()
  })

  it('runs the chosen item once and closes', async () => {
    const user = userEvent.setup()
    const { trigger, onDelete } = setup()
    await user.click(trigger)
    await user.click(screen.getByRole('menuitem', { name: 'Delete' }))
    expect(onDelete).toHaveBeenCalledTimes(1)
    expect(screen.queryByRole('menu')).not.toBeInTheDocument()
  })

  it('shows no menu button when the row has no actions', () => {
    render(
      <RowActions
        label="Actions for Sara"
        items={[]}
        primary={<button type="button">View</button>}
      />,
    )
    expect(screen.getByRole('button', { name: 'View' })).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: 'Actions for Sara' })).not.toBeInTheDocument()
  })

  it('returns focus to the trigger when Tab leaves the menu', async () => {
    const user = userEvent.setup()
    const { trigger } = setup()
    await user.click(trigger)
    await user.keyboard('{Tab}')
    expect(screen.queryByRole('menu')).not.toBeInTheDocument()
    expect(trigger).toHaveFocus()
  })

  it('returns focus to the trigger when the page scrolls', async () => {
    const user = userEvent.setup()
    const { trigger } = setup()
    await user.click(trigger)
    expect(screen.getByRole('menuitem', { name: 'Edit' })).toHaveFocus()
    fireEvent.scroll(window)
    expect(screen.queryByRole('menu')).not.toBeInTheDocument()
    expect(trigger).toHaveFocus()
  })
})
