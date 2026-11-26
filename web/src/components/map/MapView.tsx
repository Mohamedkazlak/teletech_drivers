import { useEffect, useRef } from 'react'
import L from 'leaflet'
import { MapContainer, Marker, Polyline, TileLayer, useMap, useMapEvents } from 'react-leaflet'
import 'leaflet/dist/leaflet.css'
import { readCoordinate } from '../../lib/coordinates'
import { OSM_ATTRIBUTION, OSM_TILE_URL } from './osm'

export type MapMarkerTone = 'place' | 'driver' | 'available' | 'unavailable' | 'on_trip'

export type MapMarker = {
  id: string
  lat: number
  lng: number
  label: string
  tone?: MapMarkerTone
}

export type MapPath = {
  id: string
  points: Array<{ lat: number; lng: number }>
}

type MapViewProps = {
  className?: string
  center?: [number, number]
  zoom?: number
  markers?: MapMarker[]
  paths?: MapPath[]
  onPick?: (lat: number, lng: number) => void
  onSelect?: (id: string) => void
}

const CAIRO: [number, number] = [30.0444, 31.2357]

const markerIcons: Record<MapMarkerTone, L.DivIcon> = {
  place: markerIcon('#4A78BE'),
  driver: markerIcon('#0B4DA2'),
  available: markerIcon('#2E9E6B'),
  unavailable: markerIcon('#D64545'),
  on_trip: markerIcon('#0B4DA2'),
}

function markerIcon(color: string): L.DivIcon {
  return L.divIcon({
    className: 'teletech-pin',
    html: `<span style="display:block;width:14px;height:14px;margin:-2px;border-radius:9999px;background:${color};border:2px solid #fff;box-shadow:0 0 0 1px ${color}"></span>`,
    iconSize: [14, 14],
    iconAnchor: [7, 7],
  })
}

export function MapView({
  className,
  center,
  zoom = 11,
  markers = [],
  paths = [],
  onPick,
  onSelect,
}: MapViewProps) {
  const drawnPaths = paths
    .map((path) => ({
      ...path,
      points: path.points.filter(
        (point) => readCoordinate(point.lat) != null && readCoordinate(point.lng) != null,
      ),
    }))
    .filter((path) => path.points.length > 0)
  const drawnMarkers = markers.filter(
    (marker) => readCoordinate(marker.lat) != null && readCoordinate(marker.lng) != null,
  )
  const initial =
    center ??
    (drawnMarkers[0]
      ? ([readCoordinate(drawnMarkers[0].lat)!, readCoordinate(drawnMarkers[0].lng)!] as [
          number,
          number,
        ])
      : CAIRO)

  return (
    <MapContainer
      center={initial}
      zoom={drawnMarkers.length === 1 ? 14 : zoom}
      scrollWheelZoom={Boolean(onPick)}
      className={className ?? 'h-80 w-full rounded-control'}
    >
      <TileLayer attribution={OSM_ATTRIBUTION} url={OSM_TILE_URL} />
      <InvalidateSize />
      <FitMarkers markers={drawnMarkers} paths={drawnPaths} />
      {onPick ? <PickEvents onPick={onPick} /> : null}
      {drawnPaths.map((path) => (
        <Polyline
          key={path.id}
          positions={path.points.flatMap((point) => {
            const lat = readCoordinate(point.lat)
            const lng = readCoordinate(point.lng)
            return lat == null || lng == null ? [] : [[lat, lng] as [number, number]]
          })}
          pathOptions={{ color: '#0B4DA2', weight: 4 }}
        />
      ))}
      {drawnMarkers.map((marker) => (
        <Marker
          key={marker.id}
          position={[readCoordinate(marker.lat)!, readCoordinate(marker.lng)!]}
          icon={markerIcons[marker.tone ?? 'place']}
          title={marker.label}
          eventHandlers={{
            click: () => onSelect?.(marker.id),
          }}
        />
      ))}
    </MapContainer>
  )
}

function InvalidateSize() {
  const map = useMap()
  useEffect(() => {
    const container = map.getContainer()
    const update = () => {
      map.invalidateSize()
    }
    update()
    const observer = new ResizeObserver(update)
    observer.observe(container)
    if (container.parentElement) observer.observe(container.parentElement)
    return () => observer.disconnect()
  }, [map])
  return null
}

function FitMarkers({ markers, paths }: { markers: MapMarker[]; paths: MapPath[] }) {
  const map = useMap()
  const points = collectPoints(markers, paths)
  const key = points.map((point) => `${point[0]}:${point[1]}`).join('|')
  const pointsRef = useRef(points)

  useEffect(() => {
    pointsRef.current = points
  })

  useEffect(() => {
    const current = pointsRef.current
    if (current.length === 0) return
    if (current.length === 1) {
      const only = current[0]
      if (!only) return
      map.setView(only, 14)
      return
    }
    map.fitBounds(L.latLngBounds(current), { padding: [24, 24] })
  }, [key, map])

  return null
}

function collectPoints(markers: MapMarker[], paths: MapPath[]): Array<[number, number]> {
  const points: Array<[number, number]> = []
  for (const marker of markers) {
    const pair = pairOf(marker.lat, marker.lng)
    if (pair) points.push(pair)
  }
  for (const path of paths) {
    for (const point of path.points) {
      const pair = pairOf(point.lat, point.lng)
      if (pair) points.push(pair)
    }
  }
  return points
}

function pairOf(lat: unknown, lng: unknown): [number, number] | null {
  const parsedLat = readCoordinate(lat)
  const parsedLng = readCoordinate(lng)
  if (parsedLat == null || parsedLng == null) return null
  return [parsedLat, parsedLng]
}

function PickEvents({ onPick }: { onPick: (lat: number, lng: number) => void }) {
  useMapEvents({
    click(event) {
      onPick(event.latlng.lat, event.latlng.lng)
    },
  })
  return null
}
