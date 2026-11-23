import { describe, expect, it } from 'vitest'
import { cairoInputToIso, isFutureCairoInput, nextSlotInput } from './cairo-schedule'

describe('cairo schedule', () => {
  const now = new Date('2026-11-16T12:00:00.000Z')

  it('defaults to the next Cairo minute and closes earlier times', () => {
    expect(nextSlotInput(now)).toBe('2026-11-16T14:01')
    expect(isFutureCairoInput('2026-11-16T14:00', now)).toBe(false)
    expect(isFutureCairoInput('2026-11-16T14:01', now)).toBe(true)
    expect(isFutureCairoInput('2026-11-15T18:00', now)).toBe(false)
    expect(cairoInputToIso('2026-11-16T14:01')).toBe('2026-11-16T12:01:00.000Z')
  })

  it('rolls to the next day in the last minute', () => {
    expect(nextSlotInput(new Date('2026-11-16T21:59:10.000Z'))).toBe('2026-11-17T00:00')
  })
})
