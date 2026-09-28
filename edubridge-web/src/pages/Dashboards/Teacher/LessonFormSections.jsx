export function LessonAudienceFields({ audience, onAudienceChange, onTypeIdChange, typeId, types }) {
  return (
    <>
      <label>الفئة المستهدفة</label>
      <select value={audience} onChange={(e) => onAudienceChange(e.target.value)}>
        <option value="children">الأطفال</option>
        <option value="parents">أولياء الأمور</option>
      </select>

      {audience === 'children' && (
        <>
          <label>نوع الإعاقة المستهدَف</label>
          <select value={typeId} onChange={(e) => onTypeIdChange(e.target.value)}>
            <option value="">— عام (كل الأنواع) —</option>
            {types.map((type) => (
              <option key={type.id} value={type.id}>{type.name}</option>
            ))}
          </select>
        </>
      )}
    </>
  )
}

export function LessonMediaFields({
  audioDescription,
  existingMedia,
  isEditing,
  onAudioChange,
  onAudioDescriptionChange,
  onCaptionChange,
  onImagesChange,
  onSignLanguageChange,
  onVideoChange,
}) {
  return (
    <>
      {isEditing && existingMedia.length > 0 && (
        <div className="meta" style={{ margin: '10px 0' }}>
          الوسائط الحالية: {existingMedia.join('، ')}. اختيار ملف جديد يستبدل الوسائط من النوع نفسه.
        </div>
      )}

      <label>{isEditing ? 'استبدال صور الدرس' : 'صور الدرس (يمكن اختيار عدة صور)'}</label>
      <input
        type="file"
        accept="image/jpeg,image/png,image/webp"
        multiple
        onChange={(e) => onImagesChange(Array.from(e.target.files || []))}
      />

      <label>{isEditing ? 'استبدال فيديو الدرس' : 'فيديو الدرس'}</label>
      <input
        type="file"
        accept="video/mp4,video/webm,video/quicktime"
        onChange={(e) => onVideoChange(e.target.files?.[0] || null)}
      />

      <label>{isEditing ? 'استبدال التسجيل الصوتي' : 'تسجيل صوتي'}</label>
      <input
        type="file"
        accept="audio/mpeg,audio/mp4,audio/aac,audio/wav,audio/ogg"
        onChange={(e) => onAudioChange(e.target.files?.[0] || null)}
      />

      <label>{isEditing ? 'استبدال ملف الترجمة' : 'ملف الترجمة (.vtt أو .srt)'}</label>
      <input
        type="file"
        accept=".vtt,.srt,text/vtt"
        onChange={(e) => onCaptionChange(e.target.files?.[0] || null)}
      />

      <label>{isEditing ? 'استبدال فيديو لغة الإشارة' : 'فيديو لغة الإشارة'}</label>
      <input
        type="file"
        accept="video/mp4,video/webm,video/quicktime"
        onChange={(e) => onSignLanguageChange(e.target.files?.[0] || null)}
      />

      <label>الوصف الصوتي</label>
      <textarea
        value={audioDescription}
        onChange={(e) => onAudioDescriptionChange(e.target.value)}
        rows={3}
        placeholder="صف ما يحدث في الفيديو ليستفيد المستخدم الكفيف..."
      />

      <small style={{ display: 'block', marginTop: 8, opacity: 0.7 }}>
        الصور حتى 10MB للصورة، الصوت حتى 50MB، والفيديو حتى 150MB.
      </small>
    </>
  )
}

export function LessonModalActions({ isEditing, onClose, saving }) {
  return (
    <div className="modal-actions">
      <button type="button" className="btn outline" onClick={onClose}>إلغاء</button>
      <button type="submit" className="btn success" disabled={saving}>
        {saving ? 'جارِ الحفظ...' : isEditing ? 'حفظ التعديلات' : 'حفظ الدرس'}
      </button>
    </div>
  )
}
