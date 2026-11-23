import { LIVE_POLL_MS } from './live-poll'
import { useDocumentVisible } from './use-document-visible'

/** Poll interval while the tab is in the foreground, or false when it is hidden. */
export function useForegroundPoll(): number | false {
  const visible = useDocumentVisible()
  return visible ? LIVE_POLL_MS : false
}
