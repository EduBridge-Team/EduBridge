// Separate the outcome of a confirmed write from an optional read-after-write.
// A failed refresh must never be reported as a failed quota save.
export async function saveQuotaWithRefresh(write, read) {
  await write()
  try {
    const response = await read()
    if (!response || !Array.isArray(response.quotas)) throw new Error('Invalid quota response')
    return { saved: true, refreshed: true, quotas: response.quotas }
  } catch {
    return { saved: true, refreshed: false, quotas: null }
  }
}
