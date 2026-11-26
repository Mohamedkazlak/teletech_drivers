import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { useTranslation } from 'react-i18next'
import { afterEach, describe, expect, it } from 'vitest'
import i18n, { LOCALE_KEY } from '../../i18n'
import { LanguageToggle } from './LanguageToggle'

function Probe() {
  const { t } = useTranslation()
  return (
    <>
      <LanguageToggle />
      <h1>{t('auth.signIn')}</h1>
    </>
  )
}

afterEach(async () => {
  localStorage.removeItem(LOCALE_KEY)
  await i18n.changeLanguage('en')
})

describe('language and RTL toggle', () => {
  it('switches to Arabic, flips direction, and remembers the choice', async () => {
    const user = userEvent.setup()
    render(<Probe />)

    expect(document.documentElement.dir).toBe('ltr')
    expect(screen.getByRole('heading', { name: 'Sign in' })).toBeInTheDocument()

    await user.click(screen.getByRole('button', { name: 'العربية' }))

    expect(document.documentElement.lang).toBe('ar')
    expect(document.documentElement.dir).toBe('rtl')
    expect(localStorage.getItem(LOCALE_KEY)).toBe('ar')
    expect(screen.getByRole('heading', { name: 'تسجيل الدخول' })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'العربية' })).toHaveAttribute('aria-pressed', 'true')
  })

  it('switches back to English and left-to-right layout', async () => {
    const user = userEvent.setup()
    render(<Probe />)

    await user.click(screen.getByRole('button', { name: 'العربية' }))
    await user.click(screen.getByRole('button', { name: 'English' }))

    expect(document.documentElement.lang).toBe('en')
    expect(document.documentElement.dir).toBe('ltr')
    expect(localStorage.getItem(LOCALE_KEY)).toBe('en')
    expect(screen.getByRole('heading', { name: 'Sign in' })).toBeInTheDocument()
  })

  it('shows short labels in the compact variant and keeps full names for screen readers', async () => {
    const user = userEvent.setup()
    render(<LanguageToggle compact />)

    const arabic = screen.getByRole('button', { name: 'العربية' })
    expect(arabic).toHaveTextContent('ع')
    expect(screen.getByRole('button', { name: 'English' })).toHaveTextContent('EN')

    await user.click(arabic)
    expect(document.documentElement.dir).toBe('rtl')
  })
})
