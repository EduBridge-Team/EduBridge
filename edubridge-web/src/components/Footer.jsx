// تذييل الموقع — مشترك بين الصفحات
import { Link } from 'react-router-dom'
import { Download, Headphones, MapPin, Smartphone } from 'lucide-react'

function InstagramIcon({ size = 20 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <rect x="3" y="3" width="18" height="18" rx="5" stroke="currentColor" strokeWidth="2" />
      <circle cx="12" cy="12" r="4" stroke="currentColor" strokeWidth="2" />
      <circle cx="17.5" cy="6.5" r="1.1" fill="currentColor" />
    </svg>
  )
}

function LinkedinIcon({ size = 20 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
      <path d="M5.2 7.7H2.3V21h2.9V7.7ZM3.75 2A1.72 1.72 0 1 0 3.75 5.44 1.72 1.72 0 0 0 3.75 2ZM21.7 13.36c0-4.01-2.14-5.88-5-5.88-2.3 0-3.33 1.27-3.91 2.16V7.78H9.9V21h2.89v-6.55c0-1.73.33-3.41 2.48-3.41 2.12 0 2.15 1.98 2.15 3.52V21h2.89l.01-7.64h1.38Z" />
    </svg>
  )
}

const ANDROID_DOWNLOAD_URL = 'https://github.com/EduBridge-Team/EduBridge/releases/download/v1.10.0/app-release.apk'
const LINKEDIN_URL = 'https://www.linkedin.com/company/%D8%AC%D8%B3%D8%B1-%D8%AA%D8%B9%D9%84%D9%8A%D9%85%D9%8A-edubridge/'
const INSTAGRAM_URL = 'https://www.instagram.com/edu_bridge12?stkn=dDlmMTdnMnBrczB0'

export default function Footer() {
  return (
    <footer className="site-footer" id="contact">
      <div className="footer-decor footer-decor-a" aria-hidden="true" />
      <div className="footer-decor footer-decor-b" aria-hidden="true" />

      <div className="footer-grid">
        <div className="footer-identity">
          <div className="brand-lockup brand-lockup--footer" aria-label="EduBridge">
            <img className="brand-lockup-icon" src="/edubridge-icon.png" alt="" />
            <span className="brand-wordmark">EduBridge</span>
          </div>
          <p>معاً، لكل طفل فرصة. تعليم ذكي وشامل يدعم رحلة كل متعلم.</p>
        </div>

        <div className="footer-column">
          <h4>روابط هامة</h4>
          <Link to="/">الرئيسية</Link>
          <Link to="/about">من نحن</Link>
          <Link to="/lessons">الدروس</Link>
          <Link to="/login">تسجيل الدخول</Link>
        </div>

        <div className="footer-column">
          <h4>تواصل معنا</h4>
          <div className="footer-contact"><MapPin size={16} /> فلسطين</div>
          <div className="footer-contact"><Headphones size={16} /> دعم متاح على مدار الساعة</div>
          <a className="footer-contact" href="mailto:ibrahimgandeel@gmail.com">ibrahimgandeel@gmail.com</a>
        </div>

        <div className="footer-column footer-follow">
          <h4>تابعنا على</h4>
          <div className="footer-socials" aria-label="حسابات EduBridge على شبكات التواصل">
            <a href={INSTAGRAM_URL} target="_blank" rel="noopener noreferrer" aria-label="EduBridge على Instagram">
              <InstagramIcon size={20} />
            </a>
            <a href={LINKEDIN_URL} target="_blank" rel="noopener noreferrer" aria-label="EduBridge على LinkedIn">
              <LinkedinIcon size={20} />
            </a>
          </div>

          <a
            className="footer-download-btn"
            href={ANDROID_DOWNLOAD_URL}
            target="_blank"
            rel="noopener noreferrer"
          >
            <Smartphone size={18} />
            <span>حمّل تطبيق الأندرويد</span>
            <Download size={17} />
          </a>
        </div>
      </div>

      <div className="footer-copy">
        © 2026 EduBridge — جميع الحقوق محفوظة.
      </div>
    </footer>
  )
}
