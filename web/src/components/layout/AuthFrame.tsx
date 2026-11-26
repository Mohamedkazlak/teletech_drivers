import { lazy, Suspense, type ReactNode } from 'react'
import { BrandMark } from '../brand/BrandMark'
import { LanguageToggle } from '../language/LanguageToggle'

// WebGL rings (React Bits) load after the form, so sign-in is never blocked.
const MagicRings = lazy(() => import('../reactbits/MagicRings'))

type AuthFrameProps = {
  title: string
  subtitle?: string | null
  children: ReactNode
}

function canAnimateRings(): boolean {
  if (typeof window === 'undefined' || typeof window.matchMedia !== 'function') return false
  return !window.matchMedia('(prefers-reduced-motion: reduce)').matches
}

export function AuthFrame({ title, subtitle, children }: AuthFrameProps) {
  const rings = canAnimateRings()

  return (
    <div className="relative min-h-dvh overflow-hidden bg-scaffold">
      <div
        aria-hidden="true"
        className="absolute inset-x-0 top-0 h-[52vh] min-h-[360px] overflow-hidden bg-[linear-gradient(140deg,#0b4da2_0%,#0b1f45_58%,#071533_100%)]"
      >
        {rings ? (
          <Suspense fallback={null}>
            <MagicRings
              className="opacity-70"
              color="#2F7BEA"
              colorTwo="#8CA6D9"
              ringCount={6}
              motion="ripple"
              speed={0.45}
              lineThickness={1.4}
              glow={0.8}
              baseRadius={0.18}
              radiusStep={0.09}
              followMouse
              mouseInfluence={0.12}
              clickBurst={false}
              theme="dark"
            />
          </Suspense>
        ) : null}
        <div className="absolute inset-x-0 bottom-0 h-24 bg-gradient-to-b from-transparent to-[#071533]/40" />
      </div>
      <div className="relative mx-auto flex min-h-dvh w-full max-w-[440px] flex-col px-5 py-6">
        <div className="mb-4 flex justify-end">
          <LanguageToggle tone="dark" />
        </div>
        <div className="mb-6 flex justify-center animate-pop">
          <div className="rounded-[40px] bg-white px-8 py-5 shadow-auth">
            <BrandMark className="h-[76px] w-auto" alt="" />
          </div>
        </div>
        <div className="rounded-auth border border-white/60 bg-white px-6 pb-6 pt-7 shadow-auth [animation-delay:80ms] animate-rise">
          <h1 className="text-[22px] font-semibold tracking-[-0.01em] text-navy">{title}</h1>
          {subtitle ? <p className="mt-1 text-sm text-ink-muted animate-fade">{subtitle}</p> : null}
          <div className="mt-6">{children}</div>
        </div>
      </div>
    </div>
  )
}
