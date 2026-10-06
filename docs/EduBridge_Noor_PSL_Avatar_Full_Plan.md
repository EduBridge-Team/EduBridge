# EduBridge Noor Avatar — الخطة الكاملة لتعليم لغة الإشارة الفلسطينية (PSL)

## 1. الهدف

الهدف هو تحويل شخصية Noor ثلاثية الأبعاد إلى Avatar قادر على أداء إشارات لغة الإشارة الفلسطينية (PSL) بشكل مفهوم، قابل للتوسع، ومناسب للاستخدام داخل EduBridge على الويب وتطبيق Flutter.

الفكرة الأساسية ليست "تدريب الـ3D model" مثل نموذج ذكاء اصطناعي، بل بناء **منظومة حركات وإشارات** منظمة، ثم ربطها بالـRig الخاص بالشخصية.

المسار المستهدف:

```text
Arabic / English / Noor response
        ↓
PSL linguistic representation
        ↓
PSL gloss sequence
        ↓
Animation resolver
        ↓
Noor animation clips
        ↓
Web / Flutter / GLB playback
```

## 2. المكونات الرئيسية للنظام

### 2.1 Noor 3D Avatar

يجب أن تكون الشخصية جاهزة من ناحية:
- Mesh نظيف
- Rig كامل للجسم
- Rig تفصيلي لليدين والأصابع
- Wrist / elbow / shoulder deformation جيد
- Face rig أو Shape Keys للتعبيرات
- Scale ثابت
- Export نظيف بصيغة GLB

### 2.2 PSL Sign Dictionary

لكل إشارة سجل مستقل يحتوي على:
- id
- gloss
- arabic_label
- english_label
- dominant_hand
- duration
- handshape_start
- handshape_end
- facial_expression
- body_orientation
- animation_file
- validated
- notes

مثال:

```json
{
  "id": "psl_triangle",
  "language": "PSL",
  "gloss": "TRIANGLE",
  "arabic_label": "مثلث",
  "english_label": "Triangle",
  "duration": 2.1,
  "dominant_hand": "right",
  "handshape_start": "open",
  "handshape_end": "triangle",
  "facial_expression": "neutral",
  "body_orientation": "front",
  "animation_file": "psl_triangle.glb",
  "validated": true
}
```

## 3. المرحلة الأولى — تجهيز Noor للـRigging

### المطلوب
- تثبيت أفضل نسخة نهائية من الـAvatar
- تنظيف الـTopology
- حذف أو إخفاء التجارب القديمة
- ضبط Body / Head / Hair / Clothes / Eyes / Hands
- وضع الشخصية في A-Pose نظيفة
- ضبط الطول على ~1.68 m
- Center على Origin
- Apply transforms عند الحاجة

### معايير النجاح
- لا يوجد clipping واضح
- الأصابع منفصلة
- اليد مفتوحة بشكل طبيعي
- الكتفين والكوعين والرسغين قابلين للتحريك
- الملابس لا تنهار مع الحركة

## 4. المرحلة الثانية — بناء الـRig

### Body Rig
- Root
- Pelvis
- Spine
- Chest
- Neck
- Head
- Clavicle L/R
- Upper Arm L/R
- Forearm L/R
- Hand L/R
- Thigh L/R
- Shin L/R
- Foot L/R

### Hand Rig
لكل يد:
- Wrist
- Thumb: metacarpal / proximal / distal
- Index: MCP / PIP / DIP
- Middle: MCP / PIP / DIP
- Ring: MCP / PIP / DIP
- Pinky: MCP / PIP / DIP

الهدف: كل إصبع يتحرك بشكل مستقل لأن شكل اليد عنصر أساسي في PSL.

## 5. المرحلة الثالثة — Face Rig

يجب دعم تعبيرات على الأقل:
- Neutral
- Smile
- Question
- Confirmation
- Negation
- Focus
- Blink
- Mouth open
- Speaking
- Eyebrow raise
- Eyebrow lower

