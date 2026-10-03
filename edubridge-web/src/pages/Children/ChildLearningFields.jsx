export default function ChildLearningFields({ form, onChange }) {
  return (
    <>
      <label htmlFor="disability_type">نوع الإعاقة *</label>
      <input
        id="disability_type"
        value={form.disability_type}
        onChange={onChange('disability_type')}
        placeholder="مثال: إعاقة حركية، إعاقة سمعية، ..."
        required
      />

      <label htmlFor="disability_description">وصف الإعاقة *</label>
      <textarea
        id="disability_description"
        rows={3}
        value={form.disability_description}
        onChange={onChange('disability_description')}
        required
      />

      <label htmlFor="medical_history">التاريخ الطبي (اختياري)</label>
      <textarea
        id="medical_history"
        rows={3}
        value={form.medical_history}
        onChange={onChange('medical_history')}
      />

      <label htmlFor="psychologist_notes">ملاحظات مختص الدعم التعليمي (اختياري)</label>
      <textarea
        id="psychologist_notes"
        rows={3}
        value={form.psychologist_notes}
        onChange={onChange('psychologist_notes')}
      />

      <label htmlFor="special_needs">احتياجات خاصة *</label>
      <textarea
        id="special_needs"
        rows={2}
        value={form.special_needs}
        onChange={onChange('special_needs')}
        placeholder="مثال: يحتاج إلى دعم إضافي في القراءة"
        required
      />

      <label htmlFor="preferred_learning_style">أسلوب التعلم المفضل (اختياري)</label>
      <input
        id="preferred_learning_style"
        value={form.preferred_learning_style}
        onChange={onChange('preferred_learning_style')}
        placeholder="مثال: بصري، سمعي، حركي"
      />

      <label htmlFor="strengths">نقاط القوة *</label>
      <input
        id="strengths"
        value={form.strengths}
        onChange={onChange('strengths')}
        placeholder="أدخل النقاط مفصولة بفواصل، مثال: قراءة، رسم"
        required
      />

      <label htmlFor="challenges">التحديات *</label>
      <input
        id="challenges"
        value={form.challenges}
        onChange={onChange('challenges')}
        placeholder="أدخل التحديات مفصولة بفواصل، مثال: صعوبة في الكتابة"
        required
      />
    </>
  )
}
