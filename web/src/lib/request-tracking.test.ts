import { describe, expect, it } from 'vitest'
import { trackingChipStatus } from './request-tracking'

describe('trackingChipStatus', () => {
  it('maps each lifecycle stage onto the requester chip', () => {
    expect(trackingChipStatus('submitted')).toBe('pending')
    expect(trackingChipStatus('approved')).toBe('approved')
    expect(trackingChipStatus('driver_assigned')).toBe('driver_assigned')
    expect(trackingChipStatus('in_progress')).toBe('in_progress')
    expect(trackingChipStatus('finished')).toBe('completed')
    expect(trackingChipStatus('awaiting_confirmation')).toBe('completed')
    expect(trackingChipStatus('confirmed')).toBe('completed')
    expect(trackingChipStatus('unconfirmed')).toBe('completed')
    expect(trackingChipStatus('rejected')).toBe('rejected')
    expect(trackingChipStatus('cancelled')).toBe('cancelled')
  })
})