يمكن تنفيذها عبر Shape Keys أو Face Bones أو Hybrid Rig.

## 6. المرحلة الرابعة — تصوير إشارات PSL

### مواصفات الفيديو
- 30 أو 60 FPS
- إضاءة واضحة
- خلفية بسيطة
- الجسم من الخصر وفوق ظاهر على الأقل
- اليدان لا تخرجان من الكادر
- الوجه واضح
- لا يوجد Motion Blur قوي

### لكل إشارة نسجل
- البداية
- الحركة
- الوضع النهائي
- تعبير الوجه
- اتجاه الجسم
- اتجاه الرأس
- اليد المسيطرة

يفضل Front، وإذا احتجنا عمق أفضل: Front + Side أو كاميرتين.

## 7. المرحلة الخامسة — استخراج الحركة

```text
PSL Video
   ↓
Pose Detection
   ↓
Left Hand Tracking
   ↓
Right Hand Tracking
   ↓
Face / Head Tracking
   ↓
3D landmarks
   ↓
Filtering
   ↓
Retargeting
```

أدوات مقترحة:
- MediaPipe Pose
- MediaPipe Hands
- MediaPipe Holistic

### البيانات المطلوبة
Body:
- shoulders
- elbows
- wrists
- neck
- head
- torso orientation

Hands:
- 21 landmark لكل يد على الأقل

Face:
- head rotation
- eyebrows
- mouth
- basic expression classification

## 8. المرحلة السادسة — تنظيف Motion Data

بعد استخراج الـlandmarks:
- إزالة jitter
- smoothing
- interpolation للفريمات الناقصة
- normalization
- temporal filtering
- confidence filtering

مرشحات ممكنة:
- Moving Average
- One Euro Filter
- Savitzky-Golay
- Kalman Filter

ويجب الاحتفاظ بـ:
- raw capture
- cleaned capture
- final validated motion

## 9. المرحلة السابعة — Retargeting إلى Noor

نحتاج Bone Mapping ثابت.

مثال:

```text
pose.left_shoulder  → upper_arm.L
pose.left_elbow     → forearm.L
pose.left_wrist     → hand.L

hand.index_mcp      → index_01.L
hand.index_pip      → index_02.L
hand.index_dip      → index_03.L
```

لكل فريم نحول landmarks إلى:
- Bone rotation
- Local rotation
- Finger bend
- Wrist orientation
- Arm direction

مهم: لا نعتمد على Position فقط؛ يجب حساب Rotation لكل عظمة.

## 10. المرحلة الثامنة — Manual Correction داخل Blender

بعد كل حركة:
- راجع fingers
- wrists
- elbows
- shoulders
- facial expression
- أصلح Keyframes يدويًا إذا لزم

هذه المرحلة مهمة خصوصًا للإشارات التي تعتمد على شكل الأصابع.

## 11. المرحلة التاسعة — أول Proof of Concept

لا نبدأ بمئات الإشارات. نختار إشارة واحدة مثل:
- One
- Triangle
- Book
- Hello
- Thank you

المسار:

```text
Recorded Sign
    ↓
Motion Extraction
    ↓
Cleanup
    ↓
Retarget
    ↓
Manual Fix
    ↓
Blender Animation
    ↓
GLB Export
    ↓
Playback in EduBridge
```

إذا نجحت حركة واحدة، نكون أثبتنا الـPipeline كامل.

## 12. المرحلة العاشرة — بناء مكتبة أولية

- Batch 1: 10 إشارات
- Batch 2: 50 إشارة
- Batch 3: 100 إشارة
- Batch 4: قاموس PSL أكبر

الأولوية لإشارات EduBridge التعليمية:
- الأرقام
- الألوان
- الأشكال
- العمليات الحسابية
- المدرسة
- الكتب
- العائلة
- المشاعر
- الأسئلة
- التعليمات الصفية

## 13. المرحلة الحادية عشرة — الانتقالات بين الإشارات

