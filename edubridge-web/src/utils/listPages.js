export function listPage(data, key) {
  const meta = data.pagination
  if (!Array.isArray(data[key]) || !meta || !Number.isInteger(meta.page) ||
      !Number.isInteger(meta.total) || !Number.isInteger(meta.last_page) ||
      typeof meta.has_more !== 'boolean') throw new Error('تعذّر تحميل القائمة، حاول مجدداً')
  return data
}

export function createListPageLoader(fetchPage, key, onData, onError) {
  let revision = 0
  return {
    cancel() { ++revision },
    async load(params) {
      const request = ++revision
      try {
        const data = listPage(await fetchPage(params), key)
        if (request === revision) onData(data)
      } catch (error) {
        if (request === revision) onError(error)
      }
    },
  }
}
