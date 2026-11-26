import { describe, expect, it } from 'vitest'
import { staggerDelay } from './motion'

describe('staggerDelay', () => {
  it('follows the design system delays and caps at 165 ms', () => {
    expect([0, 1, 2, 3, 4, 5, 6, 9].map(staggerDelay)).toEqual([
      0, 50, 90, 120, 145, 165, 165, 165,
    ])
  })
})
