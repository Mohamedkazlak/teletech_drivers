import { useId } from 'react'
import { controlClass } from './styles'

export type FilterOption = {
  value: string
  label: string
}

type FilterSelectProps = {
  label: string
  options: FilterOption[]
  value: string
  onChange: (value: string) => void
}

export function FilterSelect({ label, options, value, onChange }: FilterSelectProps) {
  const id = useId()
  return (
    <div className="flex min-w-44 flex-col gap-1">
      <label htmlFor={id} className="text-xs font-semibold text-ink-muted">
        {label}
      </label>
      <select
        id={id}
        className={controlClass}
        value={value}
        onChange={(event) => onChange(event.target.value)}
      >
        {options.map((option) => (
          <option key={option.value} value={option.value}>
            {option.label}
          </option>
        ))}
      </select>
    </div>
  )
}
