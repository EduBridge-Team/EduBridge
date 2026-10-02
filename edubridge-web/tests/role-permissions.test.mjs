import assert from 'node:assert/strict'
import { test } from 'node:test'
import { isPortalPathForRole } from '../src/portalRoutes.js'

const roles = ['parent', 'teacher', 'specialist', 'admin', 'institution', 'ministry']
const allowed = {
  '/admin': ['admin'], '/admin/verifications': ['admin'], '/ministry': ['ministry'], '/institution': ['institution'],
  '/children': ['parent', 'teacher', 'specialist', 'admin'], '/children/new': ['parent'],
  '/accessibility': ['specialist'], '/children/10/accessibility': ['specialist'],
  '/homeworks': ['parent', 'teacher', 'specialist', 'admin'], '/weekly-reports': ['parent', 'teacher', 'specialist', 'admin'],
  '/care-team': ['parent', 'teacher', 'specialist', 'admin'], '/parent-lessons': ['parent', 'teacher', 'specialist', 'admin'],
  '/case-discussions': ['teacher', 'specialist', 'admin'], '/specialist-workflow': ['specialist', 'admin'],
  '/learning-support': ['parent', 'specialist', 'admin'], '/search': ['teacher', 'specialist', 'admin', 'institution', 'ministry'],
  '/lessons': roles, '/conversations': roles, '/notifications': roles, '/verify': roles, '/profile': roles, '/support': roles,
}

test('portal role permissions match the API roles shared with mobile', () => {
  for (const [path, pageRoles] of Object.entries(allowed)) {
    for (const role of roles) assert.equal(isPortalPathForRole(path, role), pageRoles.includes(role), `${path}: ${role}`)
  }
  assert.equal(isPortalPathForRole('/lessons', 'unknown'), false)
})
