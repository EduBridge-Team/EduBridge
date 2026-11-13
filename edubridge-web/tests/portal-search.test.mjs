import assert from 'node:assert/strict'
import { test } from 'node:test'
import { portalSearchFor } from '../src/layouts/portalSearch.js'
import { DASHBOARD_BY_ROLE } from '../src/roleRoutes.js'
import { isPortalPathForRole } from '../src/portalRoutes.js'

test('toolbar search always opens a route permitted for the current role', () => {
  for (const role of Object.keys(DASHBOARD_BY_ROLE)) {
    const search = portalSearchFor(role)
    assert.equal(isPortalPathForRole(search.path, role), true, role)
  }
})

test('student and school accounts search lessons instead of being redirected from staff search', () => {
  for (const role of ['parent', 'student', 'staff', 'school', 'school_director']) {
    assert.deepEqual(portalSearchFor(role), {
      path: '/lessons', placeholder: 'ابحث في الدروس والمحتوى...',
    })
  }
})

test('authorized staff keep identity search', () => {
  for (const role of ['teacher', 'specialist', 'admin', 'ministry', 'institution']) {
    assert.deepEqual(portalSearchFor(role), {
      path: '/search', placeholder: 'ابحث برقم الهوية أو افتح صفحة البحث...',
    })
  }
})
