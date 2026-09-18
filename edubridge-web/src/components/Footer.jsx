// تذييل الموقع — مشترك بين الصفحات
import { Link } from 'react-router-dom'
import { Download, Headphones, Instagram, Linkedin, MapPin, Smartphone } from 'lucide-react'

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
              <Instagram size={20} />
            </a>
            <a href={LINKEDIN_URL} target="_blank" rel="noopener noreferrer" aria-label="EduBridge على LinkedIn">
              <Linkedin size={20} />
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
