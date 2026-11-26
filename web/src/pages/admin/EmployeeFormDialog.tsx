import { zodResolver } from '@hookform/resolvers/zod'
import { useMemo, useState } from 'react'
import { useForm } from 'react-hook-form'
import { useTranslation } from 'react-i18next'
import { z } from 'zod'
import { ApiError } from '../../api/errors'
import type { Branch, Employee } from '../../api/types'
import { useCreateEmployee, useUpdateEmployee } from '../../api/use-employees'
import { BranchText } from '../../components/ui/BranchText'
import { DetailDialog } from '../../components/ui/DetailDialog'
import { DetailList } from '../../components/ui/DetailList'
import { fieldDescribedBy } from '../../components/ui/described-by'
import { FormField } from '../../components/ui/FormField'
import { StatusBadge } from '../../components/ui/StatusBadge'
import { controlClass, primaryButtonClass } from '../../components/ui/styles'
import { useToast } from '../../components/ui/toast-context'
import { messageForApiError } from '../../lib/api-message'
import { applyFieldErrors } from '../../lib/form-errors'
import { localizedName } from '../../lib/names'
import { changedEmployeeFields } from './employee-patch'

type EmployeeDialogMode = 'create' | 'edit' | 'view'

type EmployeeFormDialogProps = {
  mode: EmployeeDialogMode | null
  employee: Employee | null
  onClose: () => void
}

type FormValues = {
  name_en: string
  name_ar: string
  email: string
  phone: string
  branch: '' | Branch
  password: string
}

const FIELDS: Array<keyof FormValues> = [
  'name_en',
  'name_ar',
  'email',
  'phone',
  'branch',
  'password',
]

export function EmployeeFormDialog({ mode, employee, onClose }: EmployeeFormDialogProps) {
  const { t } = useTranslation()
  const title =
    mode === 'edit'
      ? t('employees.edit')
      : mode === 'view'
        ? t('employees.detailTitle')
        : t('employees.add')
  return (
    <DetailDialog open={mode !== null} title={title} onClose={onClose}>
      {mode === 'view' && employee ? <EmployeeView employee={employee} /> : null}
      {mode === 'create' || mode === 'edit' ? (
        <EmployeeForm
          key={`${mode}-${employee?.id ?? 'new'}`}
          mode={mode}
          employee={employee}
          onClose={onClose}
        />
      ) : null}
    </DetailDialog>
  )
}

function EmployeeView({ employee }: { employee: Employee }) {
  const { t, i18n } = useTranslation()
  return (
    <DetailList
      items={[
        { label: t('profile.nameEn'), value: employee.name_en },
        { label: t('profile.nameAr'), value: employee.name_ar || t('common.dash') },
        {
          label: t('places.name'),
          value: localizedName(i18n.language, employee.name_en, employee.name_ar),
        },
        { label: t('profile.email'), value: employee.email },
        { label: t('profile.phone'), value: employee.phone || t('common.dash') },
        { label: t('profile.branch'), value: <BranchText value={employee.branch} /> },
        {
          label: t('employees.active'),
          value: <StatusBadge status={employee.is_active ? 'active' : 'inactive'} />,
        },
        ...(employee.deleted_at
          ? [{ label: t('common.deleted'), value: <StatusBadge status="deleted" /> }]
          : []),
      ]}
    />
  )
}

