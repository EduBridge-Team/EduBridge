export function AACSentencePanel({
  sentence,
  onClear,
  onRemoveLast,
  onSpeak,
}) {
  return (
    <section className="fp-card">
      <div className="aac-sentence">
        {sentence.length ? (
          sentence.map((word, index) => (
            <span key={`${word}-${index}`} className="fp-badge">{word}</span>
          ))
        ) : (
          <span className="meta">اضغط على الصور لبناء جملة</span>
        )}
      </div>

      <div className="fp-actions">
        <button className="btn success" onClick={onSpeak} disabled={!sentence.length}>
          🔊 قلها
        </button>
        <button className="btn outline" onClick={onRemoveLast} disabled={!sentence.length}>
          ⌫ حذف آخر
        </button>
        <button className="btn outline" onClick={onClear} disabled={!sentence.length}>
          مسح
        </button>
      </div>
    </section>
  )
}

export function AACCategoryTabs({
  categories,
  selectedCategory,
  onSelect,
}) {
  return (
    <div className="fp-actions">
      {categories.map((category) => (
        <button
          key={category}
          className={category === selectedCategory ? 'btn' : 'btn outline'}
          onClick={() => onSelect(category)}
        >
          {category}
        </button>
      ))}
    </div>
  )
}

export function AACSymbolGrid({ items, onSelect }) {
  return (
    <section className="aac-grid">
      {items.map(([emoji, label, spoken]) => (
        <button
          className="aac-tile"
          key={`${label}-${spoken}`}
          onClick={() => onSelect(label, spoken)}
        >
          <span>{emoji}</span>
          <strong>{label}</strong>
        </button>
      ))}
    </section>
  )
}
