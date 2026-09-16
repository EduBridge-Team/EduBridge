// المسارات + الشريط العلوي + حماية الصفحات بالتوكن
import { Navigate, Route, Routes } from 'react-router-dom'
import { getToken, getUser } from './api'
import { dashboardFor } from './roleRoutes'
import TopBar from './components/TopBar'
import AssistantWidget from './components/AssistantWidget'
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
import VerificationsPage from './pages/VerificationsPage'
import SupportPage from './pages/SupportPage'
import MinistryPage from './pages/MinistryPage'
import ConsultationsPage from './pages/ConsultationsPage'
import EducationalGamesPage from './pages/EducationalGamesPage'
import AccessibilityPage from './pages/AccessibilityPage'
import AccessibilityOverviewPage from './pages/AccessibilityOverviewPage'
import ConversationsPage from './pages/ConversationsPage'
import InstitutionDashboard from './pages/InstitutionDashboard'

// صفحة محمية: بدون توكن نحوّل المستخدم لتسجيل الدخول
function Protected({ children }) {
  if (!getToken()) return <Navigate to="/login" replace />
  return children
}

function RoleProtected({ roles, children }) {
  if (!getToken()) return <Navigate to="/login" replace />
  const user = getUser()
  if (!user || !roles.includes(user.role)) {
    return <Navigate to={dashboardFor(user)} replace />
  }
  return children
}

function DashboardRedirect() {
  if (!getToken()) return <Navigate to="/login" replace />
  return <Navigate to={dashboardFor(getUser())} replace />
}

// الصفحة الرئيسية العامة تبقى للزوار فقط. المستخدم المسجّل يذهب مباشرة للوحة دوره.
function HomeRedirect() {
  if (!getToken()) return <HomePage />
  return <Navigate to={dashboardFor(getUser())} replace />
}

// لا نعيد عرض صفحات الدخول/التسجيل لمستخدم لديه جلسة فعّالة.
function GuestOnly({ children }) {
  if (getToken()) return <Navigate to={dashboardFor(getUser())} replace />
  return children
}

// حاوية موحّدة لصفحات المحتوى
function Page({ children }) {
  return <main className="container">{children}</main>
}

export default function App() {
  return (
    <div>
      {/* الشريط العلوي في كل الصفحات */}
      <TopBar />

      <Routes>
        <Route path="/login" element={<GuestOnly><LoginPage /></GuestOnly>} />
        <Route path="/register" element={<GuestOnly><RegisterPage /></GuestOnly>} />
        <Route path="/dashboard" element={<DashboardRedirect />} />
        <Route
          path="/about"
          element={
            <Page>
              <AboutPage />
            </Page>
          }
        />
        {/* الصفحة الرئيسية — للزائر فقط، والمستخدم المسجّل يُفتح له dashboard دوره */}
        <Route path="/" element={<HomeRedirect />} />
        {/* لوحة ولي الأمر */}
        <Route
          path="/parent"
          element={
            <RoleProtected roles={['parent']}>
              <Page>
                <ParentDashboard />
              </Page>
            </RoleProtected>
          }
        />
        <Route
          path="/notifications"
          element={
            <Protected>
              <Page>
                <NotificationsPage />
              </Page>
            </Protected>
          }
        />
        <Route
          path="/children"
          element={
            <Protected>
              <Page>
                <ChildrenPage />
              </Page>
            </Protected>
          }
        />
        <Route
          path="/children/new"
          element={
            <Protected>
              <Page>
                <ChildFormPage />
              </Page>
            </Protected>
          }
        />
        <Route
          path="/children/:childId"
          element={
            <Protected>
              <Page>
                <ChildDetailsPage />
              </Page>
            </Protected>
          }
        />
        <Route
          path="/children/:childId/edit"
          element={
            <Protected>
              <Page>
                <ChildFormPage />
              </Page>
            </Protected>
          }
        />
        <Route
          path="/lessons"
          element={
            <Protected>
              <Page>
                <LessonsPage />
              </Page>
            </Protected>
          }
        />
        <Route
          path="/children/:childId/lessons"
          element={
            <Protected>
              <Page>
                <ChildLessonsPage />
              </Page>
            </Protected>
          }
        />
        <Route
          path="/children/:childId/progress"
          element={
            <Protected>
              <Page>
                <ChildProgressPage />
              </Page>
            </Protected>
          }
        />
        <Route
          path="/children/:childId/games"
          element={<Protected><Page><EducationalGamesPage /></Page></Protected>}
        />
        <Route
          path="/children/:childId/accessibility"
          element={<Protected><Page><AccessibilityPage /></Page></Protected>}
        />
        <Route
          path="/accessibility"
          element={<Protected><Page><AccessibilityOverviewPage /></Page></Protected>}
        />
        <Route
          path="/conversations"
          element={<Protected><Page><ConversationsPage /></Page></Protected>}
        />
        <Route
          path="/admin"
          element={
            <RoleProtected roles={['admin']}>
              <AdminPage />
            </RoleProtected>
          }
        />
        <Route
          path="/admin/verifications"
          element={
            <RoleProtected roles={['admin']}>
              <VerificationsPage />
            </RoleProtected>
          }
        />
        <Route
          path="/search"
          element={
            <Protected>
              <Page>
                <SearchPage />
              </Page>
            </Protected>
          }
        />
        <Route
          path="/verify"
          element={
            <Protected>
              <Page>
                <VerifyIdentityPage />
              </Page>
            </Protected>
          }
        />
        <Route
          path="/support"
          element={
            <Protected>
              <Page>
                <SupportPage />
              </Page>
            </Protected>
          }
        />
        <Route
          path="/consultations"
          element={
            <Protected>
              <Page>
                <ConsultationsPage />
              </Page>
            </Protected>
          }
        />
        <Route
          path="/ministry"
          element={
            <RoleProtected roles={['ministry', 'admin']}>
              <MinistryPage />
            </RoleProtected>
          }
        />
        <Route
          path="/teacher"
          element={
            <RoleProtected roles={['teacher']}>
              <TeacherDashboard />
            </RoleProtected>
          }
        />
        <Route
          path="/specialist"
          element={
            <RoleProtected roles={['specialist']}>
              <SpecialistDashboard />
            </RoleProtected>
          }
        />
        <Route
          path="/institution"
          element={
            <RoleProtected roles={['institution']}>
              <InstitutionDashboard />
            </RoleProtected>
          }
        />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>

      {/* نور يظهر فقط للمستخدم المسجّل دخوله */}
      <AssistantWidget />
    </div>
  )
}
