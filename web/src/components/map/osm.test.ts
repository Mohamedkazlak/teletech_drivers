import { describe, expect, it } from 'vitest'
import { OSM_ATTRIBUTION, OSM_TILE_URL } from './osm'

describe('osm tiles', () => {
  it('uses the canonical tile URL and contributor attribution', () => {
    expect(OSM_TILE_URL).toBe('https://tile.openstreetmap.org/{z}/{x}/{y}.png')
    expect(OSM_TILE_URL).not.toContain('{s}')
    expect(OSM_ATTRIBUTION).toContain('OpenStreetMap contributors')
  })
})
