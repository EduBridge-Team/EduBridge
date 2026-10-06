import { useEffect, useState } from 'react'
import { googleLogin } from '../../api'
import { dashboardFor } from '../../roleRoutes'
import { loadGoogleIdentity } from './googleIdentity.js'

export function useGoogleSignIn({ navigate, setError, setLoading, googleRole }) {
  const [googleReady, setGoogleReady] = useState(false)

  useEffect(() => {
    const googleClientId = import.meta.env.VITE_GOOGLE_CLIENT_ID
    if (!googleClientId) return undefined

    let cancelled = false
    let revealTimer

    const setupGoogle = () => {
      if (cancelled || !window.google?.accounts?.id) return false

      setGoogleReady(false)
      window.google.accounts.id.initialize({
        client_id: googleClientId,
        callback: async (response) => {
          setError(null)
          setLoading(true)
          try {
            const user = await googleLogin(response.credential, googleRole)
            navigate(dashboardFor(user))
          } catch (err) {
            setError(err.message)
          } finally {
            setLoading(false)
          }
        },
      })

      const container = document.getElementById('google-signin-button')
      if (container) {
        container.replaceChildren()
        window.google.accounts.id.renderButton(container, {
          theme: 'outline',
          size: 'large',
          text: 'signin_with',
          shape: 'rectangular',
          width: 320,
          locale: 'ar',
        })

        // Google briefly paints an oversized intermediate state on some mobile
        // browsers while its iframe/styles settle. Keep it clipped and hidden
        // until the provider has had a moment to finish layout.
        revealTimer = window.setTimeout(() => {
          if (!cancelled) setGoogleReady(true)
        }, 180)
      }
      return true
    }

    loadGoogleIdentity().then(setupGoogle).catch(() => {
      // Password login remains available when the external provider fails.
      if (!cancelled) setGoogleReady(false)
    })

    return () => {
      cancelled = true
      if (revealTimer) window.clearTimeout(revealTimer)
    }
  }, [navigate, setError, setLoading, googleRole])

  return googleReady
}
