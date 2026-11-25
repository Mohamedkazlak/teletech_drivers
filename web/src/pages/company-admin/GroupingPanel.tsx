import { type ReactNode, useState } from 'react'
import { useTranslation } from 'react-i18next'
import type { GroupSuggestion, GroupSuggestionMember } from '../../api/types'
import { useApproveGroup } from '../../api/use-trip-requests'
import { BranchText } from '../../components/ui/BranchText'
import { ConfirmDialog } from '../../components/ui/ConfirmDialog'
import { useToast } from '../../components/ui/toast-context'
import { primaryButtonClass, secondaryButtonClass } from '../../components/ui/styles'
import { messageForApiError } from '../../lib/api-message'
import { formatWhen } from '../../lib/format'
import { localizedName } from '../../lib/names'

type GroupingPanelProps = {
  suggestions: GroupSuggestion[]
  /** Replaces the company-admin approve actions. Members still come from the suggestion. */
  actions?: (suggestion: GroupSuggestion, selectedIds: string[]) => ReactNode
  hint?: string
}

export function GroupingPanel({ suggestions, actions, hint }: GroupingPanelProps) {
  const { t, i18n } = useTranslation()
  const toast = useToast()
  const approveGroup = useApproveGroup()
  const [dismissed, setDismissed] = useState<string[]>([])
  const [checked, setChecked] = useState<Record<string, string[]>>({})
  const [pendingIds, setPendingIds] = useState<string[] | null>(null)
  const [pendingCluster, setPendingCluster] = useState<string | null>(null)

  const visible = suggestions.filter(
    (suggestion) =>
      suggestion.request_ids.length >= 2 && !dismissed.includes(suggestion.cluster_id),
  )

  if (visible.length === 0) return null

  function selection(suggestion: GroupSuggestion): string[] {
    return checked[suggestion.cluster_id] ?? suggestion.request_ids
  }

  function toggle(suggestion: GroupSuggestion, requestId: string) {
    const current = selection(suggestion)
    const next = current.includes(requestId)
      ? current.filter((id) => id !== requestId)
      : [...current, requestId]
    setChecked((previous) => ({ ...previous, [suggestion.cluster_id]: next }))
  }

  async function confirmApprove() {
    if (!pendingIds || pendingIds.length < 2 || !pendingCluster) return
    try {
      await approveGroup.mutateAsync(pendingIds)
      setDismissed((current) => [...current, pendingCluster])
      toast(t('requests.groupApproved'), 'success')
      setPendingIds(null)
      setPendingCluster(null)
    } catch (error) {
      toast(messageForApiError(error, t), 'error')
    }
  }

  return (
    <section
      className="rounded-card border border-line bg-white p-4"
      aria-label={t('requests.groups')}
    >
      <h2 className="text-base font-semibold text-navy">{t('requests.groups')}</h2>
      <p className="mt-1 text-sm text-ink-muted">{hint ?? t('requests.groupsHint')}</p>
      <div className="mt-4 flex flex-col gap-3">
        {visible.map((suggestion) => {
          const selected = selection(suggestion)
          return (
            <article
              key={suggestion.cluster_id}
              aria-labelledby={`group-${suggestion.cluster_id}`}
              className="rounded-control border border-line p-3"
            >
              <h3 id={`group-${suggestion.cluster_id}`} className="font-medium text-navy">
                {suggestion.route_label}
              </h3>
              <p className="mt-1 text-sm text-ink-muted">
                {suggestion.destination_label}
                {' · '}
                {formatWhen(suggestion.earliest_requested_at, i18n.language)}
                {' – '}
                {formatWhen(suggestion.latest_requested_at, i18n.language)}
              </p>
              <p className="mt-1 text-sm text-ink-muted">
                {t('requests.requestCount', { count: suggestion.request_ids.length })}
              </p>
              <ul className="mt-3 flex flex-col gap-2">
                {suggestion.members.map((member) => (
                  <li key={member.request_id}>
                    <label className="inline-flex items-center gap-2 text-sm text-navy">
                      <input
                        type="checkbox"
                        checked={selected.includes(member.request_id)}
                        onChange={() => toggle(suggestion, member.request_id)}
                      />
                      {memberName(member, i18n.language)}
                    </label>
                    <p className="ms-6 text-sm text-ink-muted">
                      <BranchText value={member.branch} />
                      {' · '}
                      {t('requests.routeValue', {
                        from: member.from_place,
                        to: member.to_place,
                      })}
                      {' · '}
                      {formatWhen(member.requested_at, i18n.language)}
                    </p>
                  </li>
                ))}
              </ul>
              <div className="mt-3 flex flex-wrap gap-2">
                {actions ? (
                  actions(suggestion, selected)
                ) : (
                  <>
                    <button
                      type="button"
                      className={primaryButtonClass}
                      onClick={() => {
                        setPendingIds(suggestion.request_ids)
                        setPendingCluster(suggestion.cluster_id)
                      }}
                    >
                      {t('requests.approveGroup')}
                    </button>
                    <button
                      type="button"
                      className={secondaryButtonClass}
                      disabled={selected.length < 2}
                      onClick={() => {
                        setPendingIds(selected)
                        setPendingCluster(suggestion.cluster_id)
                      }}
                    >
                      {t('requests.approveSelected')}
                    </button>
                  </>
                )}
                <button
                  type="button"
                  className={secondaryButtonClass}
                  onClick={() => setDismissed((current) => [...current, suggestion.cluster_id])}
                >
                  {t('requests.dismiss')}
                </button>
              </div>
            </article>
          )
        })}
      </div>
      {actions ? null : (
        <ConfirmDialog
          open={pendingIds !== null}
          title={t('requests.approveGroupTitle')}
          description={t('requests.approveGroupMessage', { count: pendingIds?.length ?? 0 })}
          confirmLabel={t('requests.approveGroup')}
          cancelLabel={t('common.cancel')}
          busy={approveGroup.isPending}
          onCancel={() => {
            setPendingIds(null)
            setPendingCluster(null)
          }}
          onConfirm={() => {
            void confirmApprove()
          }}
        />
      )}
    </section>
  )
}

function memberName(member: GroupSuggestionMember, language: string): string {
  return (
    localizedName(language, member.requester_name_en, member.requester_name_ar) || member.request_id
  )
}
