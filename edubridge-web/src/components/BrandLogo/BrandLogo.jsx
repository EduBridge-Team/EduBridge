export default function BrandLogo({ className = '', title = 'EduBridge' }) {
  return (
    <img
      className={className}
      src="/edubridge-logo-horizontal-transparent.png"
      alt={title}
      decoding="async"
    />
  )
}
