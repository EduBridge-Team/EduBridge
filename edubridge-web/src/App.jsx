// المسارات + الشريط العلوي + حماية الصفحات بالتوكن
import { Navigate, Route, Routes } from 'react-router-dom'
import { getToken } from './api'
import TopBar from './components/TopBar'
import LoginPage from './pages/LoginPage'
import RegisterPage from './pages/RegisterPage'
import ChildrenPage from './pages/ChildrenPage'
import ChildLessonsPage from './pages/ChildLessonsPage'
import ChildProgressPage from './pages/ChildProgressPage'
import LessonsPage from './pages/LessonsPage'
import AboutPage from './pages/AboutPage'

// صفحة محمية: بدون توكن → تحويل لتسجيل الدخول
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
        <Route
          path="/"
          element={
            <Protected>
              <Page>
                <ChildrenPage />
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
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </div>
  )
}
