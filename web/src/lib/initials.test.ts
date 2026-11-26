import { describe, expect, it } from 'vitest'
import { initials } from './initials'

describe('initials', () => {
  it('skips the Arabic article on the last word', () => {
    expect(initials('مدير النظام')).toBe('من')
    expect(initials('مسؤول السائقين')).toBe('مس')
  })

  it('uses first and last initials for Latin names', () => {
    expect(initials('Test Admin')).toBe('TA')
  })

  it('uses one letter for a single word', () => {
    expect(initials('omar')).toBe('O')
  })

  it('falls back to a question mark for blank names', () => {
    expect(initials('  ')).toBe('?')
  })
})
