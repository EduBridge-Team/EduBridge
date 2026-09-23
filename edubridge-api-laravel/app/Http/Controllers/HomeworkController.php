<?php

namespace App\Http\Controllers;

use App\Support\Notify;
use App\Support\R2Storage;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class HomeworkController extends Controller
{
    private const ALLOWED_EXTENSIONS = ['jpg','jpeg','png','webp','pdf','mp3','m4a','wav','mp4','mov'];
    private const MAX_BYTES = 10 * 1024 * 1024;

    private function homeworkQuery()
    {
        return DB::table('homeworks as h')
            ->join('users as t', 't.id', '=', 'h.teacher_id')
            ->select('h.*', 't.name as teacher_name')
            ->orderByDesc('h.created_at');
    }

    private function normalize($row): array
    {
        $data = (array) $row;

        foreach (['assigned_child_ids', 'attachment_urls'] as $field) {
            $value = $data[$field] ?? [];
            if (is_string($value)) {
                $decoded = json_decode($value, true);
                $value = is_array($decoded) ? $decoded : [];
            }
            $data[$field] = array_values(is_array($value) ? $value : []);
        }

        $submissions = DB::table('homework_submissions as hs')
            ->join('children as c', 'c.id', '=', 'hs.child_id')
            ->where('hs.homework_id', $data['id'])
            ->orderByDesc('hs.submitted_at')
            ->select('hs.*', 'c.name as child_name')
            ->get()
            ->map(function ($s) {
                $item = (array) $s;
                $urls = $item['file_urls'] ?? [];
                if (is_string($urls)) {
                    $decoded = json_decode($urls, true);
                    $urls = is_array($decoded) ? $decoded : [];
                }
                $item['file_urls'] = array_values(is_array($urls) ? $urls : []);
                $item['file_url'] = $item['file_url'] ?? ($item['file_urls'][0] ?? null);
                $item['is_late'] = (bool) ($item['is_late'] ?? false);
                return $item;
            })
            ->values()
            ->all();

        $data['submissions'] = $submissions;
        return $data;
    }

    private function canViewChild($user, int $childId): bool
    {
        if (!$user) return false;
        if (in_array($user->role, ['specialist','admin'], true)) return true;
        if ($user->role === 'teacher') {
            return DB::table('children')
                ->where('id', $childId)
                ->where('assigned_teacher_id', $user->id)
                ->exists()
                || DB::table('child_teacher')
                    ->where('child_id', $childId)
                    ->where('teacher_id', $user->id)
                    ->exists();
        }

        return $user->role === 'parent'
            && DB::table('child_parent')
                ->where('child_id', $childId)
                ->where('parent_id', $user->id)
                ->exists();
    }

    private function storeFiles(Request $request, string $field, string $prefix): array
    {
        $files = $request->file($field, []);
        if (!is_array($files)) {
            $files = [$files];
        }

        $urls = [];
        foreach ($files as $file) {
            if (!$file || !$file->isValid()) continue;

            $ext = strtolower($file->getClientOriginalExtension());
            if (!in_array($ext, self::ALLOWED_EXTENSIONS, true)) {
                throw new \RuntimeException('صيغة ملف غير مسموحة');
            }
            if ($file->getSize() > self::MAX_BYTES) {
                throw new \RuntimeException('حجم الملف يتجاوز 10 ميغابايت');
            }

            $name = $prefix . '_' . date('Ymd_His') . '_' . bin2hex(random_bytes(5)) . '.' . $ext;
            $key = 'homework/' . $name;

            R2Storage::putUploadedFile(
                R2Storage::mediaBucket(),
                $key,
                $file,
                (string) $file->getMimeType()
            );
            $urls[] = R2Storage::mediaPublicUrl($key);
        }

        return $urls;
    }

    public function index(Request $request)
    {
        $user = $request->attributes->get('jwt_user');
        $childId = $request->filled('child_id') ? (int) $request->query('child_id') : null;

        if ($childId && !$this->canViewChild($user, $childId)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        try {
            $rows = $this->homeworkQuery()->get();

            $homeworks = $rows->filter(function ($row) use ($user, $childId) {
                $ids = $row->assigned_child_ids;
                if (is_string($ids)) {
                    $decoded = json_decode($ids, true);
                    $ids = is_array($decoded) ? $decoded : [];
                }
                $ids = array_map('intval', is_array($ids) ? $ids : []);

                if ($childId !== null) {
                    return in_array($childId, $ids, true);
                }
                if ($user->role === 'teacher') {
                    return (int) $row->teacher_id === (int) $user->id;
                }
                if ($user->role === 'parent') {
                    $owned = DB::table('child_parent')
                        ->where('parent_id', $user->id)
                        ->pluck('child_id')
                        ->map(fn ($id) => (int) $id)
                        ->all();
                    return count(array_intersect($ids, $owned)) > 0;
                }
                return true;
            })->map(fn ($row) => $this->normalize($row))->values();

            return response()->json(['homeworks' => $homeworks]);
        } catch (\Throwable $e) {
            report($e);
            return response()->json(['error' => 'تعذّر تحميل الواجبات'], 500);
        }
    }

    public function store(Request $request)
    {
        $user = $request->attributes->get('jwt_user');
        if (!$user || !in_array($user->role, ['teacher','specialist','admin'], true)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        $title = trim((string) $request->input('title', ''));
        $description = trim((string) $request->input('description', ''));
        $dueDate = trim((string) $request->input('due_date', ''));
        $subject = trim((string) $request->input('subject', ''));

        $assigned = $request->input('assigned_child_ids', []);
        if (is_string($assigned)) {
            $decoded = json_decode($assigned, true);
            $assigned = is_array($decoded) ? $decoded : [];
        }
        $assigned = array_values(array_unique(array_filter(array_map('intval', is_array($assigned) ? $assigned : []))));

        if ($title === '' || $description === '' || $dueDate === '' || !$assigned) {
            return response()->json(['error' => 'العنوان والوصف والموعد وطفل واحد على الأقل مطلوبة'], 422);
        }

        $validChildCount = DB::table('children')->whereIn('id', $assigned)->count();
        if ($validChildCount !== count($assigned)) {
            return response()->json(['error' => 'بعض الأطفال المحددين غير موجودين'], 422);
        }

        if ($user->role === 'teacher') {
            $authorizedIds = DB::table('children')
                ->whereIn('id', $assigned)
                ->where('assigned_teacher_id', $user->id)
                ->pluck('id')
                ->map(fn ($id) => (int) $id)
                ->all();
            $teamIds = DB::table('child_teacher')
                ->whereIn('child_id', $assigned)
                ->where('teacher_id', $user->id)
                ->pluck('child_id')
                ->map(fn ($id) => (int) $id)
                ->all();
            $authorizedCount = count(array_unique(array_merge($authorizedIds, $teamIds)));
            if ($authorizedCount !== count($assigned)) {
                return response()->json(['error' => 'يمكنك إسناد الواجبات فقط للأطفال المسندين إليك'], 403);
            }
        }

        try {
            $attachments = $this->storeFiles($request, 'attachments', 'assignment');

            $id = DB::table('homeworks')->insertGetId([
                'title' => $title,
                'description' => $description,
                'teacher_id' => $user->id,
                'subject' => $subject !== '' ? $subject : null,
                'due_date' => $dueDate,
                'assigned_child_ids' => json_encode($assigned),
                'attachment_urls' => json_encode($attachments),
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            foreach ($assigned as $childId) {
                Notify::toChildParents(
                    $childId,
                    'واجب جديد',
                    'تمت إضافة واجب جديد: ' . $title,
                    'homework_created'
                );
            }

            $homework = $this->homeworkQuery()->where('h.id', $id)->first();
            return response()->json(['homework' => $this->normalize($homework)], 201);
        } catch (\RuntimeException $e) {
            return response()->json(['error' => $e->getMessage()], 422);
        } catch (\Throwable $e) {
            report($e);
            return response()->json(['error' => 'تعذّر إنشاء الواجب'], 500);
        }
    }

    public function submit(Request $request, $id)
    {
        $user = $request->attributes->get('jwt_user');
        $childId = (int) $request->input('child_id');

        if ($childId <= 0 || !$this->canViewChild($user, $childId)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        $homework = DB::table('homeworks')->where('id', $id)->first();
        if (!$homework) {
            return response()->json(['error' => 'الواجب غير موجود'], 404);
        }

        $assigned = $homework->assigned_child_ids;
        if (is_string($assigned)) {
            $assigned = json_decode($assigned, true) ?: [];
        }
        if (!in_array($childId, array_map('intval', is_array($assigned) ? $assigned : []), true)) {
            return response()->json(['error' => 'الواجب غير معيّن لهذا الطفل'], 403);
        }

        $text = trim((string) $request->input('text_answer', ''));

        try {
            $files = $this->storeFiles($request, 'files', 'submission');
            if ($text === '' && !$files) {
                return response()->json(['error' => 'أضف إجابة نصية أو ملفاً واحداً على الأقل'], 422);
            }

            $due = new \DateTimeImmutable($homework->due_date);
            $isLate = now()->greaterThan($due);

            $existing = DB::table('homework_submissions')
                ->where('homework_id', $id)
                ->where('child_id', $childId)
                ->first();

            $payload = [
                'text_answer' => $text !== '' ? $text : null,
                'file_urls' => json_encode($files),
                'file_url' => $files[0] ?? null,
                'is_late' => $isLate,
                'submitted_at' => now(),
                'updated_at' => now(),
            ];

            if ($existing) {
                DB::table('homework_submissions')->where('id', $existing->id)->update($payload);
                $submissionId = $existing->id;
            } else {
                $submissionId = DB::table('homework_submissions')->insertGetId(array_merge($payload, [
                    'homework_id' => $id,
                    'child_id' => $childId,
                    'created_at' => now(),
                ]));
            }

            Notify::toUser(
                $homework->teacher_id,
                'تم تسليم واجب',
                'تم تسليم الواجب "' . $homework->title . '"',
                'homework_submitted'
            );

            $submission = DB::table('homework_submissions as hs')
                ->join('children as c', 'c.id', '=', 'hs.child_id')
                ->where('hs.id', $submissionId)
                ->select('hs.*', 'c.name as child_name')
                ->first();

            $result = (array) $submission;
            $result['file_urls'] = $files;
            $result['file_url'] = $result['file_url'] ?? ($files[0] ?? null);
            $result['is_late'] = (bool) $result['is_late'];

            return response()->json(['submission' => $result], $existing ? 200 : 201);
        } catch (\RuntimeException $e) {
            return response()->json(['error' => $e->getMessage()], 422);
        } catch (\Throwable $e) {
            report($e);
            return response()->json(['error' => 'تعذّر تسليم الواجب'], 500);
        }
    }

    public function grade(Request $request, $submissionId)
    {
        $user = $request->attributes->get('jwt_user');
        if (!$user || !in_array($user->role, ['teacher','specialist','admin'], true)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        $grade = $request->input('grade');
        if ($grade === null || !is_numeric($grade) || (int) $grade < 0 || (int) $grade > 100) {
            return response()->json(['error' => 'العلامة يجب أن تكون بين 0 و100'], 422);
        }

        $submission = DB::table('homework_submissions as hs')
            ->join('homeworks as h', 'h.id', '=', 'hs.homework_id')
            ->where('hs.id', $submissionId)
            ->select('hs.*', 'h.teacher_id', 'h.title')
            ->first();

        if (!$submission) {
            return response()->json(['error' => 'التسليم غير موجود'], 404);
        }
        if ($user->role === 'teacher' && (int) $submission->teacher_id !== (int) $user->id) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        DB::table('homework_submissions')->where('id', $submissionId)->update([
            'grade' => (int) $grade,
            'feedback' => $request->input('feedback'),
            'graded_by' => $user->id,
            'graded_at' => now(),
            'updated_at' => now(),
        ]);

        Notify::toChildParents(
            $submission->child_id,
            'تم تقييم الواجب',
            'تم تقييم الواجب "' . $submission->title . '" بدرجة ' . (int) $grade,
            'homework_graded'
        );

        return response()->json([
            'submission' => DB::table('homework_submissions')->where('id', $submissionId)->first(),
        ]);
    }
}
