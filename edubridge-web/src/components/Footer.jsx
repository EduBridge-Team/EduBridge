// تذييل الموقع — مشترك بين الصفحات
import { Link } from 'react-router-dom'
import { Headphones, MapPin, Smartphone } from 'lucide-react'

export default function Footer() {
  return (
    <footer className="site-footer" id="contact">
      <div className="footer-grid">
        <div className="footer-identity">
          <div className="brand-lockup brand-lockup--footer" aria-label="EduBridge">
            <img className="brand-lockup-icon" src="/edubridge-icon.png" alt="" />
            <span className="brand-wordmark">EduBridge</span>
          </div>
          <p>معاً، لكل طفل فرصة. تعليم ذكي وشامل يدعم رحلة كل متعلم.</p>
        </div>
        <div>
          <h4>روابط هامة</h4>
          <Link to="/about">عن المنصة</Link>
          <Link to="/lessons">تصفح الدروس</Link>
          <Link to="/login">تسجيل الدخول</Link>
          <a
            className="footer-contact"
            href="https://github.com/EduBridge-Team/EduBridge/releases/latest"
            target="_blank"
            rel="noreferrer"
          >
            <Smartphone size={16} /> حمّل تطبيق الأندرويد
          </a>
        </div>
        <div>
          <h4>تواصل معنا</h4>
          <div className="footer-contact"><MapPin size={16} /> فلسطين</div>
          <div className="footer-contact"><Headphones size={16} /> دعم متاح على مدار الساعة</div>
        </div>
      </div>
      <div className="footer-copy">
        © 2026 EduBridge — جميع الحقوق محفوظة.
      </div>
    </footer>
  )
}
