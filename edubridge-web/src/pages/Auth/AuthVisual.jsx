import BrandLogo from '../../components/BrandLogo/BrandLogo'

export default function AuthVisual({ registration = false }) {
  return (
    <section className="auth-visual auth-visual-art" aria-label="رحلة التعلم مع EduBridge">
      <div className="auth-art-heading">
        <BrandLogo className="auth-art-logo" />
        <h2>{registration ? 'ابدأ رحلتك معنا' : 'مرحباً بعودتك'}</h2>
        <p>تعلّم ودعم لكل طفل، خطوة بخطوة.</p>
      </div>
      <img
        src="/auth-learning-hq.webp"
        alt="أم تساعد طفلها على التعلم باستخدام الحاسوب"
        width="1122"
        height="1402"
        decoding="async"
        fetchPriority="high"
      />
    </section>
  )
}
