import BrandLogo from './BrandLogo/BrandLogo'

export default function RouteLoadingFallback() {
  return (
    <main className="route-loading-screen" role="status" aria-live="polite" dir="rtl">
      <div className="route-loading-content">
        <BrandLogo className="route-loading-logo" />
        <span className="route-loading-spinner" aria-hidden="true" />
        <span className="sr-only">جارِ تحميل الصفحة…</span>
      </div>
    </main>
  )
}
