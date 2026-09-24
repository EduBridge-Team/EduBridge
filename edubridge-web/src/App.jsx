import { Navigate, Route, Routes, useLocation } from 'react-router-dom'
import { getToken, getUser } from './api'
import { dashboardFor } from './roleRoutes'
import { CHILD_ROLES, CONSULTATION_ROLES, STAFF_SEARCH_ROLES, isPortalPathForRole } from './portalRoutes'
import TopBar from './components/TopBar'
import RolePortalShell from './components/ParentPortalShell'
import AssistantWidget from './components/AssistantWidget'
import NoorRunnerWidget from './components/NoorRunnerWidget'
import HomePage from './pages/HomePage'
import LoginPage from './pages/LoginPage'
import RegisterPage from './pages/RegisterPage'
import ChildrenPage from './pages/ChildrenPage'
import ChildLessonsPage from './pages/ChildLessonsPage'
import ChildProgressPage from './pages/ChildProgressPage'
import LessonsPage from './pages/LessonsPage'
import AboutPage from './pages/AboutPage'
import AdminPage from './pages/AdminPage'
import TeacherDashboard from './pages/TeacherDashboard'
import SpecialistDashboard from './pages/SpecialistDashboard'
import ParentDashboard from './pages/ParentDashboard'
import ChildDetailsPage from './pages/ChildDetailsPage'
import ChildFormPage from './pages/ChildFormPage'
import NotificationsPage from './pages/NotificationsPage'
import SearchPage from './pages/SearchPage'
import VerifyIdentityPage from './pages/VerifyIdentityPage'
import ProfilePage from './pages/ProfilePage'
import VerificationsPage from './pages/VerificationsPage'
import SupportPage from './pages/SupportPage'
import MinistryPage from './pages/MinistryPage'
import ConsultationsPage from './pages/ConsultationsPage'
import EducationalGamesPage from './pages/EducationalGamesPage'
import AccessibilityPage from './pages/AccessibilityPage'
import AccessibilityOverviewPage from './pages/AccessibilityOverviewPage'
import ConversationsPage from './pages/ConversationsPage'
import InstitutionDashboard from './pages/InstitutionDashboard'
import HomeworkPage from './pages/HomeworkPage'
import WeeklyReportsPage from './pages/WeeklyReportsPage'
import LearningSupportPage from './pages/LearningSupportPage'
import CareTeamPage from './pages/CareTeamPage'
import CaseDiscussionsPage from './pages/CaseDiscussionsPage'
import SpecialistWorkflowPage from './pages/SpecialistWorkflowPage'
import ParentLessonsPage from './pages/ParentLessonsPage'
import AACPage from './pages/AACPage'
import VoiceCommandWidget from './components/VoiceCommandWidget'
import './parent-portal.css'

function Protected({ children }) {
  if (!getToken()) return <Navigate to="/login" replace />
  return children
}

function RoleProtected({ roles, children }) {
  if (!getToken()) return <Navigate to="/login" replace />
  const user = getUser()
  if (!user || !roles.includes(user.role)) return <Navigate to={dashboardFor(user)} replace />
  return children
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
  const user = getUser()
  const location = useLocation()
  const useRoleShell = Boolean(user?.role)
    && isPortalPathForRole(location.pathname, user.role)

  if (useRoleShell) return <RolePortalShell>{children}</RolePortalShell>
  return <main className="container">{children}</main>
}

function RolePage({ roles, children }) {
  return <RoleProtected roles={roles}><Page>{children}</Page></RoleProtected>
}

