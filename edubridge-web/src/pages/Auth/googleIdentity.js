let pending

export function loadGoogleIdentity() {
  if (window.google?.accounts?.id) return Promise.resolve()
  if (pending) return pending

  pending = new Promise((resolve, reject) => {
    const script = document.createElement('script')
    script.src = 'https://accounts.google.com/gsi/client'
    script.async = true
    const timeout = setTimeout(() => finish(new Error('Google sign-in timed out')), 15000)
    function finish(error) {
      clearTimeout(timeout)
      script.onload = script.onerror = null
      if (error) {
        script.remove()
        pending = undefined
        reject(error)
      } else {
        resolve()
      }
    }
    script.onload = () => finish(window.google?.accounts?.id ? null : new Error('Google sign-in unavailable'))
    script.onerror = () => finish(new Error('Google sign-in failed to load'))
    document.head.appendChild(script)
  })
  return pending
}
