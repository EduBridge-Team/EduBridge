export const VERIFICATION_PATHS = new Set(['/verify', '/profile', '/support'])

export function isIdentityVerified(user, verification) {
  return user?.role === 'admin' || verification?.verification_status === 'verified'
}

export function canOpenUnverifiedPath(pathname) {
  return VERIFICATION_PATHS.has(pathname)
}
