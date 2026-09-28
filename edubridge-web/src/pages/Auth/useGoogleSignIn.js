import { useEffect, useState } from 'react'
import { googleLogin } from '../../api'
import { dashboardFor } from '../../roleRoutes'

export function useGoogleSignIn({ navigate, setError, setLoading }) {
  const [googleReady, setGoogleReady] = useState(false)

  useEffect(() => {
    const googleClientId = import.meta.env.VITE_GOOGLE_CLIENT_ID
    if (!googleClientId) return undefined

    let cancelled = false
    let pollId

    const setupGoogle = () => {
      if (cancelled || !window.google?.accounts?.id) return false

      window.google.accounts.id.initialize({
        client_id: googleClientId,
        callback: async (response) => {
          setError(null)
          setLoading(true)
          try {
            const user = await googleLogin(response.credential)
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
        window.google.accounts.id.renderButton(container, {
          theme: 'outline',
          size: 'large',
          text: 'signin_with',
          shape: 'rectangular',
          width: 320,
          locale: 'ar',
        })
        setGoogleReady(true)
      }
      return true
    }

    if (!setupGoogle()) {
      pollId = setInterval(() => {
        if (setupGoogle()) clearInterval(pollId)
      }, 200)
    }

    return () => {
      cancelled = true
      if (pollId) clearInterval(pollId)
    }
  }, [navigate, setError, setLoading])

  return googleReady
}
