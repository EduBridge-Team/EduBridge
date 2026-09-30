export function childAssignment(child) {
  const name = child?.assigned_teacher_name?.trim()
  const assigned = Boolean(child?.assigned_teacher_id || name)
  return {
    label: child?.status === 'evaluated' ? 'تم التقييم' : assigned ? 'تم تعيين معلّم' : 'بانتظار المتابعة',
    cls: child?.status === 'evaluated' ? 'evaluated' : assigned ? 'assigned' : 'pending',
    teacher: name || (assigned ? 'معلّم معيّن — الاسم غير متاح' : 'بانتظار التعيين'),
  }
}
