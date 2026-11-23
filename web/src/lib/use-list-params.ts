import { useCallback } from 'react'
import { useSearchParams } from 'react-router-dom'

export function useListParams() {
  const [params, setParams] = useSearchParams()

  const set = useCallback(
    (updates: Record<string, string | null>, resetPage = true) => {
      const next = new URLSearchParams(params)
      for (const [key, value] of Object.entries(updates)) {
        if (value === null || value === '') next.delete(key)
        else next.set(key, value)
      }
      if (resetPage) next.delete('page')
      setParams(next, { replace: true })
    },
    [params, setParams],
  )

  const pageValue = Number(params.get('page') ?? '1')
  const page = Number.isInteger(pageValue) && pageValue > 0 ? pageValue : 1

  const setPage = useCallback(
    (nextPage: number) => {
      set({ page: nextPage <= 1 ? null : String(nextPage) }, false)
    },
    [set],
  )

  return { params, set, page, setPage }
}
