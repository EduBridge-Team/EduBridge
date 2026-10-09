import { lazy, Suspense } from 'react'
import RouteLoadBoundary from './components/RouteLoadBoundary'
import { Navigate, Route, Routes, useLocation } from 'react-router-dom'
import { getToken, getUser } from './api'
import { dashboardFor } from './roleRoutes'
import { CHILD_ROLES, CONSULTATION_ROLES, STAFF_SEARCH_ROLES, isPortalPathForRole } from './portalRoutes'
import RolePortalLayout from './layouts/RolePortalLayout'
import HomePage from './pages/Public/HomePage'
import { useVerification, VerificationRequired } from './verification'
import { canOpenUnverifiedPath } from './verificationPolicy'

import './styles/routes.css'

const LoginPage = lazy(() => import('./pages/Auth/LoginPage'))
const RegisterPage = lazy(() => import('./pages/Auth/RegisterPage'))
const ForgotPasswordPage = lazy(() => import('./pages/Auth/ForgotPasswordPage'))
const ResetPasswordPage = lazy(() => import('./pages/Auth/ResetPasswordPage'))
const ChildrenPage = lazy(() => import('./pages/Children/ChildrenPage'))
const ChildLessonsPage = lazy(() => import('./pages/Children/ChildLessonsPage'))
const ChildProgressPage = lazy(() => import('./pages/Children/ChildProgressPage'))
const LessonsPage = lazy(() => import('./pages/Learning/LessonsPage'))
const AboutPage = lazy(() => import('./pages/Public/AboutPage'))
const AdminPage = lazy(() => import('./pages/Dashboards/Admin/AdminPage'))
const TeacherDashboard = lazy(() => import('./pages/Dashboards/Teacher/TeacherDashboard'))
const SpecialistDashboard = lazy(() => import('./pages/Dashboards/SpecialistDashboard'))
const ParentDashboard = lazy(() => import('./pages/Dashboards/Parent/ParentDashboard'))
const ChildDetailsPage = lazy(() => import('./pages/Children/ChildDetailsPage'))
const ChildFormPage = lazy(() => import('./pages/Children/ChildFormPage'))
const NotificationsPage = lazy(() => import('./pages/Communication/NotificationsPage'))
const SearchPage = lazy(() => import('./pages/Account/SearchPage'))
const VerifyIdentityPage = lazy(() => import('./pages/Account/VerifyIdentityPage'))
const ProfilePage = lazy(() => import('./pages/Account/ProfilePage'))
const VerificationsPage = lazy(() => import('./pages/Account/VerificationsPage'))
const SupportPage = lazy(() => import('./pages/Support/SupportPage'))
const MinistryPage = lazy(() => import('./pages/Dashboards/MinistryPage'))
const ConsultationsPage = lazy(() => import('./pages/Support/ConsultationsPage'))
const EducationalGamesPage = lazy(() => import('./pages/Children/EducationalGamesPage'))
const AccessibilityPage = lazy(() => import('./pages/Children/AccessibilityPage'))
const AccessibilityOverviewPage = lazy(() => import('./pages/Children/AccessibilityOverviewPage'))
const ConversationsPage = lazy(() => import('./pages/Communication/ConversationsPage'))
const InstitutionDashboard = lazy(() => import('./pages/Dashboards/InstitutionDashboard'))
const InstitutionSchoolsPage = lazy(() => import('./pages/Dashboards/InstitutionSchoolsPage'))
const InstitutionTeachersPage = lazy(() => import('./pages/Dashboards/InstitutionTeachersPage'))
const InstitutionStudentsPage = lazy(() => import('./pages/Dashboards/InstitutionStudentsPage'))
const InstitutionAttendancePage = lazy(() => import('./pages/Dashboards/InstitutionAttendancePage'))
const InstitutionTimetablePage = lazy(() => import('./pages/Dashboards/InstitutionTimetablePage'))
const InstitutionSubstitutionsPage = lazy(() => import('./pages/Dashboards/InstitutionSubstitutionsPage'))
const InstitutionReportsPage = lazy(() => import('./pages/Dashboards/InstitutionReportsPage'))
const TeacherInvitationPage = lazy(() => import('./pages/Dashboards/TeacherInvitationPage'))
const HomeworkPage = lazy(() => import('./pages/Learning/HomeworkPage'))
const WeeklyReportsPage = lazy(() => import('./pages/Learning/WeeklyReportsPage'))
const LearningSupportPage = lazy(() => import('./pages/Support/LearningSupportPage'))
const CareTeamPage = lazy(() => import('./pages/Support/CareTeamPage'))
const CaseDiscussionsPage = lazy(() => import('./pages/Support/CaseDiscussionsPage'))
const SpecialistWorkflowPage = lazy(() => import('./pages/Support/SpecialistWorkflowPage'))
const ParentLessonsPage = lazy(() => import('./pages/Learning/ParentLessonsPage'))

