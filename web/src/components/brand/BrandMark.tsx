import { useTranslation } from 'react-i18next'

type BrandMarkProps = {
  className?: string
  alt?: string
}

/** The TeleTech wordmark, as a vector so it stays crisp at any size. */
export function BrandMark({ className = 'h-8 w-auto', alt }: BrandMarkProps) {
  const { t } = useTranslation()
  return (
    <img
      src="/teletech_logo.svg"
      alt={alt ?? t('app.name')}
      className={`object-contain ${className}`}
      draggable={false}
    />
  )
}

/**
 * The concentric-ring mark on its own (blue disc, two white rings), drawn
 * with the logo's proportions. Used where the full wordmark is too wide.
 */
export function RingMark({ size = 36, className = '' }: { size?: number; className?: string }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 94 94"
      aria-hidden="true"
      focusable="false"
      className={className}
    >
      <circle cx="47" cy="47" r="47" fill="#2F7BEA" />
      <circle cx="48.9" cy="47" r="34" fill="none" stroke="#fff" strokeWidth="7" />
      <circle cx="51" cy="47.5" r="24" fill="none" stroke="#fff" strokeWidth="4.5" />
    </svg>
  )
}

/** A static field of concentric rings for dark hero surfaces. */
export function RingField({ className = '' }: { className?: string }) {
  return (
    <svg
      aria-hidden="true"
      focusable="false"
      className={`pointer-events-none absolute inset-0 h-full w-full ${className}`}
      preserveAspectRatio="xMaxYMin slice"
      viewBox="0 0 400 300"
    >
      {[1, 2, 3, 4, 5, 6].map((ring) => (
        <circle
          key={ring}
          cx="370"
          cy="30"
          r={ring * 62}
          fill="none"
          stroke="white"
          strokeOpacity="0.07"
          strokeWidth="1.2"
        />
      ))}
    </svg>
  )
}
