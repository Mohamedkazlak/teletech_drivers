import type { ReactNode } from 'react'
import { BrandMark } from '../brand/BrandMark'
import { LanguageToggle } from '../language/LanguageToggle'

type AuthFrameProps = {
  title: string
  subtitle?: string | null
  children: ReactNode
}

export function AuthFrame({ title, subtitle, children }: AuthFrameProps) {
  return (
    <div className="relative min-h-dvh bg-scaffold">
      <div
        aria-hidden="true"
        className="absolute inset-x-0 top-0 h-[40vh] bg-gradient-to-br from-deep to-mid"
      />
      <div className="relative mx-auto flex min-h-dvh w-full max-w-[420px] flex-col px-5 py-6">
        <div className="mb-2 flex justify-end">
          <LanguageToggle />
        </div>
        <div className="mb-5 flex justify-center">
          <div className="rounded-[40px] bg-white px-7 py-[18px] shadow-auth">
            <BrandMark className="h-[90px] w-auto" alt="" />
          </div>
        </div>
        <div className="rounded-auth bg-white px-[22px] pb-5 pt-6 shadow-dialog">
          <h1 className="text-[22px] font-bold text-navy">{title}</h1>
          {subtitle ? <p className="mt-1 text-sm text-navy/75">{subtitle}</p> : null}
          <div className="mt-5">{children}</div>
        </div>
      </div>
    </div>
  )
}
