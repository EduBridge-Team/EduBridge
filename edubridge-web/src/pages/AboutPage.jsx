// صفحة من نحن — تعريف بمشروع جسر
export default function AboutPage() {
  return (
    <div>
      <div className="page-title">
        <h2>من نحن</h2>
      </div>

      <div className="card about-card">
        <img src="/icon.png" alt="شعار جسر" width="110" height="110" />
        <h3>EduBridge — جسر تعليمي</h3>
        <p className="content">
          «EduBridge» منصة تعليمية موجّهة لأطفال ذوي الاحتياجات الخاصة، تصل بين
          المعلّمين والمختصين وأولياء الأمور في مكان واحد. تقدّم المنصة دروساً
          مصمّمة حسب نوع إعاقة كل طفل، مع متابعة تقدّمه درساً بدرس.
        </p>
        <p className="content">
          صُمّمت الواجهة بمبادئ إمكانية الوصول: أزرار كبيرة، خطوط واضحة، تباين
          لوني جيد، وقراءة صوتية لمحتوى الدروس — لأن التعليم حقّ للجميع.
        </p>
        <p className="content muted">
          المشروع جزء من تدريب ميداني جامعي، ويشمل تطبيق موبايل (Flutter)
          وواجهة ويب (React) وخادم (Node.js + PostgreSQL).
        </p>
      </div>
    </div>
  )
}
