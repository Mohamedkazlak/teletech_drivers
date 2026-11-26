import { useId, useMemo, useState, type KeyboardEvent } from 'react'
import { useTranslation } from 'react-i18next'
import { useDriverRoster } from '../../api/use-drivers'
import { localizedName } from '../../lib/names'
import { CloseIcon } from '../icons'
import { controlClass } from './styles'

type DriverPickerProps = {
  value: string | null
  onChange: (driverId: string | null) => void
}

const MAX_OPTIONS = 8

/*
  Searchable driver filter. The fleet roster is small and already cached for
  other screens, so it filters the full roster by name as you type.
*/
export function DriverPicker({ value, onChange }: DriverPickerProps) {
  const { t, i18n } = useTranslation()
  const id = useId()
  const listId = `${id}-list`
  const roster = useDriverRoster(true)
  const drivers = useMemo(() => roster.data ?? [], [roster.data])
  const selected = drivers.find((driver) => driver.id === value)
  // A filter from the URL may name a driver the roster doesn't have (still
  // loading, deleted): say so rather than looking like "Any driver".
  const selectedName = selected
    ? localizedName(i18n.language, selected.name_en, selected.name_ar)
    : value
      ? roster.isPending
        ? t('common.loading')
        : t('filters.unknownDriver')
      : ''
  const [draft, setDraft] = useState<string | null>(null)
  const [open, setOpen] = useState(false)
  const [active, setActive] = useState(0)
  const text = draft ?? selectedName

  const matches = useMemo(() => {
    const needle = (draft ?? '').trim().toLowerCase()
    return drivers
      .filter((driver) =>
        [driver.name_en, driver.name_ar].some((name) => name?.toLowerCase().includes(needle)),
      )
      .slice(0, MAX_OPTIONS)
  }, [drivers, draft])

  function pick(driverId: string | null) {
    onChange(driverId)
    setDraft(null)
    setOpen(false)
  }

  function onKeyDown(event: KeyboardEvent<HTMLInputElement>) {
    if (event.key === 'ArrowDown') {
      event.preventDefault()
      setOpen(true)
      setActive((index) => Math.min(index + 1, matches.length - 1))
    } else if (event.key === 'ArrowUp') {
      event.preventDefault()
      setActive((index) => Math.max(index - 1, 0))
    } else if (event.key === 'Enter' && open && matches[active]) {
      event.preventDefault()
      pick(matches[active].id)
    } else if (event.key === 'Escape') {
      setDraft(null)
      setOpen(false)
    }
  }

  return (
    <div className="relative flex min-w-56 flex-col gap-1">
      <label htmlFor={id} className="text-xs font-semibold text-ink-muted">
        {t('attendance.driver')}
      </label>
      <input
        id={id}
        role="combobox"
        aria-expanded={open}
        aria-controls={listId}
        aria-autocomplete="list"
        aria-activedescendant={open && matches[active] ? `${id}-${matches[active].id}` : undefined}
        autoComplete="off"
        placeholder={t('filters.anyDriver')}
        className={`${controlClass} pe-10`}
        value={text}
        onChange={(event) => {
          setDraft(event.target.value)
          setActive(0)
          setOpen(true)
        }}
        onFocus={() => setOpen(true)}
        onBlur={() => {
          setOpen(false)
          setDraft(null)
        }}
        onKeyDown={onKeyDown}
      />
      {value ? (
        <button
          type="button"
          aria-label={t('filters.clearDriver')}
          className="absolute end-1.5 bottom-1.5 inline-flex h-8 w-8 items-center justify-center rounded-[9px] text-ink-muted transition-colors duration-150 hover:bg-pale hover:text-navy"
          onClick={() => pick(null)}
        >
          <CloseIcon size={16} />
        </button>
      ) : null}
      {open && matches.length > 0 ? (
        <ul
          id={listId}
          role="listbox"
          className="absolute inset-x-0 top-full z-30 mt-1.5 max-h-72 overflow-auto rounded-[14px] border border-line bg-white p-1.5 shadow-float animate-pop"
        >
          {matches.map((driver, index) => (
            <li
              key={driver.id}
              id={`${id}-${driver.id}`}
              role="option"
              aria-selected={driver.id === value}
              // Keep focus in the input so the list doesn't close before the click lands.
              onMouseDown={(event) => event.preventDefault()}
              onClick={() => pick(driver.id)}
              className={`cursor-pointer rounded-[10px] px-3 py-2 text-sm text-navy ${
                index === active ? 'bg-pale' : 'hover:bg-pale/60'
              }`}
            >
              {localizedName(i18n.language, driver.name_en, driver.name_ar)}
            </li>
          ))}
        </ul>
      ) : null}
    </div>
  )
}
