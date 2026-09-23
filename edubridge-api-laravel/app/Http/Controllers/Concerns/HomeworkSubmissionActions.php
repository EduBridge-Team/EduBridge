<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait HomeworkSubmissionActions
{
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
        if ($user->role === 'specialist' && !$this->canViewChild($user, (int) $submission->child_id)) {
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
