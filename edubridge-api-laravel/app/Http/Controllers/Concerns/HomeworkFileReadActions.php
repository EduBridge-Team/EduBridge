<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait HomeworkFileReadActions
{
    public function file(Request $request, int $homeworkId, int $childId, string $filename)
    {
        $user = $request->attributes->get('jwt_user');
        $homework = DB::table('homeworks')->find($homeworkId);
        if (!$homework || !$user || !$this->validFilename($filename)
            || !($user->role === 'admin' || (int) $homework->teacher_id === (int) $user->id || $this->canViewChild($user, $childId))) {
            return response()->json(['error' => 'غير مصرّح بعرض الملف'], 403);
        }
        $submission = DB::table('homework_submissions')->where('homework_id', $homeworkId)->where('child_id', $childId)->first();
        $url = "/api/private-files/homework/{$homeworkId}/child/{$childId}/{$filename}";
        $urls = json_decode((string) ($submission->file_urls ?? '[]'), true) ?: [];
        if (!$submission || (!in_array($url, $urls, true) && ($submission->file_url ?? null) !== $url)) {
            return response()->json(['error' => 'الملف غير موجود'], 404);
        }
        return $this->streamPrivateObject("homework/submissions/{$homeworkId}/{$childId}/{$filename}");
    }
}
