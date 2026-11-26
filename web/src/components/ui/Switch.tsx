type SwitchProps = {
  checked: boolean
  onChange: (checked: boolean) => void
  label: string
}

/** On/off switch with a sliding thumb; the whole row is the hit target. */
export function Switch({ checked, onChange, label }: SwitchProps) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      onClick={() => onChange(!checked)}
      className="group inline-flex h-[var(--control-height)] select-none items-center gap-2.5 rounded-control px-1 text-sm font-medium text-navy"
    >
      <span
        aria-hidden="true"
        className={`relative inline-flex h-6 w-10 shrink-0 items-center rounded-full p-0.5 transition-colors duration-[180ms] ease-[var(--ease-out)] ${
          checked ? 'bg-deep' : 'bg-line group-hover:bg-light/60'
        }`}
      >
        <span
          className={`h-5 w-5 rounded-full bg-white shadow-[0_1px_3px_rgb(7_21_51/0.25)] transition-transform duration-[180ms] ease-[var(--ease-out)] ${
            checked ? 'translate-x-4 rtl:-translate-x-4' : ''
          }`}
        />
      </span>
      {label}
    </button>
  )
}
