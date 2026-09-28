export default function ParentNavigation({ navItems, onHome }) {
  return (
    <>
      <aside className="pd-sidebar" aria-label="قائمة ولي الأمر">
        <button className="pd-brand" onClick={onHome} aria-label="EduBridge">
          <img src="/edubridge-icon.png" alt="" />
          <span>EduBridge</span>
        </button>

        <nav className="pd-side-nav">
          {navItems.map((item) => (
            <button
              key={item.label}
              className={item.active ? 'active' : ''}
              onClick={item.onClick}
              title={item.label}
              aria-label={item.label}
              aria-current={item.active ? 'page' : undefined}
              disabled={item.disabled}
            >
              {item.icon}
              <span>{item.label}</span>
              {item.badge > 0 && <em>{Math.min(item.badge, 99)}</em>}
            </button>
          ))}
        </nav>
      </aside>

      <nav className="pd-mobile-nav" aria-label="تنقل ولي الأمر">
        {navItems.slice(0, 5).map((item) => (
          <button
            key={item.label}
            className={item.active ? 'active' : ''}
            onClick={item.onClick}
            title={item.label}
            aria-label={item.label}
            aria-current={item.active ? 'page' : undefined}
          >
            {item.icon}
            <span>{item.label}</span>
          </button>
        ))}
      </nav>
    </>
  )
}