function EmployeeForm({
  mode,
  employee,
  onClose,
}: {
  mode: 'create' | 'edit'
  employee: Employee | null
  onClose: () => void
}) {
  const { t } = useTranslation()
  const toast = useToast()
  const create = useCreateEmployee()
  const update = useUpdateEmployee()
  const [banner, setBanner] = useState<string | null>(null)
  const schema = useMemo(
    () =>
      z.object({
        name_en: z.string().trim().min(1, t('validation.required')).max(255),
        name_ar: z.string().trim().min(1, t('validation.required')).max(255),
        email: z
          .string()
          .trim()
          .min(1, t('validation.required'))
          .email(t('validation.email'))
          .max(255),
        phone: z.string().max(50),
        branch: z.enum(['', 'company_headquarters', 'new_headquarters']),
        password: mode === 'create' ? z.string().min(8, t('validation.minPassword')) : z.string(),
      }),
    [mode, t],
  )
  const {
    register,
    handleSubmit,
    setError,
    formState: { errors, isSubmitting },
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: {
      name_en: employee?.name_en ?? '',
      name_ar: employee?.name_ar ?? '',
      email: employee?.email ?? '',
      phone: employee?.phone ?? '',
      branch: employee?.branch ?? '',
      password: '',
    },
  })

  async function onSubmit(values: FormValues) {
    setBanner(null)
    try {
      if (mode === 'create') {
        await create.mutateAsync({
          name_en: values.name_en.trim(),
          name_ar: values.name_ar.trim(),
          email: values.email.trim(),
          password: values.password,
          phone: values.phone.trim() === '' ? null : values.phone.trim(),
          branch: values.branch === '' ? null : values.branch,
        })
        toast(t('employees.created'), 'success')
      } else if (employee) {
        const body = changedEmployeeFields(employee, values)
        if (Object.keys(body).length === 0) {
          onClose()
          return
        }
        await update.mutateAsync({ id: employee.id, body })
        toast(t('employees.saved'), 'success')
      }
      onClose()
    } catch (error) {
      const fieldBanner = applyFieldErrors(error, setError, FIELDS)
      setBanner(fieldBanner ?? (error instanceof ApiError ? null : messageForApiError(error, t)))
    }
  }

  return (
    <form
      className="flex flex-col gap-4"
      onSubmit={(event) => void handleSubmit(onSubmit)(event)}
      noValidate
    >
      {banner ? (
        <p role="alert" className="text-sm text-danger-ink">
          {banner}
        </p>
      ) : null}
      <FormField id="employee-name-en" label={t('profile.nameEn')} error={errors.name_en?.message}>
        <input
          id="employee-name-en"
          className={controlClass}
          aria-describedby={fieldDescribedBy('employee-name-en', errors.name_en?.message)}
          {...register('name_en')}
        />
      </FormField>
      <FormField id="employee-name-ar" label={t('profile.nameAr')} error={errors.name_ar?.message}>
        <input
          id="employee-name-ar"
          className={controlClass}
          aria-describedby={fieldDescribedBy('employee-name-ar', errors.name_ar?.message)}
          {...register('name_ar')}
        />
      </FormField>
      <FormField id="employee-email" label={t('profile.email')} error={errors.email?.message}>
        <input
          id="employee-email"
          type="email"
          className={controlClass}
          autoComplete="off"
          aria-describedby={fieldDescribedBy('employee-email', errors.email?.message)}
          {...register('email')}
        />
      </FormField>
      <FormField id="employee-phone" label={t('profile.phone')} error={errors.phone?.message}>
        <input
          id="employee-phone"
          className={controlClass}
          aria-describedby={fieldDescribedBy('employee-phone', errors.phone?.message)}
          {...register('phone')}
        />
      </FormField>
      <FormField id="employee-branch" label={t('profile.branch')} error={errors.branch?.message}>
        <select
          id="employee-branch"
          className={controlClass}
          aria-describedby={fieldDescribedBy('employee-branch', errors.branch?.message)}
          {...register('branch')}
        >
          <option value="">{t('profile.none')}</option>
          <option value="company_headquarters">{t('branch.company_headquarters')}</option>
          <option value="new_headquarters">{t('branch.new_headquarters')}</option>
        </select>
      </FormField>
      {mode === 'create' ? (
        <FormField
          id="employee-password"
          label={t('employees.password')}
          error={errors.password?.message}
          hint={t('employees.passwordHint')}
        >
          <input
            id="employee-password"
            type="password"
            className={controlClass}
            autoComplete="new-password"
            aria-describedby={fieldDescribedBy(
              'employee-password',
              errors.password?.message,
              t('employees.passwordHint'),
            )}
            {...register('password')}
          />
        </FormField>
      ) : null}
      <button type="submit" className={primaryButtonClass} disabled={isSubmitting}>
        {isSubmitting ? t('common.loading') : t('common.save')}
      </button>
    </form>
  )
}
