const LABELS = {
  assigned: 'تم التعيين', pending: 'قيد الانتظار', accepted: 'مقبول', rejected: 'مرفوض', scheduled: 'مجدول', completed: 'مكتمل', cancelled: 'ملغى', canceled: 'ملغى',
  open: 'مفتوحة', resolved: 'محلولة', followUp: 'متابعة', follow_up: 'متابعة', initial: 'أولي', assessment: 'تقييم',
  educational: 'تعليمي', learning_support: 'دعم تعليمي', communication_support: 'تخاطب', learning_behavior: 'دعم سلوك التعلم',
  teacher: 'معلّم', specialist: 'مختص', parent: 'ولي أمر', admin: 'مدير النظام', text: 'رسالة', observation: 'ملاحظة', question: 'سؤال', decision: 'قرار',
}
export function workflowLabel(value) { return LABELS[value] || value || 'غير محدد' }
