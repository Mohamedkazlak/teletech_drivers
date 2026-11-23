import type { Branch } from '../api/types'

const BRANCHES: readonly Branch[] = ['company_headquarters', 'new_headquarters']

export function isBranch(value: string | null | undefined): value is Branch {
  return BRANCHES.some((branch) => branch === value)
}

export function localizedName(
  language: string,
  nameEn: string | null | undefined,
  nameAr: string | null | undefined,
): string {
  const english = nameEn?.trim() ?? ''
  const arabic = nameAr?.trim() ?? ''
  if (language.startsWith('ar') && arabic !== '') return arabic
  return english || arabic
}
