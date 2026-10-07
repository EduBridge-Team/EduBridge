import '../domain/quiz_question.dart';

/// Existing content and identifiers are retained during extraction.
class LearningQuestionBank {
  static final List<QuizQuestion> logic = List.unmodifiable([
    QuizQuestion(prompt: 'كل الطيور لها أجنحة، والعصفور طائر. ماذا نعرف؟', choices: ['للعصفور أجنحة', 'العصفور سمكة', 'لا يملك ريشاً', 'لا شيء'], correctAnswerIndex: 0),
    QuizQuestion(prompt: 'إذا كان أحمد أطول من سامر، وسامر أطول من كريم، فمن الأطول؟', choices: ['كريم', 'سامر', 'أحمد', 'متساوون'], correctAnswerIndex: 2),
    QuizQuestion(prompt: 'يوجد 3 كتب على الطاولة وأضفنا كتابين. كم أصبح العدد؟', choices: ['4', '5', '6', '3'], correctAnswerIndex: 1),
    QuizQuestion(prompt: 'إذا كانت كل المربعات أشكالاً، وهذا الشكل مربع، فما الصحيح؟', choices: ['ليس شكلاً', 'هو شكل', 'هو دائرة', 'لا نعرف'], correctAnswerIndex: 1),
    QuizQuestion(prompt: 'بدأ الدرس الساعة 9 وانتهى الساعة 10. كم استغرق؟', choices: ['ساعة', 'ساعتان', '30 دقيقة', '3 ساعات'], correctAnswerIndex: 0),
    QuizQuestion(prompt: 'ليلى أمام هدى في الصف، وهدى أمام نور. من تقف أولاً؟', choices: ['ليلى', 'هدى', 'نور', 'لا نعرف'], correctAnswerIndex: 0),
    QuizQuestion(prompt: 'أي شيء لا ينتمي إلى المجموعة: تفاحة، موزة، برتقالة، قلم؟', choices: ['تفاحة', 'موزة', 'قلم', 'برتقالة'], correctAnswerIndex: 2),
    QuizQuestion(prompt: 'كل الأسماك تعيش في الماء. السردين سمكة. أين يعيش؟', choices: ['في الماء', 'فوق الشجرة', 'في الصحراء', 'في المكتبة'], correctAnswerIndex: 0),
    QuizQuestion(prompt: 'إذا كان اليوم الثلاثاء، فما اليوم التالي؟', choices: ['الاثنين', 'الأربعاء', 'الجمعة', 'الأحد'], correctAnswerIndex: 1),
    QuizQuestion(prompt: 'أي شكل ليس له زوايا؟', choices: ['المثلث', 'المربع', 'الدائرة', 'المستطيل'], correctAnswerIndex: 2),
    for (var a = 1; a <= 9; a++)
      for (var b = 1; b <= 5; b++)
        QuizQuestion(prompt: 'يوجد $a أقلام، وأضفنا $b أقلام. كم أصبح العدد؟',
          choices: ['${a + b}', '${a + b + 1}', '${a + b + 2}', '${a + b - 1}'], correctAnswerIndex: 0),
    for (var a = 5; a <= 12; a++)
      for (var b = 1; b <= 4; b++)
        QuizQuestion(prompt: 'مع سارة $a ملصقات، أعطت صديقتها $b ملصقات. كم بقي معها؟',
          choices: ['${a - b}', '${a - b + 1}', '${a + b}', '${a - b - 1}'], correctAnswerIndex: 0),
    for (var start = 1; start <= 6; start++)
      for (var step = 1; step <= 3; step++)
        QuizQuestion(prompt: 'ما العدد التالي: $start، ${start + step}، ${start + step * 2}؟',
          choices: ['${start + step * 3}', '${start + step * 3 + 1}', '${start + step * 3 + 2}', '${start + step * 3 - 1}'], correctAnswerIndex: 0),

  ]);

