<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait HomeworkGradeActions
{
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