```text
IDLE
 ↓
SIGN_A
 ↓
TRANSITION
 ↓
SIGN_B
 ↓
IDLE
```

نحتاج:
- Neutral Pose
- Transition clips
- Blend In / Blend Out
- Hand reset
- Arm reset

## 14. المرحلة الثانية عشرة — ترجمة النص إلى PSL

لا نعتمد دائمًا ترجمة حرفية كلمة بكلمة.

```text
Arabic / English
        ↓
Meaning / intent
        ↓
PSL linguistic representation
        ↓
Gloss sequence
        ↓
Animation sequence
```

## 15. المرحلة الثالثة عشرة — PSL Gloss Layer

مثال:

```text
النص:
هذا مثلث

PSL gloss:
THIS TRIANGLE
```

ثم:
- THIS → psl_this.glb
- TRIANGLE → psl_triangle.glb

## 16. المرحلة الرابعة عشرة — Animation Resolver

مسؤول عن:
- جلب animation clip
- ترتيب الـclips
- transitions
- speed adjustment
- facial expression
- dominant hand handling
- blending

مثال:

```json
{
  "sequence": [
    {"gloss": "THIS", "clip": "psl_this", "speed": 1.0},
    {"gloss": "TRIANGLE", "clip": "psl_triangle", "speed": 1.0}
  ]
}
```

## 17. المرحلة الخامسة عشرة — دمج Noor مع EduBridge

### Web
- Three.js
- React Three Fiber
- Babylon.js

### Flutter
- native GLB renderer
- WebView + Three.js
- custom 3D integration

### المطلوب
- تحميل Avatar مرة واحدة
- animations حسب الحاجة
- speed control
- play / pause / replay
- camera control
- front / side view
- close hand view

## 18. المرحلة السادسة عشرة — الربط مع Noor AI

```text
User asks Noor
      ↓
Noor generates educational response
      ↓
PSL translation service
      ↓
Gloss sequence
      ↓
Animation resolver
      ↓
Avatar performs signs
```

يمكن دعم Text + Audio + PSL Avatar بالتوازي.

## 19. المرحلة السابعة عشرة — QA للإشارات

### Technical QA
- لا clipping
- bones صحيحة
- fps ثابت
- لا jitter
- export يعمل

### Linguistic QA
- handshape صحيح
- direction صحيح
- motion صحيح
- facial expression مناسب

### Accessibility QA
- واضحة بصريًا
- السرعة مناسبة
- اليدان واضحتان
- الكاميرا لا تقطع الحركة

## 20. المرحلة الثامنة عشرة — Validation من مختص PSL

الحالات:
```text
draft
captured
retargeted
reviewed
validated
production
```

## 21. المرحلة التاسعة عشرة — قاعدة البيانات

### sign_languages
```text
id
code
name
region
```

### sign_entries
```text
id
sign_language_id
gloss
arabic_label
english_label
category
dominant_hand
duration
validated
```

### sign_animations
```text
id
sign_entry_id
version
glb_path
fps
duration
rig_version
validated
```

### sign_variants
```text
id
sign_entry_id
variant_name
region
notes
```

## 22. المرحلة العشرون — Versioning

نحتاج version لكل:
- Avatar
- Rig
- Animation
- Sign entry
- Exporter

مثال:
```text
avatar_version = 1.0
rig_version = 1.0
animation_version = 1.2
```

## 23. المرحلة الحادية والعشرون — Export Standard

يفضل GLB مع:
- mesh
- skeleton
- materials
- animation clips
- textures

Naming ثابت:
```text
Noor
Armature
hand.L
hand.R
index_01.L
index_02.L
...
```

## 24. المرحلة الثانية والعشرون — Performance

للموبايل والويب:
- تقليل polygon count عند الحاجة
- ضغط textures
- texture atlas
- Draco / Meshopt إذا مناسب
- animation compression
- lazy loading
- clip caching

