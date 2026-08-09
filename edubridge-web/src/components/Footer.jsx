// تذييل الموقع — مشترك بين الصفحات
import { Link } from 'react-router-dom'

export default function Footer() {
  return (
    <footer className="site-footer">
      <div className="footer-grid">
        <div>
          <h3 className="footer-brand">EduBridge — جسر تعليمي</h3>
          <p className="muted">
            نسعى لتمكين كل طالب بفرص تعليمية متساوية وعادلة، من خلال الابتكار في
            تقنيات الوصول الرقمي.
          </p>
        </div>
        <div>
          <h4>روابط هامة</h4>
          <Link to="/about">عن المنصة</Link>
          <Link to="/lessons">تصفح الدروس</Link>
          <Link to="/login">تسجيل الدخول</Link>
          <a
            href="https://github.com/EduBridge-Team/EduBridge/releases/latest"
            target="_blank"
            rel="noreferrer"
          >
            📱 حمّل تطبيق الأندرويد
          </a>
        </div>
        <div>
          <h4>بيانات التواصل</h4>
          <div>📍 فلسطين</div>
          <div>🎧 دعم متاح على مدار الساعة</div>
        </div>
      </div>
      <div className="footer-copy">
        © 2026 EduBridge — جسر تعليمي. التمكين عبر إمكانية الوصول.
      </div>
    </footer>
  )
}
