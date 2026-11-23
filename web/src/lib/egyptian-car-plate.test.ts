import { describe, expect, it } from 'vitest'
import { canonicalPlate, parsePlate, plateLettersInput, plateNumbersInput } from './egyptian-car-plate'

describe('egyptian car plate', () => {
  it('keeps up to three letters and four digits', () => {
    expect(plateLettersInput('ط ع ب ج')).toBe('ط ع ب')
    expect(plateNumbersInput('92951')).toBe('9295')
  })

  it('builds the spaced plate and reads it back', () => {
    expect(canonicalPlate('طعب', '9295')).toBe('ط ع ب 9295')
    expect(parsePlate('طعب9295')).toEqual({ letters: 'ط ع ب', numbers: '9295' })
    expect(parsePlate('ا ب ١٢٣')).toEqual({ letters: 'أ ب', numbers: '123' })
    expect(parsePlate('CAR-1')).toBeNull()
    expect(canonicalPlate('', '9295')).toBeNull()
  })
})
