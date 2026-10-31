import { useEffect, useState } from 'react'
import { request } from '../../api/core'

export function useSchoolResource(path) {
  const [revision, setRevision] = useState(0)
  const [state, setState] = useState({ data: null, loading: true, error: '' })
  useEffect(() => {
    if (!path) { setState({ data: null, loading: false, error: '' }); return }
    let current = true
    setState({ data: null, loading: true, error: '' })
    request(path).then(data => { if (current) setState({ data, loading: false, error: '' }) })
      .catch(error => { if (current) setState({ data: null, loading: false, error: error.message }) })
    return () => { current = false }
  }, [path, revision])
  return { ...state, reload: () => setRevision(value => value + 1) }
}
