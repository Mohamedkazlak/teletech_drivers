import { describe, expect, it } from 'vitest'
import { endOfFleetWeek, startOfFleetWeek } from './period'

describe('fleet week', () => {
  it('starts on Saturday and ends on Friday', () => {
    const wednesday = new Date(2026, 10, 11)
    const start = startOfFleetWeek(wednesday)
    const end = endOfFleetWeek(wednesday)

    expect(start.getDay()).toBe(6)
    expect(start.getDate()).toBe(7)
    expect(end.getDay()).toBe(5)
    expect(end.getDate()).toBe(13)
  })
})
