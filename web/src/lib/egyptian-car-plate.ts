/** Egyptian private-vehicle plate: 1–3 traffic letters and 1–4 digits. */

const allowedLetters = 'أبجدرسصطعفقلمنهوي'
const alefVariants = new Set(['إ', 'آ', 'ا', 'ٱ'])
const digits: Record<string, string> = {
  '٠': '0',
  '١': '1',
  '٢': '2',
  '٣': '3',
  '٤': '4',
  '٥': '5',
  '٦': '6',
  '٧': '7',
  '٨': '8',
  '٩': '9',
  '۰': '0',
  '۱': '1',
  '۲': '2',
  '۳': '3',
  '۴': '4',
  '۵': '5',
  '۶': '6',
  '۷': '7',
  '۸': '8',
  '۹': '9',
}

const platePattern = new RegExp(`^[${allowedLetters}]{1,3}\\d{1,4}$`)

export function plateLettersInput(raw: string): string {
  return collectLetters(raw).join(' ')
}

export function plateNumbersInput(raw: string): string {
  let numbers = ''
  for (const char of raw) {
    const mapped = digits[char] ?? char
    if (/^\d$/.test(mapped)) {
      numbers += mapped
      if (numbers.length === 4) break
    }
  }
  return numbers
}

/** Canonical "ط ع ب 9295", or null when either part is empty. */
export function canonicalPlate(letters: string, numbers: string): string | null {
  const letterList = collectLetters(letters)
  const number = plateNumbersInput(numbers)
  if (letterList.length === 0 || number.length === 0) return null
  return `${letterList.join(' ')} ${number}`
}

export function parsePlate(raw: string): { letters: string; numbers: string } | null {
  const compact = compactPlate(raw)
  const match = platePattern.exec(compact)
  if (!match) return null
  const letters = [...match[0].replace(/\d/g, '')].join(' ')
  const numbers = match[0].replace(/\D/g, '')
  return { letters, numbers }
}

function collectLetters(raw: string): string[] {
  const letters: string[] = []
  for (const char of raw) {
    if (char === '\u0640') continue
    const normalized = alefVariants.has(char) ? 'أ' : char
    if (!allowedLetters.includes(normalized)) continue
    letters.push(normalized)
    if (letters.length === 3) break
  }
  return letters
}

function compactPlate(raw: string): string {
  let compact = ''
  for (const char of raw) {
    if (char.trim() === '' || char === '\u0640') continue
    if (alefVariants.has(char)) {
      compact += 'أ'
      continue
    }
    compact += digits[char] ?? char
  }
  return compact
}
