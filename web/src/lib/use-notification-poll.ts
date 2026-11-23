import { useDocumentVisible } from './use-document-visible'

export const NOTIFICATION_POLL_MS = 15_000

/** Poll interval while the tab is visible. Hidden tabs do not poll. */
export function useNotificationPoll(): number | false {
  const visible = useDocumentVisible()
  return visible ? NOTIFICATION_POLL_MS : false
}
