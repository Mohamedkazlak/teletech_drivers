const TOKEN_KEY = 'teletech.token'

type Listener = () => void

const listeners = new Set<Listener>()

function emit(): void {
  for (const listener of listeners) listener()
}

export const sessionStore = {
  get(): string | null {
    return localStorage.getItem(TOKEN_KEY)
  },
  set(token: string): void {
    localStorage.setItem(TOKEN_KEY, token)
    emit()
  },
  clear(): void {
    localStorage.removeItem(TOKEN_KEY)
    emit()
  },
  subscribe(listener: Listener): () => void {
    listeners.add(listener)
    return () => {
      listeners.delete(listener)
    }
  },
}