## 25. المرحلة الثالثة والعشرون — Automated Validation

Script يفحص كل GLB:
- skeleton names
- missing bones
- duration
- fps
- missing textures
- missing animations
- scale
- root motion
- file size

## 26. المرحلة الرابعة والعشرون — أدوات داخلية

مستقبلًا: EduBridge PSL Studio

وظائفه:
- Upload video
- Extract motion
- Preview Noor
- Adjust timing
- Approve
- Export GLB
- Save sign metadata

## 27. المرحلة الخامسة والعشرون — Dataset Management

لكل capture نخزن:
```text
source_video
raw_landmarks
cleaned_landmarks
retargeted_animation
final_animation
metadata
validation_status
```

## 28. المرحلة السادسة والعشرون — جودة البيانات

نحسب:
- pose confidence
- left hand confidence
- right hand confidence
- face confidence
- dropped frames
- occlusions

ونرفض capture ضعيف تلقائيًا.

## 29. المرحلة السابعة والعشرون — تحسين التقاط اليد

إذا MediaPipe لم يكن كافيًا:
- كاميرتين
- depth camera
- Leap Motion / Ultraleap
- gloves
- markerless multi-view reconstruction

لكن نبدأ بالفيديو العادي أولًا.

## 30. المرحلة الثامنة والعشرون — الاختبارات الأولى

### Test 1 — "واحد"
الهدف:
- finger rig
- wrist
- hand visibility

### Test 2 — "مثلث"
الهدف:
- two-hand coordination
- fingers
- timing

### Test 3 — "كتاب"
الهدف:
- symmetric hand motion

### Test 4
إشارة فيها حركة ذراع أكبر:
- shoulder/elbow validation

### Test 5
إشارة فيها facial expression:
- face rig validation

# خطة التنفيذ العملية

## Milestone 1 — Avatar Ready
- Final mesh
- Rig
- fingers
- face
- GLB export

## Milestone 2 — Single Sign PoC
- one recorded sign
- extraction
- retarget
- manual cleanup
- GLB
- playback

## Milestone 3 — 10 Signs
- repeatable pipeline
- metadata
- QA
- validation

## Milestone 4 — 50 Signs
- automation
- database
- transition system
- playback engine

## Milestone 5 — Noor Integration
- text → PSL
- gloss sequence
- animation resolver
- web/mobile integration

## Milestone 6 — Production PSL Library
- 100+ signs
- specialist validation
- analytics
- versioning
- optimized delivery

# معايير نجاح النظام النهائي

النظام يعتبر جاهزًا عندما:
- Noor تؤدي الإشارات بشكل مفهوم
- الأصابع تتحرك بدقة
- لا clipping
- الانتقالات طبيعية
- الإشارات تم التحقق منها لغويًا
- GLB يعمل على الويب والموبايل
- Noor تستطيع تنفيذ sequence من عدة إشارات
- النص يتحول إلى gloss sequence
- animations تُحل تلقائيًا
- الأداء مناسب للموبايل
- pipeline قابل لإضافة إشارات جديدة بسهولة

# الأولوية الحالية

بعد انتهاء Codex من الـAvatar:

```text
1. Freeze Avatar Mesh
2. Build Rig
3. Validate Hands/Fingers
4. Build Face Rig
5. Record ONE PSL sign
6. Extract motion
7. Retarget to Noor
8. Manual correction
9. Export GLB
10. Test inside EduBridge
```

لا نبدأ بقاموس ضخم قبل نجاح أول إشارة end-to-end.

# النتيجة المستهدفة

```text
EduBridge Noor
   +
PSL Dictionary
   +
Motion Capture Pipeline
   +
Retargeting Engine
   +
Animation Library
   +
PSL Translation Layer
   +
Web / Flutter Player
```

بحيث تستطيع Noor لاحقًا تحويل المحتوى التعليمي إلى لغة الإشارة الفلسطينية وعرضه كشخصية ثلاثية الأبعاد داخل EduBridge.
