export default function ListPagination({ meta, loading, onPage }) {
  if (!meta || meta.last_page <= 1) return null
  return (
    <nav aria-label="صفحات القائمة" className="card" style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', gap: 16, flexWrap: 'wrap' }}>
      <button className="btn outline" disabled={loading || meta.page <= 1} onClick={() => onPage(meta.page - 1)}>السابق</button>
      <span aria-live="polite">صفحة {meta.page} من {meta.last_page} · {meta.total} نتيجة</span>
      <button className="btn outline" disabled={loading || !meta.has_more} onClick={() => onPage(meta.page + 1)}>التالي</button>
    </nav>
  )
}
