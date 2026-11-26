import type { SVGProps } from 'react'

/*
  One drawn icon set: 24px grid, 1.75 stroke, round caps and joins.
  Icons are decorative by default (aria-hidden); give the control a label.
*/
type IconProps = SVGProps<SVGSVGElement> & { size?: number }

function Icon({ size = 20, children, ...rest }: IconProps) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={1.75}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
      focusable="false"
      {...rest}
    >
      {children}
    </svg>
  )
}

export const DashboardIcon = (p: IconProps) => (
  <Icon {...p}>
    <rect x="3.5" y="3.5" width="7" height="8" rx="2" />
    <rect x="13.5" y="3.5" width="7" height="5" rx="2" />
    <rect x="13.5" y="11.5" width="7" height="9" rx="2" />
    <rect x="3.5" y="14.5" width="7" height="6" rx="2" />
  </Icon>
)

export const CarIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M5 16.5V12l1.8-4.6A2 2 0 0 1 8.7 6h6.6a2 2 0 0 1 1.9 1.4L19 12v4.5" />
    <path d="M3.5 12h17v4.5a1 1 0 0 1-1 1h-15a1 1 0 0 1-1-1z" />
    <path d="M6.5 17.5v1.5M17.5 17.5v1.5" />
    <circle cx="7.5" cy="14.75" r=".9" fill="currentColor" stroke="none" />
    <circle cx="16.5" cy="14.75" r=".9" fill="currentColor" stroke="none" />
  </Icon>
)

export const PeopleIcon = (p: IconProps) => (
  <Icon {...p}>
    <circle cx="9" cy="8.5" r="3.25" />
    <path d="M3.5 19a5.5 5.5 0 0 1 11 0" />
    <path d="M15.5 5.6a3.25 3.25 0 0 1 0 5.8M17 13.9a5.5 5.5 0 0 1 3.5 5.1" />
  </Icon>
)

export const UserKeyIcon = (p: IconProps) => (
  <Icon {...p}>
    <circle cx="10" cy="8" r="3.5" />
    <path d="M3.5 19.5a6.5 6.5 0 0 1 10.3-5.3" />
    <circle cx="17.5" cy="15.5" r="2.25" />
    <path d="m19.2 17.2 1.8 1.8M20.2 18.2l-.9.9" />
  </Icon>
)

export const PinIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M12 21s-6.5-5.6-6.5-11a6.5 6.5 0 0 1 13 0c0 5.4-6.5 11-6.5 11z" />
    <circle cx="12" cy="10" r="2.4" />
  </Icon>
)

export const RouteIcon = (p: IconProps) => (
  <Icon {...p}>
    <circle cx="6" cy="18" r="2.25" />
    <circle cx="18" cy="6" r="2.25" />
    <path d="M8.25 18h7.25a3 3 0 0 0 0-6h-7a3 3 0 0 1 0-6h7.25" />
  </Icon>
)

export const ClipboardIcon = (p: IconProps) => (
  <Icon {...p}>
    <rect x="5" y="4.5" width="14" height="16" rx="2.5" />
    <path d="M9 4.5V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v.5" />
    <path d="M8.5 10.5h7M8.5 14h7M8.5 17.5h4" />
  </Icon>
)

export const BriefcaseIcon = (p: IconProps) => (
  <Icon {...p}>
    <rect x="3.5" y="7" width="17" height="12.5" rx="2.5" />
    <path d="M9 7V5.5a1.5 1.5 0 0 1 1.5-1.5h3A1.5 1.5 0 0 1 15 5.5V7" />
    <path d="M3.5 12.5h17" />
  </Icon>
)

export const CalendarCheckIcon = (p: IconProps) => (
  <Icon {...p}>
    <rect x="3.5" y="5" width="17" height="15.5" rx="2.5" />
    <path d="M8 3v4M16 3v4M3.5 10h17" />
    <path d="m9 15 2 2 4-4" />
  </Icon>
)

