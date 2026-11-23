import { describe, expect, it } from 'vitest'
import { readCoordinate } from './coordinates'

describe('readCoordinate', () => {
  it('reads a string, a number, and null', () => {
    expect(readCoordinate('30.0444')).toBe(30.0444)
    expect(readCoordinate(31.2)).toBe(31.2)
    expect(readCoordinate(null)).toBeNull()
    expect(readCoordinate('')).toBeNull()
    expect(readCoordinate('north')).toBeNull()
  })
})
