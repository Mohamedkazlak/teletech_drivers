import { useTranslation } from 'react-i18next'
import { Switch } from './Switch'

type IncludeDeletedToggleProps = {
  checked: boolean
  onChange: (checked: boolean) => void
}

export function IncludeDeletedToggle({ checked, onChange }: IncludeDeletedToggleProps) {
  const { t } = useTranslation()
  return <Switch checked={checked} onChange={onChange} label={t('common.includeDeleted')} />
}