export default function App() {
  return (
    <div>
      <TopBar />
      <Routes>
        <Route path="/login" element={<GuestOnly><LoginPage /></GuestOnly>} />
        <Route path="/register" element={<GuestOnly><RegisterPage /></GuestOnly>} />
        <Route path="/dashboard" element={<DashboardRedirect />} />
        <Route path="/about" element={<Page><AboutPage /></Page>} />
        <Route path="/" element={<HomeRedirect />} />

        <Route path="/parent" element={<RolePage roles={['parent']}><ParentDashboard /></RolePage>} />
        <Route path="/teacher" element={<RolePage roles={['teacher']}><TeacherDashboard /></RolePage>} />
        <Route path="/specialist" element={<RolePage roles={['specialist']}><SpecialistDashboard /></RolePage>} />
        <Route path="/admin" element={<RolePage roles={['admin']}><AdminPage /></RolePage>} />
        <Route path="/institution" element={<RolePage roles={['institution']}><InstitutionDashboard /></RolePage>} />
        <Route path="/ministry" element={<RolePage roles={['ministry', 'admin']}><MinistryPage /></RolePage>} />

        <Route path="/notifications" element={<Protected><Page><NotificationsPage /></Page></Protected>} />
        <Route path="/conversations" element={<Protected><Page><ConversationsPage /></Page></Protected>} />
        <Route path="/lessons" element={<Protected><Page><LessonsPage /></Page></Protected>} />
        <Route path="/verify" element={<Protected><Page><VerifyIdentityPage /></Page></Protected>} />
        <Route path="/profile" element={<Protected><Page><ProfilePage /></Page></Protected>} />
        <Route path="/support" element={<Protected><Page><SupportPage /></Page></Protected>} />

        <Route path="/children" element={<RolePage roles={CHILD_ROLES}><ChildrenPage /></RolePage>} />
        <Route path="/children/new" element={<RolePage roles={['parent', 'admin']}><ChildFormPage /></RolePage>} />
        <Route path="/children/:childId" element={<RolePage roles={CHILD_ROLES}><ChildDetailsPage /></RolePage>} />
        <Route path="/children/:childId/edit" element={<RolePage roles={CHILD_ROLES}><ChildFormPage /></RolePage>} />
        <Route path="/children/:childId/lessons" element={<RolePage roles={CHILD_ROLES}><ChildLessonsPage /></RolePage>} />
        <Route path="/children/:childId/progress" element={<RolePage roles={CHILD_ROLES}><ChildProgressPage /></RolePage>} />
        <Route path="/children/:childId/games" element={<RolePage roles={CHILD_ROLES}><EducationalGamesPage /></RolePage>} />
        <Route path="/children/:childId/accessibility" element={<RolePage roles={CHILD_ROLES}><AccessibilityPage /></RolePage>} />
        <Route path="/accessibility" element={<RolePage roles={CHILD_ROLES}><AccessibilityOverviewPage /></RolePage>} />

        <Route path="/search" element={<RolePage roles={STAFF_SEARCH_ROLES}><SearchPage /></RolePage>} />
        <Route path="/consultations" element={<RolePage roles={CONSULTATION_ROLES}><ConsultationsPage /></RolePage>} />
        <Route path="/homeworks" element={<RolePage roles={['parent','teacher','specialist','admin']}><HomeworkPage /></RolePage>} />
        <Route path="/weekly-reports" element={<RolePage roles={['parent','teacher','specialist','admin']}><WeeklyReportsPage /></RolePage>} />
        <Route path="/learning-support" element={<RolePage roles={['parent','specialist','admin']}><LearningSupportPage /></RolePage>} />
        <Route path="/care-team" element={<RolePage roles={['parent','teacher','specialist','admin']}><CareTeamPage /></RolePage>} />
        <Route path="/case-discussions" element={<RolePage roles={['teacher','specialist','admin']}><CaseDiscussionsPage /></RolePage>} />
        <Route path="/specialist-workflow" element={<RolePage roles={['teacher','specialist','admin']}><SpecialistWorkflowPage /></RolePage>} />
        <Route path="/parent-lessons" element={<RolePage roles={['parent']}><ParentLessonsPage /></RolePage>} />
        <Route path="/aac" element={<RolePage roles={CHILD_ROLES}><AACPage /></RolePage>} />
        <Route path="/admin/verifications" element={<RolePage roles={['admin']}><VerificationsPage /></RolePage>} />

        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
      <AssistantWidget />
      <NoorRunnerWidget />
      <VoiceCommandWidget />
    </div>
  )
}
