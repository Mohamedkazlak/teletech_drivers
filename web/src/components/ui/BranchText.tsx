import { useTranslation } from 'react-i18next'
import { isBranch } from '../../lib/names'

export function BranchText({ value }: { value: string | null | undefined }) {
  const { t } = useTranslation()
  if (!value) return t('common.dash')
  if (isBranch(value)) return t(`branch.${value}`)
  return value
}
