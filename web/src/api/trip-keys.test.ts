import { describe, expect, it } from 'vitest'
import { tripKeys } from './use-trips'

describe('trip query keys', () => {
  it('keeps the fleet list and my trips in different caches', () => {
    const fleet = tripKeys.list({ stage: 'unassigned', branch: 'company_headquarters' })
    const mine = tripKeys.mine({ bucket: 'active' })

    expect(fleet[0]).toBe('trips')
    expect(mine[0]).toBe('my-trips')
    expect(fleet[0]).not.toBe(mine[0])
  })
})
