type NavigateFn = (path: string) => void

function assignPath(path: string): void {
  if (window.location.pathname === path) return
  window.location.assign(path)
}

let navigateImpl: NavigateFn = assignPath

export function setNavigator(next: NavigateFn | null): void {
  navigateImpl = next
    ? (path) => {
        if (window.location.pathname === path) return
        next(path)
      }
    : assignPath
}

export function redirectTo(path: string): void {
  navigateImpl(path)
}
