import { useTranslation } from 'react-i18next'
import { NavLink } from 'react-router-dom'
import type { WebRole } from '../../api/types'
import { NAV } from './nav'

type SidebarProps = {
  role: WebRole
  onNavigate?: () => void
}

export function Sidebar({ role, onNavigate }: SidebarProps) {
  const { t } = useTranslation()
  const items = NAV[role]

  return (
    <div className="flex h-full flex-col bg-slate-900 text-slate-100">
      <div className="flex items-center gap-3 border-b border-white/10 px-4 py-4">
        <img
          src="/teletech_logo.png"
          alt=""
          className="h-10 w-10 rounded-md bg-white object-contain p-1"
        />
        <div className="min-w-0">
          <p className="truncate text-sm font-semibold">{t('app.name')}</p>
          <p className="truncate text-xs text-slate-400">{t('app.tagline')}</p>
        </div>
      </div>
      <nav aria-label={t('common.menu')} className="flex flex-1 flex-col gap-1 p-3">
        {items.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            end={item.end}
            onClick={onNavigate}
            className={({ isActive }) =>
              `rounded-md px-3 py-2 text-sm ${isActive ? 'bg-deep font-semibold text-white' : 'text-light hover:bg-mid/35 hover:text-white'}`
            }
          >
            {t(item.labelKey)}
          </NavLink>
        ))}
      </nav>
    </div>
  )
}
