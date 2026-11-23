import { spawn } from 'node:child_process'
import { readFileSync } from 'node:fs'
import path from 'node:path'
import { createInterface } from 'node:readline/promises'
import { stdin, stdout } from 'node:process'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const envFile = path.join(root, 'backend', '.env')
const requiredSeedKeys = [
  'SEED_ADMIN_EMAIL',
  'SEED_ADMIN_PASSWORD',
  'SEED_COMPANY_ADMIN_EMAIL',
  'SEED_COMPANY_ADMIN_PASSWORD',
  'SEED_DRIVERS_ADMIN_EMAIL',
  'SEED_DRIVERS_ADMIN_PASSWORD',
]

const env = readEnv(envFile)
const missing = requiredSeedKeys.filter((key) => !env.get(key))
if (missing.length > 0) {
  console.error(`backend/.env is missing ${missing.join(', ')}.`)
  console.error('DatabaseSeeder requires them before migrate:fresh --seed. Nothing was changed.')
  process.exit(1)
}
if (!env.get('APP_KEY')) {
  console.error('backend/.env has no APP_KEY. From the backend directory run: php artisan key:generate')
  console.error('Nothing was changed.')
  process.exit(1)
}

const appEnv = env.get('APP_ENV') ?? ''
if (appEnv !== 'local' && appEnv !== 'testing') {
  console.error(
    `Refused: db:reset runs only when APP_ENV is local or testing (found ${appEnv || 'empty'}). Nothing was changed.`,
  )
  process.exit(1)
}

if (!stdin.isTTY) {
  console.error('db:reset must be run in a terminal so you can type RESET.')
  process.exit(1)
}

const prompt = createInterface({ input: stdin, output: stdout })
const answer = (
  await prompt.question(
    'This deletes all rows, re-runs migrations, and runs the database seeders. Type RESET to continue: ',
  )
).trim()
prompt.close()

if (answer !== 'RESET') {
  console.error('Aborted. The database was not changed.')
  process.exit(1)
}

const child = spawn('php artisan migrate:fresh --seed', {
  cwd: path.join(root, 'backend'),
  stdio: 'inherit',
  shell: true,
})

child.on('error', (error) => {
  console.error(error.message)
  process.exit(1)
})
child.on('exit', (code, signal) => {
  if (signal) process.exit(1)
  process.exit(code ?? 1)
})

function readEnv(file) {
  let text
  try {
    text = readFileSync(file, 'utf8').replace(/^\uFEFF/, '')
  } catch {
    console.error('backend/.env is missing. Copy backend/.env.example to backend/.env. Nothing was changed.')
    process.exit(1)
  }

  const values = new Map()
  for (const line of text.split(/\r?\n/)) {
    const trimmed = line.trim()
    if (trimmed === '' || trimmed.startsWith('#')) continue
    const separator = trimmed.indexOf('=')
    if (separator < 1) continue
    const key = trimmed.slice(0, separator).trim()
    let value = trimmed.slice(separator + 1).trim()
    if (
      (value.startsWith('"') && value.endsWith('"') && value.length >= 2) ||
      (value.startsWith("'") && value.endsWith("'") && value.length >= 2)
    ) {
      value = value.slice(1, -1)
    }
    values.set(key, value)
  }
  return values
}
