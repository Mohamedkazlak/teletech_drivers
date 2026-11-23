import { useTranslation } from 'react-i18next'
import type { Branch } from '../../api/types'
import { FilterSelect } from './FilterSelect'

export type BranchFilterValue = '' | Branch

type BranchFilterProps = {
  value: BranchFilterValue
  onChange: (value: BranchFilterValue) => void
}

export function BranchFilter({ value, onChange }: BranchFilterProps) {
  const { t } = useTranslation()
  return (
    <FilterSelect
      label={t('profile.branch')}
      value={value}
      onChange={(next) => onChange(next as BranchFilterValue)}
      options={[
        { value: '', label: t('branch.all') },
        { value: 'company_headquarters', label: t('branch.company_headquarters') },
        { value: 'new_headquarters', label: t('branch.new_headquarters') },
      ]}
    />
  )
}
