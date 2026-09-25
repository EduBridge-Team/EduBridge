export default function BrandLogo({ className = '', title = 'EduBridge' }) {
  return (
    <svg
      className={className}
      viewBox="0 0 460 110"
      role="img"
      aria-label={title}
      xmlns="http://www.w3.org/2000/svg"
      preserveAspectRatio="xMidYMid meet"
    >
      <image href="/edubridge-icon.png" x="0" y="5" width="100" height="100" preserveAspectRatio="xMidYMid meet" />
      <text
        x="112"
        y="76"
        fontFamily="Inter, system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif"
        fontSize="58"
        fontWeight="800"
        letterSpacing="-2"
      >
        <tspan fill="#1769c2">Edu</tspan>
        <tspan fill="#25b8c8">Bridge</tspan>
      </text>
    </svg>
  )
}
