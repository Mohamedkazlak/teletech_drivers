import { useEffect, useId, useRef, useState, type ReactNode } from 'react'
import { useTranslation } from 'react-i18next'
import { Link } from 'react-router-dom'
import type { User } from '../../api/types'
import type { RealtimeStatus } from '../../realtime/use-fleet-realtime'
import { NotificationMenu } from '../notifications/NotificationMenu'
import { BrandMark } from '../brand/BrandMark'
import { ChevronDownIcon, LogoutIcon, MenuIcon, SettingsIcon, UserIcon } from '../icons'
import { initials } from '../../lib/initials'
import { LanguageToggle } from '../language/LanguageToggle'
import { iconButtonClass, menuItemClass, menuPanelClass } from '../ui/styles'
import { BackButton } from './BackButton'
import { ConnectionStatus } from './ConnectionStatus'

type TopBarProps = {
  user: User
  connection: RealtimeStatus
  onMenu: () => void
  onLogout: () => void
}

export function TopBar({ user, connection, onMenu, onLogout }: TopBarProps) {
  const { t, i18n } = useTranslation()
  const [open, setOpen] = useState(false)
  const menuId = useId()
  const rootRef = useRef<HTMLDivElement>(null)
  const name = i18n.language.startsWith('ar') && user.name_ar ? user.name_ar : user.name_en

  useEffect(() => {
    function onPointer(event: MouseEvent) {
      if (!rootRef.current?.contains(event.target as Node)) setOpen(false)
    }
    function onKey(event: KeyboardEvent) {
      if (event.key === 'Escape') setOpen(false)
    }
    document.addEventListener('mousedown', onPointer)
    document.addEventListener('keydown', onKey)
    return () => {
      document.removeEventListener('mousedown', onPointer)
      document.removeEventListener('keydown', onKey)
    }
  }, [])

  return (
    <header className="sticky top-0 z-20 flex h-16 items-center gap-2.5 border-b border-line bg-white/85 px-4 backdrop-blur-md backdrop-saturate-150 sm:px-6">
      <button
        type="button"
        className={`${iconButtonClass} lg:hidden`}
        aria-label={t('common.openMenu')}
        onClick={onMenu}
      >
        <MenuIcon size={19} />
      </button>
      <BackButton />
      <BrandMark className="h-7 w-auto lg:hidden" />
      <div className="ms-auto flex items-center gap-2 sm:gap-2.5">
        <ConnectionStatus status={connection} />
        <NotificationMenu />
        <div className="sm:hidden">
          <LanguageToggle compact />
        </div>
        <div className="hidden sm:block">
          <LanguageToggle />
        </div>
        <div ref={rootRef} className="relative">
          <button
            type="button"
            className="inline-flex h-10 max-w-56 items-center gap-2 rounded-full border border-line bg-white py-1 pe-2.5 ps-1 text-sm font-semibold text-navy transition-[background-color,border-color,transform] duration-150 ease-[var(--ease-out)] hover:border-light hover:bg-pale/60 active:scale-[0.97]"
            aria-haspopup="menu"
            aria-expanded={open}
            aria-controls={menuId}
            onClick={() => setOpen((current) => !current)}
          >
            <span
              aria-hidden="true"
              className="inline-flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-[linear-gradient(140deg,#0b4da2,#0b1f45)] text-xs font-semibold text-white"
            >
              {initials(name)}
            </span>
            <span className="truncate">{name}</span>
            <ChevronDownIcon
              size={16}
              className={`shrink-0 text-ink-muted transition-transform duration-200 ${open ? 'rotate-180' : ''}`}
            />
          </button>
          {open ? (
            <div id={menuId} role="menu" className={`${menuPanelClass} w-60`}>
              <div className="px-3 pb-2 pt-1.5">
                <p className="truncate text-sm font-semibold text-navy">{name}</p>
                <p className="truncate text-xs text-ink-muted">{t(`role.${user.role}`)}</p>
              </div>
              <div className="mb-1 h-px bg-line" />
              <MenuLink
                to="/profile"
                label={t('nav.profile')}
                icon={<UserIcon size={18} />}
                onPick={() => setOpen(false)}
              />
              <MenuLink
                to="/settings"
                label={t('nav.settings')}
                icon={<SettingsIcon size={18} />}
                onPick={() => setOpen(false)}
              />
              <div className="my-1 h-px bg-line" />
              <button
                type="button"
                role="menuitem"
                className={`${menuItemClass} text-danger-ink hover:bg-danger/8`}
                onClick={() => {
                  setOpen(false)
                  onLogout()
                }}
              >
                <LogoutIcon size={18} />
                {t('common.signOut')}
              </button>
            </div>
          ) : null}
        </div>
      </div>
    </header>
  )
}

function MenuLink({
  to,
  label,
  icon,
  onPick,
}: {
  to: string
  label: string
  icon: ReactNode
  onPick: () => void
}) {
  return (
    <Link to={to} role="menuitem" className={`${menuItemClass} text-ink-muted hover:text-navy`} onClick={onPick}>
      <span className="text-ink-muted">{icon}</span>
      <span className="text-navy">{label}</span>
    </Link>
  )
}
