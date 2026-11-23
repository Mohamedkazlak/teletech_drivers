import { readFileSync } from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

export class DeviceSelectionError extends Error {
  /**
   * @param {string} message
   * @param {number} [exitCode]
   */
  constructor(message, exitCode = 1) {
    super(message)
    this.name = 'DeviceSelectionError'
    this.exitCode = exitCode
  }
}

/**
 * @param {unknown} device
 */
export function isWebDevice(device) {
  const record = asRecord(device)
  const platform = String(record.targetPlatform ?? '').toLowerCase()
  const id = String(record.id ?? '').toLowerCase()
  if (platform.startsWith('web')) return true
  return id === 'chrome' || id === 'edge' || id === 'web-server'
}

/**
 * @param {unknown} device
 */
export function isAndroidEmulator(device) {
  const record = asRecord(device)
  const platform = String(record.targetPlatform ?? '').toLowerCase()
  const id = String(record.id ?? '')
  const flag = record.emulator
  const emulator = flag === true || flag === 'true' || flag === 1
  return platform.startsWith('android') && (emulator || id.startsWith('emulator-'))
}

/**
 * @param {string} raw
 * @returns {Array<Record<string, unknown>>}
 */
export function parseFlutterDevices(raw) {
  const text = String(raw ?? '')
  const arrayAt = text.indexOf('[')
  const objectAt = text.indexOf('{')
  let slice = ''
  if (arrayAt !== -1 && (objectAt === -1 || arrayAt < objectAt)) {
    const end = text.lastIndexOf(']')
    if (end > arrayAt) slice = text.slice(arrayAt, end + 1)
  } else if (objectAt !== -1) {
    const end = text.lastIndexOf('}')
    if (end > objectAt) slice = text.slice(objectAt, end + 1)
  }
  if (slice === '') throw parseError()

  try {
    const parsed = JSON.parse(slice)
    if (Array.isArray(parsed)) return parsed.map(asRecord)
    if (parsed && typeof parsed === 'object') return [asRecord(parsed)]
  } catch {
    throw parseError()
  }
  throw parseError()
}

/**
 * @param {Array<Record<string, unknown>>} devices
 * @param {{ deviceId?: string, lanIp?: string }} options
 */
export function selectTarget(devices, options) {
  const deviceId = (options.deviceId ?? '').trim()
  const lanIp = (options.lanIp ?? '').trim()

  if (deviceId !== '') {
    const match = devices.find((device) => String(device.id ?? '') === deviceId)
    const emulator = match ? isAndroidEmulator(match) : deviceId.startsWith('emulator-')
    return {
      id: deviceId,
      name: match ? String(match.name ?? deviceId) : deviceId,
      emulator,
      apiBaseUrl: apiBaseUrl(emulator, lanIp),
    }
  }

  const nonWeb = devices.filter((device) => !isWebDevice(device) && device.isSupported !== false)
  if (nonWeb.length === 0) {
    throw new DeviceSelectionError(
      [
        'No non-web Flutter device is connected.',
        'Start an Android emulator or plug in a phone, then run npm run dev:mobile again.',
        'List devices with: flutter devices',
      ].join('\n'),
    )
  }
  if (nonWeb.length > 1) {
    const lines = nonWeb.map((device) => {
      const id = String(device.id ?? '')
      const name = String(device.name ?? '')
      const platform = String(device.targetPlatform ?? '')
      return `  ${id.padEnd(24)} ${name.padEnd(24)} ${platform}`
    })
    throw new DeviceSelectionError(
      [
        'More than one non-web device is connected. Set DEVICE_ID and run again:',
        ...lines,
        'PowerShell:',
        `  $env:DEVICE_ID = '${String(nonWeb[0].id)}'`,
        '  npm run dev:mobile',
        'bash:',
        `  DEVICE_ID=${String(nonWeb[0].id)} npm run dev:mobile`,
      ].join('\n'),
    )
  }

  const only = nonWeb[0]
  const emulator = isAndroidEmulator(only)
  return {
    id: String(only.id ?? ''),
    name: String(only.name ?? only.id ?? ''),
    emulator,
    apiBaseUrl: apiBaseUrl(emulator, lanIp),
  }
}

/**
 * @param {string} raw
 * @param {{ deviceId?: string, lanIp?: string }} options
 */
export function selectFromFlutterOutput(raw, options) {
  return selectTarget(parseFlutterDevices(raw), options)
}

/**
 * @param {boolean} emulator
 * @param {string} lanIp
 */
function apiBaseUrl(emulator, lanIp) {
  if (emulator) return 'http://10.0.2.2:8000/api'
  if (lanIp === '') {
    throw new DeviceSelectionError(
      [
        'Could not detect a LAN IPv4 address (virtual and loopback adapters are ignored).',
        'Set LAN_IP and run again:',
        'PowerShell:',
        "  $env:LAN_IP = '192.168.1.20'",
        '  npm run dev:mobile',
        'bash:',
        '  LAN_IP=192.168.1.20 npm run dev:mobile',
      ].join('\n'),
    )
  }
  return `http://${lanIp}:8000/api`
}

function parseError() {
  return new DeviceSelectionError(
    'Could not parse `flutter devices --machine` output. Run `flutter devices` and set DEVICE_ID.',
  )
}

/**
 * @param {unknown} value
 * @returns {Record<string, unknown>}
 */
function asRecord(value) {
  if (value && typeof value === 'object') return /** @type {Record<string, unknown>} */ (value)
  return {}
}

function isDirectRun() {
  const entry = process.argv[1]
  if (!entry) return false
  return path.normalize(fileURLToPath(import.meta.url)) === path.normalize(path.resolve(entry))
}

if (isDirectRun()) {
  try {
    const inputPath = process.argv[2]
    const raw = inputPath ? readFileSync(inputPath, 'utf8') : readFileSync(0, 'utf8')
    const selected = selectFromFlutterOutput(raw, {
      deviceId: process.env.DEVICE_ID,
      lanIp: process.env.LAN_IP,
    })
    process.stdout.write(`${JSON.stringify(selected)}\n`)
  } catch (error) {
    if (error instanceof DeviceSelectionError) {
      process.stderr.write(error.message.endsWith('\n') ? error.message : `${error.message}\n`)
      process.exit(error.exitCode)
    }
    throw error
  }
}
