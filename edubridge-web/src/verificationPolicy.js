export const VERIFICATION_PATHS = new Set(['/verify', '/profile', '/support'])

export const IDENTITY_VERIFICATION_EXEMPT_ROLES = new Set(['admin', 'parent', 'ministry', 'institution'])

export function isIdentityVerificationExempt(user) {
  return IDENTITY_VERIFICATION_EXEMPT_ROLES.has(user?.role)
}

export function isIdentityVerified(user, verification) {
  return user?.role === 'admin' || verification?.verification_status === 'verified'
}

export function canAccessPortal(user, verification) {
  return isIdentityVerificationExempt(user) || isIdentityVerified(user, verification)
}

export function canOpenUnverifiedPath(pathname) {
  return VERIFICATION_PATHS.has(pathname)
}
