<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait HomeworkAssignmentActions
{
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

        if ($user->role === 'specialist') {
            $authorizedCount = DB::table('child_specialist')
                ->whereIn('child_id', $assigned)
                ->where('specialist_id', $user->id)
                ->distinct()
                ->count('child_id');
            if ($authorizedCount !== count($assigned)) {
                return response()->json(['error' => 'يمكنك إسناد الواجبات فقط للأطفال ضمن فريقك'], 403);
            }
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
}
