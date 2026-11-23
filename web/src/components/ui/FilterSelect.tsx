import { useId, type ReactNode } from 'react'
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
    <div className="flex w-full max-w-xs flex-col gap-1.5">
      <label htmlFor={id} className="text-sm font-bold text-navy">
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

export function FilterRow({ children }: { children: ReactNode }) {
  return <div className="flex flex-wrap items-end gap-3">{children}</div>
}