  static final List<QuizQuestion> reading = List.unmodifiable([
    QuizQuestion(passage: 'ذهب سامر إلى المكتبة بعد المدرسة ليستعير كتاباً عن الفضاء. اختار كتاباً عن الكواكب وقرأ الفصل الأول في المساء.', prompt: 'لماذا ذهب سامر إلى المكتبة؟', choices: ['ليشتري لعبة', 'ليستعير كتاباً', 'ليتناول الطعام', 'ليلعب كرة القدم'], correctAnswerIndex: 1),
    QuizQuestion(passage: 'زرعت ليان بذور الطماطم في أصيص قرب النافذة، وكانت تسقيها كل صباح. بعد أيام بدأت أوراق صغيرة تظهر.', prompt: 'ما الذي ساعد البذور على النمو؟', choices: ['الماء والعناية', 'الظلام فقط', 'إهمالها', 'نقلها يومياً'], correctAnswerIndex: 0),
    QuizQuestion(passage: 'قرر الصف جمع الورق المستعمل لإعادة تدويره. وضع الطلاب صندوقاً خاصاً بجانب الباب وبدأوا بجمع الأوراق طوال الأسبوع.', prompt: 'ما هدف الصندوق؟', choices: ['جمع الألعاب', 'جمع الأوراق لإعادة التدوير', 'حفظ الطعام', 'تخزين الكتب الجديدة'], correctAnswerIndex: 1),
    QuizQuestion(passage: 'لاحظت مريم أن صديقتها نسيت قلمها، فأعارتها قلماً من حقيبتها. شكرتها صديقتها وأكملتا الدرس.', prompt: 'كيف ساعدت مريم صديقتها؟', choices: ['أعارتها قلماً', 'أخذت حقيبتها', 'أغلقت الدفتر', 'غادرت الصف'], correctAnswerIndex: 0),
    QuizQuestion(passage: 'كان الجو ممطراً صباحاً. حمل خالد مظلته وارتدى معطفه قبل الخروج إلى المدرسة، فوصل وملابسه جافة.', prompt: 'لماذا حمل خالد مظلته؟', choices: ['ليحتمي من المطر', 'ليلعب بها', 'ليحمل كتبه', 'ليحتمي من الشمس'], correctAnswerIndex: 0),
    QuizQuestion(passage: 'سمعت سلمى صوت عصفور قرب النافذة. وضعت له وعاء ماء في مكان آمن، ثم شاهدته يشرب ويطير.', prompt: 'ماذا وضعت سلمى للعصفور؟', choices: ['وعاء ماء', 'كتاباً', 'حقيبة', 'قلم رصاص'], correctAnswerIndex: 0),
    QuizQuestion(passage: 'أراد يوسف إعداد سلطة. غسل الخضار جيداً أولاً، ثم قطعها بمساعدة والده ووضعها في الطبق.', prompt: 'ماذا فعل يوسف أولاً؟', choices: ['غسل الخضار', 'أكل السلطة', 'وضع الطبق', 'قطع الخضار'], correctAnswerIndex: 0),
    QuizQuestion(passage: 'استعار رامي قصة من صديقه، وحافظ عليها نظيفة. بعد أن انتهى من قراءتها أعادها وشكر صديقه.', prompt: 'ماذا فعل رامي بعد القراءة؟', choices: ['أعاد القصة وشكر صديقه', 'مزق القصة', 'أخفى القصة', 'رسم على الصفحات'], correctAnswerIndex: 0),
    QuizQuestion(passage: 'تدرّبت هناء على ركوب الدراجة في الحديقة. ارتدت خوذتها، وساعدتها أختها حتى استطاعت السير وحدها.', prompt: 'ما الذي ارتدته هناء لحماية رأسها؟', choices: ['خوذة', 'وشاحاً', 'قفازاً', 'حذاء'], correctAnswerIndex: 0),
    QuizQuestion(passage: 'زارت العائلة البحر صباحاً. جمع الأطفال النفايات التي تركوها في كيس قبل العودة، فبقي المكان نظيفاً.', prompt: 'لماذا جمع الأطفال النفايات؟', choices: ['ليحافظوا على نظافة المكان', 'ليصنعوا لعبة', 'ليطعموا الأسماك', 'ليملؤوا البحر'], correctAnswerIndex: 0),
    QuizQuestion(passage: 'وضعت المعلمة بذرتين في أصيصين. سقت الأصيص الأول بانتظام وتركت الثاني بلا ماء. نمت النبتة الأولى.', prompt: 'أي نبتة نمت؟', choices: ['النبتة التي سُقيت', 'النبتة بلا ماء', 'لم تنم أي نبتة', 'نمت النبتتان بالتساوي'], correctAnswerIndex: 0),
    QuizQuestion(passage: 'شاهد آدم لوحة تشير إلى أن المكتبة تغلق الساعة الخامسة. وصل الساعة الرابعة، فكان لديه ساعة للقراءة.', prompt: 'كم وقتاً كان لدى آدم؟', choices: ['ساعة واحدة', 'ساعتان', 'ثلاث ساعات', 'يوم كامل'], correctAnswerIndex: 0),
  ]);
}
