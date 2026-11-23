import { spawnSync } from 'node:child_process'
import { mkdtempSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import path from 'node:path'
import { test } from 'node:test'
import { fileURLToPath } from 'node:url'
import assert from 'node:assert/strict'
import { DeviceSelectionError, selectFromFlutterOutput, selectTarget } from './select-flutter-device.mjs'

const scriptPath = path.join(path.dirname(fileURLToPath(import.meta.url)), 'select-flutter-device.mjs')

const emulator = {
  id: 'emulator-5554',
  name: 'Pixel 6',
  targetPlatform: 'android-x64',
  emulator: true,
  isSupported: true,
}

const phone = {
  id: 'R58N123',
  name: 'Galaxy',
  targetPlatform: 'android-arm64',
  emulator: false,
  isSupported: true,
}

const chrome = {
  id: 'chrome',
  name: 'Chrome',
  targetPlatform: 'web-javascript',
  emulator: false,
  isSupported: true,
}

test('an Android emulator uses 10.0.2.2 and ignores a missing LAN address', () => {
  const selected = selectTarget([chrome, emulator], {})
  assert.equal(selected.id, 'emulator-5554')
  assert.equal(selected.emulator, true)
  assert.equal(selected.apiBaseUrl, 'http://10.0.2.2:8000/api')
})

test('a physical device uses the LAN address', () => {
  const selected = selectTarget([phone], { lanIp: ' 192.168.1.20 ' })
  assert.equal(selected.apiBaseUrl, 'http://192.168.1.20:8000/api')
  assert.equal(selected.emulator, false)
})

test('an emulator-* id is treated as an emulator even when the flag is missing', () => {
  const selected = selectTarget(
    [{ id: 'emulator-5556', name: 'AVD', targetPlatform: 'android-x64', isSupported: true }],
    {},
  )
  assert.equal(selected.apiBaseUrl, 'http://10.0.2.2:8000/api')
})

test('a physical device without a LAN address explains how to set LAN_IP', () => {
  assert.throws(
    () => selectTarget([phone], {}),
    (error) => {
      assert.ok(error instanceof DeviceSelectionError)
      assert.match(error.message, /LAN_IP/)
      assert.match(error.message, /\$env:LAN_IP/)
      return true
    },
  )
})

test('several non-web devices are listed and DEVICE_ID selects one', () => {
  assert.throws(
    () => selectTarget([emulator, phone, chrome], { lanIp: '10.0.0.4' }),
    (error) => {
      assert.ok(error instanceof DeviceSelectionError)
      assert.match(error.message, /emulator-5554/)
      assert.match(error.message, /R58N123/)
      assert.match(error.message, /DEVICE_ID/)
      assert.doesNotMatch(error.message, /chrome/)
      return true
    },
  )

  const selected = selectTarget([emulator, phone], { deviceId: 'R58N123', lanIp: '10.0.0.4' })
  assert.equal(selected.id, 'R58N123')
  assert.equal(selected.apiBaseUrl, 'http://10.0.0.4:8000/api')
})

test('DEVICE_ID is used even when that device is not in the list', () => {
  const selected = selectTarget([phone], { deviceId: 'emulator-5554', lanIp: '10.0.0.4' })
  assert.equal(selected.apiBaseUrl, 'http://10.0.2.2:8000/api')
})

test('unsupported and web-only lists do not auto-select', () => {
  assert.throws(
    () => selectTarget([{ ...phone, isSupported: false }, chrome], { lanIp: '10.0.0.8' }),
    (error) => error instanceof DeviceSelectionError && /No non-web/.test(error.message),
  )
})

test('machine output may include log lines around the JSON array', () => {
  const raw = `Waiting for another flutter command...\n${JSON.stringify([emulator])}\n`
  const selected = selectFromFlutterOutput(raw, {})
  assert.equal(selected.id, 'emulator-5554')
})

test('the CLI prints JSON and a non-zero status when several devices exist', () => {
  const dir = mkdtempSync(path.join(tmpdir(), 'flutter-devices-'))
  const file = path.join(dir, 'devices.json')
  writeFileSync(file, JSON.stringify([emulator, phone]))
  const many = spawnSync(process.execPath, [scriptPath, file], {
    encoding: 'utf8',
    env: { ...process.env, DEVICE_ID: '', LAN_IP: '192.168.1.9' },
  })
  assert.equal(many.status, 1)
  assert.match(many.stderr, /Set DEVICE_ID/)

  const one = spawnSync(process.execPath, [scriptPath, file], {
    encoding: 'utf8',
    env: { ...process.env, DEVICE_ID: 'emulator-5554', LAN_IP: '' },
  })
  assert.equal(one.status, 0)
  assert.deepEqual(JSON.parse(one.stdout), {
    id: 'emulator-5554',
    name: 'Pixel 6',
    emulator: true,
    apiBaseUrl: 'http://10.0.2.2:8000/api',
  })
})
