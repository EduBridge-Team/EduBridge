import { useEffect, useState } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import { getUser, logout } from '../../api'
import { dashboardFor } from '../../roleRoutes'
import { isPortalPathForRole } from '../../portalRoutes'
import { useTheme } from '../../theme'
import BrandLogo from '../BrandLogo/BrandLogo'
import { GuestTopBarMenu, SignedInTopBarMenu } from './TopBarMenus'
import { buildTopBarStripLinks } from './topBarLinks'

export default function TopBar() {
  const navigate = useNavigate()
  const location = useLocation()
  const user = getUser()
  const [open, setOpen] = useState(false)
  const { dark, toggleTheme } = useTheme()

  useEffect(() => setOpen(false), [location.pathname])

  useEffect(() => {
    document.body.style.overflow = open ? 'hidden' : ''
    return () => { document.body.style.overflow = '' }
  }, [open])

  const handleLogout = () => {
    logout()
    setOpen(false)
    navigate('/login')
  }

  const dashboardPath = dashboardFor(user)
  const isRolePortal = Boolean(user?.role)
    && isPortalPathForRole(location.pathname, user.role)
  const userInitial = String(user?.name || '؟').trim().charAt(0) || '؟'
  const profileImage = user?.avatar_url || user?.avatar || user?.photo_url || user?.profile_photo_url || ''

  const stripLinks = buildTopBarStripLinks(user)

  return (
    <header className={'topbar ' + (user ? 'topbar-' + user.role : 'topbar-guest') + (isRolePortal ? ' role-portal-global-topbar' : '')}>
      <div className="topbar-brand" onClick={() => navigate('/')}>
        <BrandLogo className="topbar-brand-logo" />
      </div>

      <button className={'hamburger ' + (open ? 'is-open' : '')} aria-label="فتح القائمة" aria-expanded={open} onClick={() => setOpen((v) => !v)}>
        <span /><span /><span />
      </button>

      {user && (
        <button
          className="mobile-profile-button"
          type="button"
          aria-label="فتح الملف الشخصي"
          title="الملف الشخصي"
          onClick={() => {
            setOpen(false)
            navigate('/profile')
          }}
        >
          {profileImage ? (
            <img src={profileImage} alt="" />
          ) : (
            <span aria-hidden="true">{userInitial}</span>
          )}
        </button>
      )}

      {open && <div className="topbar-backdrop" onClick={() => setOpen(false)} />}

      <div className={'topbar-menu ' + (open ? 'open' : '')}>
        {user ? (
          <SignedInTopBarMenu
            dashboardPath={dashboardPath}
            dark={dark}
            onLogout={handleLogout}
            stripLinks={stripLinks}
            toggleTheme={toggleTheme}
            user={user}
          />
        ) : (
          <GuestTopBarMenu
            dark={dark}
            onLogin={() => {
              setOpen(false)
              navigate('/login')
            }}
            onRegister={() => navigate('/register')}
            toggleTheme={toggleTheme}
          />
        )}
      </div>
    </header>
  )
}