const LessonEditorPage = lazy(() => import('./pages/Learning/LessonEditorPage'))

function Protected({ children }) {
  const location = useLocation()
  const { verified: identityVerified } = useVerification()
  const verified = identityVerified || getUser()?.role === 'parent'
  if (!getToken()) return <Navigate to="/login" replace />
  if (!verified && !canOpenUnverifiedPath(location.pathname)) return <VerificationRequired />
  return children
}

function RoleProtected({ roles, children }) {
  if (!getToken()) return <Navigate to="/login" replace />
  const user = getUser()
  if (!user || !roles.includes(user.role)) return <Navigate to={dashboardFor(user)} replace />
  return <Protected>{children}</Protected>
}

function DashboardRedirect() {
  if (!getToken()) return <Navigate to="/login" replace />
  return <Navigate to={dashboardFor(getUser())} replace />
}

function HomeRedirect() {
  if (!getToken()) return <HomePage />
  return <Navigate to={dashboardFor(getUser())} replace />
}

function GuestOnly({ children }) {
  if (getToken()) return <Navigate to={dashboardFor(getUser())} replace />
  return children
}

function Page({ children }) {
  const { verified: identityVerified } = useVerification()
  const verified = identityVerified || getUser()?.role === 'parent'
  const user = getUser()
  const location = useLocation()
  const useRoleShell = verified && Boolean(user?.role)
    && isPortalPathForRole(location.pathname, user.role)

  if (useRoleShell) return <RolePortalLayout>{children}</RolePortalLayout>
  return <main className="container">{children}</main>
}

function RolePage({ roles, children }) {
  return <RoleProtected roles={roles}><Page>{children}</Page></RoleProtected>
}

