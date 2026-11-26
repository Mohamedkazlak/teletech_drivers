import { describe, expect, it } from 'vitest'
import { formatDate, formatDateTime, formatWhen } from './format'

describe('formatDate', () => {
  it('shows weekday, day and month in Cairo time', () => {
    expect(formatDate('2026-11-26T13:58:00Z', 'en')).toBe('Thu 26 Nov')
  })

  it('shows a dash for missing values', () => {
    expect(formatDate(undefined, 'en')).toBe('—')
  })
})

describe('formatDateTime', () => {
  it('adds the Cairo time after a comma', () => {
    expect(formatDateTime('2026-11-26T13:58:00Z', 'en')).toBe('Thu 26 Nov, 3:58\u00a0PM')
  })

  it('shows a dash for missing values', () => {
    expect(formatDateTime(null, 'en')).toBe('—')
  })

  it('keeps the Arabic time on one line', () => {
    const value = formatDateTime('2026-11-26T13:58:00Z', 'ar')
    expect(value).not.toMatch(/\n/)
    expect(value).toContain(' ')
  })
})

describe('formatWhen', () => {
  it('uses the same Cairo format as formatDateTime', () => {
    expect(formatWhen('2026-11-26T13:58:00Z', 'en')).toBe(formatDateTime('2026-11-26T13:58:00Z', 'en'))
  })

  it('stays empty for missing values so callers can pick a fallback', () => {
    expect(formatWhen(null, 'en')).toBe('')
  })
})