export const MapIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M9 4.5 3.5 6.5v13l5.5-2 6 2 5.5-2v-13l-5.5 2z" />
    <path d="M9 4.5v13M15 6.5v13" />
  </Icon>
)

export const ChartIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M4 20h16" />
    <rect x="5.5" y="11" width="3" height="6.5" rx="1" />
    <rect x="10.5" y="6" width="3" height="11.5" rx="1" />
    <rect x="15.5" y="13.5" width="3" height="4" rx="1" />
  </Icon>
)

export const MenuIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M4 7h16M4 12h16M4 17h10" />
  </Icon>
)

export const SearchIcon = (p: IconProps) => (
  <Icon {...p}>
    <circle cx="11" cy="11" r="6.5" />
    <path d="m20 20-4.2-4.2" />
  </Icon>
)

export const CloseIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M6 6l12 12M18 6 6 18" />
  </Icon>
)

export const BellIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M6 16.5V11a6 6 0 0 1 12 0v5.5l1.5 2h-15z" />
    <path d="M10 20.5a2.2 2.2 0 0 0 4 0" />
  </Icon>
)

export const ChevronStartIcon = (p: IconProps) => (
  <Icon {...p} className={`rtl:-scale-x-100 ${p.className ?? ''}`}>
    <path d="m14.5 6-6 6 6 6" />
  </Icon>
)

export const ChevronEndIcon = (p: IconProps) => (
  <Icon {...p} className={`rtl:-scale-x-100 ${p.className ?? ''}`}>
    <path d="m9.5 6 6 6-6 6" />
  </Icon>
)

export const ChevronDownIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="m6 9.5 6 6 6-6" />
  </Icon>
)

export const SortIcon = ({ direction, ...p }: IconProps & { direction?: 'asc' | 'desc' }) => (
  <Icon {...p}>
    <path d="m8 9.5 4-4 4 4" opacity={direction === 'desc' ? 0.3 : 1} />
    <path d="m8 14.5 4 4 4-4" opacity={direction === 'asc' ? 0.3 : 1} />
  </Icon>
)

export const LogoutIcon = (p: IconProps) => (
  <Icon {...p} className={`rtl:-scale-x-100 ${p.className ?? ''}`}>
    <path d="M14 4.5h3.5a2 2 0 0 1 2 2v11a2 2 0 0 1-2 2H14" />
    <path d="M10 8 6 12l4 4M6.5 12H15" />
  </Icon>
)

export const UserIcon = (p: IconProps) => (
  <Icon {...p}>
    <circle cx="12" cy="8.5" r="3.75" />
    <path d="M4.5 20a7.5 7.5 0 0 1 15 0" />
  </Icon>
)

export const SettingsIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M4 7h10M18 7h2M4 17h2M10 17h10" />
    <circle cx="16" cy="7" r="2" />
    <circle cx="8" cy="17" r="2" />
  </Icon>
)

export const CheckIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="m5 12.5 4.5 4.5L19 7.5" />
  </Icon>
)

export const AlertIcon = (p: IconProps) => (
  <Icon {...p}>
    <circle cx="12" cy="12" r="8.5" />
    <path d="M12 7.75v5M12 16.25v.01" />
  </Icon>
)

export const InfoIcon = (p: IconProps) => (
  <Icon {...p}>
    <circle cx="12" cy="12" r="8.5" />
    <path d="M12 11v5M12 7.75v.01" />
  </Icon>
)

export const RefreshIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M19.5 12a7.5 7.5 0 1 1-2.2-5.3" />
    <path d="M19.5 4.5v4h-4" />
  </Icon>
)

export const ArrowEndIcon = (p: IconProps) => (
  <Icon {...p} className={`rtl:-scale-x-100 ${p.className ?? ''}`}>
    <path d="M5 12h14M13 6l6 6-6 6" />
  </Icon>
)
