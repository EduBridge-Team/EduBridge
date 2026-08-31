// المسارات + الشريط العلوي + حماية الصفحات بالتوكن
import { Navigate, Route, Routes } from 'react-router-dom'
import { getToken } from './api'
import TopBar from './components/TopBar'
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

// صفحة محمية: بدون توكن نحوّل المستخدم لتسجيل الدخول
function Protected({ children }) {
  if (!getToken()) return <Navigate to="/login" replace />
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
        <Route path="/login" element={<LoginPage />} />
        <Route path="/register" element={<RegisterPage />} />
        <Route
          path="/about"
          element={
            <Page>
              <AboutPage />
            </Page>
          }
        />
        {/* الصفحة الرئيسية — عامة بدون تسجيل دخول */}
        <Route path="/" element={<HomePage />} />
        {/* لوحة ولي الأمر */}
        <Route
          path="/parent"
          element={
            <Protected>
              <Page>
                <ParentDashboard />
              </Page>
            </Protected>
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
          path="/admin"
          element={
            <Protected>
              <AdminPage />
            </Protected>
          }
        />
        <Route
          path="/teacher"
          element={
            <Protected>
              <TeacherDashboard />
            </Protected>
          }
        />
        <Route
          path="/specialist"
          element={
            <Protected>
              <SpecialistDashboard />
            </Protected>
          }
        />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </div>
  )
}
