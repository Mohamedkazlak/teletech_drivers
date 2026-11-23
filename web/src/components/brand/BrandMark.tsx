import { useTranslation } from 'react-i18next'

type BrandMarkProps = {
  className?: string
  alt?: string
}

export function BrandMark({ className = 'h-8 w-auto', alt }: BrandMarkProps) {
  const { t } = useTranslation()
  return (
    <img
      src="/teletech_logo.png"
      alt={alt ?? t('app.name')}
      className={`object-contain ${className}`}
    />
  )
}
