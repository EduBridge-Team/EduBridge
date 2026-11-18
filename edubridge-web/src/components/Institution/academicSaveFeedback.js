// A successful academic write is authoritative even if reloading the summary fails.
// Do not invite duplicate create requests when only readback is unavailable.
export async function saveAcademicAndRefresh(write, refresh) {
  await write()
  try {
    await refresh()
    return { saved: true, refreshed: true }
  } catch {
    return { saved: true, refreshed: false }
  }
}