export default function AppRoutes() {
  const location = useLocation()
  return (
    <RouteLoadBoundary key={location.pathname}>
      <Suspense fallback={<main className="container route-load-state" role="status" aria-live="polite" dir="rtl">جارِ تحميل الصفحة…</main>}>
        <Routes>
          <Route path="/login" element={<GuestOnly><LoginPage /></GuestOnly>} />
          <Route path="/register" element={<GuestOnly><RegisterPage /></GuestOnly>} />
          <Route path="/forgot-password" element={<GuestOnly><ForgotPasswordPage /></GuestOnly>} />
          <Route path="/reset-password" element={<GuestOnly><ResetPasswordPage /></GuestOnly>} />
          <Route path="/dashboard" element={<DashboardRedirect />} />
          <Route path="/about" element={<Page><AboutPage /></Page>} />
          <Route path="/" element={<HomeRedirect />} />

          <Route path="/parent" element={<RolePage roles={['parent']}><ParentDashboard /></RolePage>} />
          <Route path="/teacher/invitation" element={<RolePage roles={['teacher']}><TeacherInvitationPage /></RolePage>} />
          <Route path="/teacher" element={<RolePage roles={['teacher']}><TeacherDashboard /></RolePage>} />
          <Route path="/specialist" element={<RolePage roles={['specialist']}><SpecialistDashboard /></RolePage>} />
          <Route path="/admin" element={<RolePage roles={['admin']}><AdminPage /></RolePage>} />
          <Route path="/institution" element={<RolePage roles={['institution']}><InstitutionDashboard /></RolePage>} />
          <Route path="/institution/schools" element={<RolePage roles={['institution']}><InstitutionSchoolsPage /></RolePage>} />
          <Route path="/institution/reports" element={<RolePage roles={['institution']}><InstitutionReportsPage /></RolePage>} />
          <Route path="/institution/substitutions" element={<RolePage roles={['institution']}><InstitutionSubstitutionsPage /></RolePage>} />
          <Route path="/institution/timetable" element={<RolePage roles={['institution']}><InstitutionTimetablePage /></RolePage>} />
          <Route path="/institution/attendance" element={<RolePage roles={['institution']}><InstitutionAttendancePage /></RolePage>} />
          <Route path="/institution/students" element={<RolePage roles={['institution']}><InstitutionStudentsPage /></RolePage>} />
          <Route path="/institution/teachers" element={<RolePage roles={['institution']}><InstitutionTeachersPage /></RolePage>} />
          <Route path="/ministry" element={<RolePage roles={['ministry']}><MinistryPage /></RolePage>} />

          <Route path="/notifications" element={<Protected><Page><NotificationsPage /></Page></Protected>} />
          <Route path="/conversations" element={<Protected><Page><ConversationsPage /></Page></Protected>} />
          <Route path="/lessons/new" element={<RolePage roles={['teacher', 'specialist', 'admin']}><LessonEditorPage /></RolePage>} />
          <Route path="/lessons" element={<Protected><Page><LessonsPage /></Page></Protected>} />
          <Route path="/verify" element={<Protected><Page><VerifyIdentityPage /></Page></Protected>} />
          <Route path="/profile" element={<Protected><Page><ProfilePage /></Page></Protected>} />
          <Route path="/support" element={<Protected><Page><SupportPage /></Page></Protected>} />

          <Route path="/children" element={<RolePage roles={CHILD_ROLES}><ChildrenPage /></RolePage>} />
          <Route path="/children/new" element={<RolePage roles={['parent']}><ChildFormPage /></RolePage>} />
          <Route path="/children/:childId" element={<RolePage roles={CHILD_ROLES}><ChildDetailsPage /></RolePage>} />
          <Route path="/children/:childId/edit" element={<RolePage roles={CHILD_ROLES}><ChildFormPage /></RolePage>} />
          <Route path="/children/:childId/lessons" element={<RolePage roles={CHILD_ROLES}><ChildLessonsPage /></RolePage>} />
          <Route path="/children/:childId/progress" element={<RolePage roles={CHILD_ROLES}><ChildProgressPage /></RolePage>} />
          <Route path="/children/:childId/games" element={<RolePage roles={CHILD_ROLES}><EducationalGamesPage /></RolePage>} />
          <Route path="/children/:childId/accessibility" element={<RolePage roles={['specialist']}><AccessibilityPage /></RolePage>} />
          <Route path="/accessibility" element={<RolePage roles={['specialist']}><AccessibilityOverviewPage /></RolePage>} />

          <Route path="/search" element={<RolePage roles={STAFF_SEARCH_ROLES}><SearchPage /></RolePage>} />
          <Route path="/consultations" element={<RolePage roles={CONSULTATION_ROLES}><ConsultationsPage /></RolePage>} />
          <Route path="/homeworks" element={<RolePage roles={['parent','teacher','specialist','admin']}><HomeworkPage /></RolePage>} />
          <Route path="/weekly-reports" element={<RolePage roles={['parent','teacher','specialist','admin']}><WeeklyReportsPage /></RolePage>} />
          <Route path="/learning-support" element={<RolePage roles={['parent','specialist','admin']}><LearningSupportPage /></RolePage>} />
          <Route path="/care-team" element={<RolePage roles={['parent','teacher','specialist','admin']}><CareTeamPage /></RolePage>} />
          <Route path="/case-discussions" element={<RolePage roles={['teacher','specialist','admin']}><CaseDiscussionsPage /></RolePage>} />
          <Route path="/specialist-workflow" element={<RolePage roles={['specialist','admin']}><SpecialistWorkflowPage /></RolePage>} />
          <Route path="/parent-lessons" element={<RolePage roles={CHILD_ROLES}><ParentLessonsPage /></RolePage>} />
          <Route path="/aac" element={<RolePage roles={CHILD_ROLES}><Navigate to="/conversations?mode=aac" replace /></RolePage>} />
          <Route path="/admin/verifications" element={<RolePage roles={['admin']}><VerificationsPage /></RolePage>} />

          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </Suspense>
    </RouteLoadBoundary>
  )
}
