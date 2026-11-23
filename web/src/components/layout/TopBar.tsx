import { useEffect, useId, useRef, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Link } from 'react-router-dom'
import type { User } from '../../api/types'
import type { RealtimeStatus } from '../../realtime/use-fleet-realtime'
import { NotificationMenu } from '../notifications/NotificationMenu'
import { BrandMark } from '../brand/BrandMark'
import { LanguageToggle } from '../language/LanguageToggle'
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
    <header className="flex h-16 items-center gap-3 border-b border-pale bg-white px-4">
      <BackButton />
      <button
        type="button"
        className="inline-flex h-10 w-10 items-center justify-center rounded-control border-[1.5px] border-mid text-deep lg:hidden"
        aria-label={t('common.openMenu')}
        onClick={onMenu}
      >
        <span aria-hidden="true" className="text-lg leading-none">
          ☰
        </span>
      </button>
      <BrandMark className="h-8 w-auto" />
      <p className="hidden text-sm font-bold text-navy/70 sm:block">{t(`role.${user.role}`)}</p>
      <div className="ms-auto flex items-center gap-2 sm:gap-3">
        <ConnectionStatus status={connection} />
        <NotificationMenu />
        <LanguageToggle />
        <div ref={rootRef} className="relative">
          <button
            type="button"
            className="inline-flex h-10 max-w-48 items-center gap-2 rounded-control border-[1.5px] border-mid px-3 text-sm font-bold text-navy"
            aria-haspopup="menu"
            aria-expanded={open}
            aria-controls={menuId}
            onClick={() => setOpen((current) => !current)}
          >
            <span className="truncate">{name}</span>
          </button>
          {open ? (
            <div
              id={menuId}
              role="menu"
              className="absolute end-0 z-20 mt-1 w-48 rounded-control border border-pale bg-white py-1 shadow-dialog"
            >
              <MenuLink to="/profile" label={t('nav.profile')} onPick={() => setOpen(false)} />
              <MenuLink to="/settings" label={t('nav.settings')} onPick={() => setOpen(false)} />
              <button
                type="button"
                role="menuitem"
                className="block w-full px-3 py-2 text-start text-sm text-navy hover:bg-pale"
                onClick={() => {
                  setOpen(false)
                  onLogout()
                }}
              >
                {t('common.signOut')}
              </button>
            </div>
          ) : null}
        </div>
      </div>
    </header>
  )
}

function MenuLink({ to, label, onPick }: { to: string; label: string; onPick: () => void }) {
  return (
    <Link
      to={to}
      role="menuitem"
      className="block px-3 py-2 text-sm text-navy hover:bg-pale"
      onClick={onPick}
    >
      {label}
    </Link>
  )
}
