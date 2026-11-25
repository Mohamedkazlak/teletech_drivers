import { useLayoutEffect, useRef, useState, type ComponentType } from 'react'
import { useTranslation } from 'react-i18next'
import { NavLink, useLocation } from 'react-router-dom'
import type { WebRole } from '../../api/types'
import { RingField, RingMark } from '../brand/BrandMark'
import {
  BriefcaseIcon,
  CalendarCheckIcon,
  CarIcon,
  ChartIcon,
  ClipboardIcon,
  DashboardIcon,
  MapIcon,
  PeopleIcon,
  PinIcon,
  RouteIcon,
  UserKeyIcon,
} from '../icons'
import { NAV, type NavIcon } from './nav'

const ICONS: Record<NavIcon, ComponentType<{ size?: number; className?: string }>> = {
  dashboard: DashboardIcon,
  drivers: CarIcon,
  employees: PeopleIcon,
  users: UserKeyIcon,
  places: PinIcon,
  trips: RouteIcon,
  requests: ClipboardIcon,
  myTrips: BriefcaseIcon,
  attendance: CalendarCheckIcon,
  liveMap: MapIcon,
  reports: ChartIcon,
}

type SidebarProps = {
  role: WebRole
  onNavigate?: () => void
}

type Indicator = { top: number; height: number } | null

export function Sidebar({ role, onNavigate }: SidebarProps) {
  const { t } = useTranslation()
  const items = NAV[role]
  const location = useLocation()
  const navRef = useRef<HTMLElement>(null)
  const [indicator, setIndicator] = useState<Indicator>(null)
  const [ready, setReady] = useState(false)

  // The active highlight is one pill that glides between items.
  useLayoutEffect(() => {
    const nav = navRef.current
    if (!nav) return
    const active = nav.querySelector<HTMLElement>('a[aria-current="page"]')
    setIndicator(active ? { top: active.offsetTop, height: active.offsetHeight } : null)
    const frame = requestAnimationFrame(() => setReady(true))
    return () => cancelAnimationFrame(frame)
  }, [location.pathname, role])

  return (
    <div className="relative flex h-full flex-col overflow-hidden bg-[linear-gradient(170deg,#0b1f45_0%,#071533_100%)] text-white">
      <RingField className="opacity-80" />
      <div className="relative flex items-center gap-3 px-5 pb-5 pt-6">
        <RingMark size={38} className="shrink-0 drop-shadow-[0_4px_10px_rgb(47_123_234/0.45)]" />
        <div className="min-w-0">
          <p className="truncate text-[15px] font-semibold tracking-[-0.01em]">{t('app.name')}</p>
          <p className="truncate text-xs text-white/60">{t('app.tagline')}</p>
        </div>
      </div>
      <nav
        ref={navRef}
        aria-label={t('common.menu')}
        className="relative flex flex-1 flex-col gap-0.5 overflow-y-auto px-3 pb-4"
      >
        {indicator ? (
          <span
            aria-hidden="true"
            className={`absolute inset-x-3 rounded-[12px] bg-white/[0.1] shadow-[inset_0_0_0_1px_rgb(255_255_255/0.08)] ${
              ready ? 'transition-[transform,height] duration-[320ms] ease-[var(--ease-in-out)]' : ''
            }`}
            style={{ height: indicator.height, transform: `translateY(${indicator.top}px)`, top: 0 }}
          />
        ) : null}
        {items.map((item) => {
          const Icon = item.icon ? ICONS[item.icon] : null
          return (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.end}
              onClick={onNavigate}
              className={({ isActive }) =>
                `group relative z-10 flex h-11 items-center gap-3 rounded-[12px] px-3 text-sm transition-colors duration-150 ${
                  isActive
                    ? 'font-semibold text-white'
                    : 'text-white/65 hover:bg-white/[0.05] hover:text-white'
                }`
              }
            >
              {({ isActive }) => (
                <>
                  {Icon ? (
                    <Icon
                      size={19}
                      className={`shrink-0 transition-colors ${isActive ? 'text-[#8fb9ff]' : 'text-white/55 group-hover:text-white/85'}`}
                    />
                  ) : null}
                  <span className="truncate">{t(item.labelKey)}</span>
                </>
              )}
            </NavLink>
          )
        })}
      </nav>
    </div>
  )
}
