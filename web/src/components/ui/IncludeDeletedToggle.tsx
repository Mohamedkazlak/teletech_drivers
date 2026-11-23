import { useTranslation } from 'react-i18next'

type IncludeDeletedToggleProps = {
  checked: boolean
  onChange: (checked: boolean) => void
}

export function IncludeDeletedToggle({ checked, onChange }: IncludeDeletedToggleProps) {
  const { t } = useTranslation()
  return (
    <label className="inline-flex items-center gap-2 text-sm text-navy">
      <input
        type="checkbox"
        checked={checked}
        onChange={(event) => onChange(event.target.checked)}
      />
      {t('common.includeDeleted')}
    </label>
  )
}
