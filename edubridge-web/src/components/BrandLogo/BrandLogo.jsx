export default function BrandLogo({ className = '', title = 'EduBridge' }) {
  return (
    <img
      className={className}
      src="/edubridge-logo-horizontal-transparent.webp"
      alt={title}
      decoding="async"
    />
  )
}
