<?php

namespace App\Http\Controllers;

use Illuminate\Http\Client\ConnectionException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class InstitutionCurriculumController extends Controller
{
    public function overview(Request $request, string $organizationSlug, int $school): JsonResponse
    {
        if (!$this->schoolWithinTenant($request, $school)) {
            return response()->json(['error' => 'المدرسة غير موجودة'], 404);
        }

        $books = DB::table('curriculum_books as b')
            ->join('grades as g', 'g.id', '=', 'b.grade_id')
            ->join('subjects as s', 's.id', '=', 'b.subject_id')
            ->where('b.school_id', $school)
            ->select('b.*', 'g.name as grade_name', 's.name as subject_name')
            ->orderBy('g.level')
            ->orderBy('s.name')
            ->get();

        return response()->json(['books' => $books]);
    }

    public function storeBook(Request $request, string $organizationSlug, int $school): JsonResponse
    {
        if (!$this->schoolWithinTenant($request, $school)) {
            return response()->json(['error' => 'المدرسة غير موجودة'], 404);
        }

        $data = $request->validate([
            'academic_year_id' => ['nullable', 'integer'],
            'grade_id' => ['required', 'integer'],
            'subject_id' => ['required', 'integer'],
            'title' => ['required', 'string', 'max:200'],
            'semester' => ['nullable', 'string', 'max:40'],
            'edition' => ['nullable', 'string', 'max:80'],
            'source_name' => ['nullable', 'string', 'max:160'],
            'source_url' => ['nullable', 'url', 'max:2048'],
            'storage_path' => ['nullable', 'string', 'max:1024'],
            'status' => ['nullable', 'in:draft,verified,archived'],
        ]);

        if (!DB::table('grades')->where('id', $data['grade_id'])->where('school_id', $school)->exists()) {
            return response()->json(['error' => 'الصف لا يتبع هذه المدرسة'], 422);
        }
        if (!DB::table('subjects')->where('id', $data['subject_id'])->where('school_id', $school)->exists()) {
            return response()->json(['error' => 'المادة لا تتبع هذه المدرسة'], 422);
        }
        if (!empty($data['academic_year_id']) && !DB::table('academic_years')->where('id', $data['academic_year_id'])->where('school_id', $school)->exists()) {
            return response()->json(['error' => 'السنة الدراسية لا تتبع هذه المدرسة'], 422);
        }

        $id = DB::table('curriculum_books')->insertGetId([
            'school_id' => $school,
            'academic_year_id' => $data['academic_year_id'] ?? null,
            'grade_id' => $data['grade_id'],
            'subject_id' => $data['subject_id'],
            'title' => $data['title'],
            'semester' => $data['semester'] ?? null,
            'edition' => $data['edition'] ?? null,
            'source_name' => $data['source_name'] ?? null,
            'source_url' => $data['source_url'] ?? null,
            'storage_path' => $data['storage_path'] ?? null,
            'status' => $data['status'] ?? 'draft',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return response()->json(['book' => DB::table('curriculum_books')->find($id)], 201);
    }

    public function storeUnit(Request $request, string $organizationSlug, int $school, int $book): JsonResponse
    {
        if (!$this->bookWithinSchool($request, $school, $book)) {
            return response()->json(['error' => 'الكتاب غير موجود'], 404);
        }

        $data = $request->validate([
            'title' => ['required', 'string', 'max:200'],
            'position' => ['required', 'integer', 'min:1', 'max:500'],
        ]);

        $id = DB::table('curriculum_units')->insertGetId([
            'curriculum_book_id' => $book,
            'title' => $data['title'],
            'position' => $data['position'],
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return response()->json(['unit' => DB::table('curriculum_units')->find($id)], 201);
    }

    public function storeLesson(Request $request, string $organizationSlug, int $school, int $unit): JsonResponse
    {
        if (!$this->unitWithinSchool($request, $school, $unit)) {
            return response()->json(['error' => 'الوحدة غير موجودة'], 404);
        }

        $data = $request->validate([
            'title' => ['required', 'string', 'max:200'],
            'position' => ['required', 'integer', 'min:1', 'max:500'],
            'source_pages' => ['nullable', 'string', 'max:80'],
            'content_text' => ['nullable', 'string', 'max:50000'],
            'metadata' => ['nullable', 'array'],
        ]);

        $id = DB::table('curriculum_lessons')->insertGetId([
            'curriculum_unit_id' => $unit,
            'title' => $data['title'],
            'position' => $data['position'],
            'source_pages' => $data['source_pages'] ?? null,
            'content_text' => $data['content_text'] ?? null,
            'metadata' => json_encode($data['metadata'] ?? [], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return response()->json(['lesson' => DB::table('curriculum_lessons')->find($id)], 201);
    }

    public function showLesson(Request $request, string $organizationSlug, int $school, int $lesson): JsonResponse
    {
        $row = $this->lessonWithinSchool($request, $school, $lesson);
        if (!$row) {
            return response()->json(['error' => 'الدرس غير موجود'], 404);
        }

        return response()->json(['lesson' => $row]);
    }

    public function generateNoorPlan(Request $request, string $organizationSlug, int $school, int $lesson): JsonResponse
    {
        $lessonRow = $this->lessonWithinSchool($request, $school, $lesson);
        if (!$lessonRow) {
            return response()->json(['error' => 'الدرس غير موجود'], 404);
        }
        if (!trim((string) $lessonRow->content_text)) {
            return response()->json(['error' => 'يجب إضافة نص الدرس المعتمد قبل استخدام نور'], 422);
        }

        $apiKey = config('services.groq.key');
        if (!$apiKey) {
            return response()->json(['error' => 'مساعد نور غير مفعّل على الخادم بعد.'], 503);
        }

        $data = $request->validate([
            'focus' => ['nullable', 'string', 'max:1000'],
        ]);

        $system = <<<'PROMPT'
أنت نور، مساعد تعليمي للمعلمين في EduBridge. اعمل حصراً من نص الدرس المرفق ولا تضف حقائق تعليمية غير مدعومة به. المطلوب إعداد نسخة مناسبة للتعليم البصري للطلاب الصم وضعاف السمع. لا تخترع إشارات لغة إشارة. إذا احتاج مفهوم إلى إشارة فاكتب الكلمة المفتاحية فقط ليتم ربطها لاحقاً بقاموس PSL الموثق. أعد JSON صالحاً فقط بالمفاتيح التالية: objectives, simplified_explanation, key_concepts, visual_sequence, sign_keywords, classroom_activity, assessment_questions, worksheet_items, parent_summary, source_note. يجب أن تكون القيم باللغة العربية وأن تبقى الدقة العلمية محفوظة. لا تنشر المحتوى للطلاب؛ الناتج مسودة تحتاج مراجعة معلم.
PROMPT;

        $source = "عنوان الدرس: {$lessonRow->title}\n";
        if ($lessonRow->source_pages) $source .= "الصفحات: {$lessonRow->source_pages}\n";
        if (!empty($data['focus'])) $source .= "تركيز المعلم: {$data['focus']}\n";
        $source .= "\nنص الدرس المعتمد:\n{$lessonRow->content_text}";

        try {
            $response = Http::withToken($apiKey)
                ->acceptJson()
                ->timeout(45)
                ->post('https://api.groq.com/openai/v1/chat/completions', [
                    'model' => config('services.groq.model'),
                    'messages' => [
                        ['role' => 'system', 'content' => $system],
                        ['role' => 'user', 'content' => $source],
                    ],
                    'response_format' => ['type' => 'json_object'],
                    'max_completion_tokens' => 1800,
                ]);
        } catch (ConnectionException $e) {
            report($e);
            return response()->json(['error' => 'تعذر الاتصال بنور الآن.'], 502);
        }

        if (!$response->successful()) {
            Log::warning('Noor teacher generation failed', ['status' => $response->status()]);
            return response()->json(['error' => $response->status() === 429 ? 'نور مشغول قليلاً. حاول لاحقاً.' : 'تعذر إنشاء خطة الدرس الآن.'], $response->status() === 429 ? 429 : 502);
        }

        $content = data_get($response->json(), 'choices.0.message.content');
        $output = is_string($content) ? json_decode($content, true) : null;
        if (!is_array($output)) {
            return response()->json(['error' => 'وصل رد غير مكتمل من نور.'], 502);
        }

        $actor = $request->attributes->get('jwt_user');
        $generationId = DB::table('noor_lesson_generations')->insertGetId([
            'school_id' => $school,
            'curriculum_lesson_id' => $lesson,
            'requested_by' => $actor->id,
            'generation_type' => 'visual_lesson_plan',
            'output' => json_encode($output, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
            'status' => 'draft',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return response()->json([
            'generation' => [
                'id' => $generationId,
                'status' => 'draft',
                'requires_teacher_review' => true,
                'output' => $output,
            ],
        ], 201);
    }

    public function approveGeneration(Request $request, string $organizationSlug, int $school, int $generation): JsonResponse
    {
        if (!$this->schoolWithinTenant($request, $school)) {
            return response()->json(['error' => 'المدرسة غير موجودة'], 404);
        }

        $row = DB::table('noor_lesson_generations')->where('id', $generation)->where('school_id', $school)->first();
        if (!$row) {
            return response()->json(['error' => 'المسودة غير موجودة'], 404);
        }

        $actor = $request->attributes->get('jwt_user');
        if (!$actor) {
            return response()->json(['error' => 'غير مصرح'], 403);
        }

        $organization = $request->attributes->get('organization');
        $membership = DB::table('organization_user')
            ->where('organization_id', $organization->id)
            ->where('user_id', $actor->id)
            ->where('is_active', true)
            ->first();
        if (!$membership || !in_array($membership->role, ['owner', 'admin', 'school_admin', 'teacher'], true)) {
            return response()->json(['error' => 'ليس لديك صلاحية اعتماد المسودة'], 403);
        }
        // Teachers may approve only their own generations. Institution admins
        // retain the existing ability to review other teachers' drafts.
        if ($membership->role === 'teacher' && (int) $row->requested_by !== (int) $actor->id) {
            return response()->json(['error' => 'لا يمكنك اعتماد مسودة معلم آخر'], 403);
        }
        if ($row->status !== 'draft') {
            return response()->json(['error' => 'المسودة ليست قيد المراجعة'], 409);
        }

        DB::table('noor_lesson_generations')->where('id', $generation)->where('school_id', $school)->where('status', 'draft')->update([
            'status' => 'approved',
            'approved_by' => $actor->id,
            'approved_at' => now(),
            'updated_at' => now(),
        ]);

        return response()->json(['message' => 'تم اعتماد مسودة نور', 'generation_id' => $generation]);
    }

    private function schoolWithinTenant(Request $request, int $school): ?object
    {
        $organization = $request->attributes->get('organization');
        return DB::table('schools')->where('id', $school)->where('organization_id', $organization->id)->first();
    }

    private function bookWithinSchool(Request $request, int $school, int $book): ?object
    {
        if (!$this->schoolWithinTenant($request, $school)) return null;
        return DB::table('curriculum_books')->where('id', $book)->where('school_id', $school)->first();
    }

    private function unitWithinSchool(Request $request, int $school, int $unit): ?object
    {
        if (!$this->schoolWithinTenant($request, $school)) return null;
        return DB::table('curriculum_units as u')
            ->join('curriculum_books as b', 'b.id', '=', 'u.curriculum_book_id')
            ->where('u.id', $unit)->where('b.school_id', $school)
            ->select('u.*')->first();
    }

    private function lessonWithinSchool(Request $request, int $school, int $lesson): ?object
    {
        if (!$this->schoolWithinTenant($request, $school)) return null;
        return DB::table('curriculum_lessons as l')
            ->join('curriculum_units as u', 'u.id', '=', 'l.curriculum_unit_id')
            ->join('curriculum_books as b', 'b.id', '=', 'u.curriculum_book_id')
            ->join('grades as g', 'g.id', '=', 'b.grade_id')
            ->join('subjects as s', 's.id', '=', 'b.subject_id')
            ->where('l.id', $lesson)->where('b.school_id', $school)
            ->select('l.*', 'b.title as book_title', 'b.source_name', 'g.name as grade_name', 's.name as subject_name')
            ->first();
    }
}
