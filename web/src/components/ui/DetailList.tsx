import type { ReactNode } from 'react'

export function DetailList({ items }: { items: Array<{ label: string; value: ReactNode }> }) {
  return (
    <dl className="grid gap-3 sm:grid-cols-2">
      {items.map((item) => (
        <div key={item.label}>
          <dt className="text-xs font-medium text-navy/60">{item.label}</dt>
          <dd className="mt-0.5 text-sm text-navy">{item.value}</dd>
        </div>
      ))}
    </dl>
  )
}
