import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { createListPageLoader } from '../utils/listPages'

// Fetch one server-filtered page; obsolete searches never replace newer results.
export function useListPage(fetchPage, key, filters = {}) {
  const filterKey = JSON.stringify(filters)
  const [state, setState] = useState({ items: [], loading: true, error: null, meta: null, summary: null })
  const [page, setPage] = useState(1)
  const [refresh, setRefresh] = useState(0)
  const loader = useMemo(() => createListPageLoader(fetchPage, key,
    data => setState({ items: data[key], loading: false, error: null, meta: data.pagination, summary: data.summary ?? null }),
    error => setState(prev => ({ ...prev, loading: false, error: error.message })),
  ), [fetchPage, key])
  const appliedFilters = useRef(filterKey)
  useEffect(() => {
    loader.cancel()
    const targetPage = appliedFilters.current === filterKey ? page : 1
    appliedFilters.current = filterKey
    if (targetPage !== page) setPage(targetPage)
    setState(prev => ({ ...prev, loading: true, error: null }))
    const timer = setTimeout(() => loader.load({ ...JSON.parse(filterKey), page: targetPage, per_page: 30 }), 250)
    return () => { clearTimeout(timer); loader.cancel() }
  }, [loader, filterKey, page, refresh])
  const reload = useCallback(() => setRefresh(value => value + 1), [])
  return { ...state, setPage, reload }
}
