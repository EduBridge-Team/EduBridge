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

        $assigned = $this->parseAssignedChildIds(
            $request->input('assigned_child_ids', [])
        );

        if ($title === '' || $description === '' || $dueDate === '' || !$assigned) {
            return response()->json(['error' => 'العنوان والوصف والموعد وطفل واحد على الأقل مطلوبة'], 422);
        }

        $assignmentError = $this->validateAssignedChildren($user, $assigned);
        if ($assignmentError) {
            return $assignmentError;
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
