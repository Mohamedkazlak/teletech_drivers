const ARABIC_ARTICLE = 'ال'

function firstLetter(word: string): string {
  const letters = Array.from(word)
  const hasArticle = word.startsWith(ARABIC_ARTICLE) && letters.length > ARABIC_ARTICLE.length
  return (hasArticle ? letters[ARABIC_ARTICLE.length] : letters[0]) ?? ''
}

/** Avatar initials: first letter of the first and last word, skipping the Arabic "ال". */
export function initials(name: string): string {
  const parts = name.trim().split(/\s+/).filter(Boolean)
  if (parts.length === 0) return '?'
  const first = firstLetter(parts[0])
  const last = parts.length > 1 ? firstLetter(parts[parts.length - 1]) : ''
  return (first + last).toUpperCase()
}
