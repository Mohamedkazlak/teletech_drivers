import { render, screen, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { DataTable, type Column } from './DataTable'
import { RowActions } from './RowActions'

type Row = { id: string; name: string; phone: string }

const rows: Row[] = [
  { id: '1', name: 'Nader Ali', phone: '0100' },
  { id: '2', name: 'Huda Samir', phone: '0111' },
]

function columns(onEdit = vi.fn()): Column<Row>[] {
  return [
    { id: 'name', header: 'Name', accessor: (row) => row.name, mobile: 'title' },
    { id: 'phone', header: 'Phone', accessor: (row) => row.phone },
    {
      id: 'actions',
      header: 'Actions',
      isActions: true,
      accessor: (row) => (
        <RowActions
          label={`Actions for ${row.name}`}
          items={[{ label: 'Edit', onSelect: () => onEdit(row) }]}
        />
      ),
    },
  ]
}

function mockPhone(matches: boolean) {
  vi.stubGlobal(
    'matchMedia',
    vi.fn().mockImplementation((query: string) => ({
      matches: query.includes('max-width') ? matches : false,
      media: query,
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
      addListener: vi.fn(),
      removeListener: vi.fn(),
      onchange: null,
      dispatchEvent: vi.fn(),
    })),
  )
}

afterEach(() => {
  vi.unstubAllGlobals()
})

describe('DataTable rows', () => {
  it('opens a row when it is clicked', async () => {
    const user = userEvent.setup()
    const onRowClick = vi.fn()
    render(
      <DataTable
        columns={columns()}
        rows={rows}
        rowKey={(row) => row.id}
        onRowClick={onRowClick}
      />,
    )
    await user.click(screen.getByText('0111'))
    expect(onRowClick).toHaveBeenCalledWith(rows[1])
  })

  it('does not open the row when its action menu is used', async () => {
    const user = userEvent.setup()
    const onRowClick = vi.fn()
    const onEdit = vi.fn()
    render(
      <DataTable
        columns={columns(onEdit)}
        rows={rows}
        rowKey={(row) => row.id}
        onRowClick={onRowClick}
      />,
    )
    await user.click(screen.getByRole('button', { name: 'Actions for Nader Ali' }))
    await user.click(screen.getByRole('menuitem', { name: 'Edit' }))
    expect(onEdit).toHaveBeenCalledWith(rows[0])
    expect(onRowClick).not.toHaveBeenCalled()
  })
})

describe('DataTable pagination', () => {
  it('hides the pager on a single page and shows the total', () => {
    render(
      <DataTable
        columns={columns()}
        rows={rows}
        rowKey={(row) => row.id}
        page={1}
        lastPage={1}
        total={2}
        onPageChange={() => {}}
      />,
    )
    expect(screen.queryByRole('button', { name: /Next/ })).not.toBeInTheDocument()
    expect(screen.getByText('2 results')).toBeInTheDocument()
  })

  it('shows the pager when there is more than one page', () => {
    render(
      <DataTable
        columns={columns()}
        rows={rows}
        rowKey={(row) => row.id}
        page={1}
        lastPage={3}
        onPageChange={() => {}}
      />,
    )
    expect(screen.getByRole('button', { name: /Next/ })).toBeEnabled()
  })
})

describe('DataTable on a phone', () => {
  it('renders each row as a card with the title column as its heading', () => {
    mockPhone(true)
    render(<DataTable columns={columns()} rows={rows} rowKey={(row) => row.id} />)
    expect(screen.queryByRole('table')).not.toBeInTheDocument()
    const cards = screen.getAllByRole('listitem')
    expect(cards).toHaveLength(2)
    expect(within(cards[0]).getByRole('heading', { name: 'Nader Ali' })).toBeInTheDocument()
    expect(within(cards[0]).getByText('Phone')).toBeInTheDocument()
    expect(within(cards[0]).getByText('0100')).toBeInTheDocument()
  })
})
