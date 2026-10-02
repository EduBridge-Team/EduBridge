export function createMessageLoader(fetchMessages, onMessages, onError) {
  let activeId = null
  let sequence = 0
  return {
    activate(id) { activeId = id; ++sequence; onMessages([]) },
    cancel() { activeId = null; ++sequence },
    isActive(id) { return id === activeId },
    async load(id) {
      if (id !== activeId) return
      const request = ++sequence
      try {
        const data = await fetchMessages(id)
        if (id === activeId && request === sequence) onMessages(data.messages || [])
      } catch (error) {
        if (id === activeId && request === sequence) onError(error.message)
      }
    },
  }
}
