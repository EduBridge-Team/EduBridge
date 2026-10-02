<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\UploadControllerHelpers;
use App\Support\AuthCredentials;
use App\Support\LessonFiles;
use App\Support\LessonVisibility;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class LessonFileController extends Controller
{
    use UploadControllerHelpers;

    public function show(Request $request, int $lessonId, string $filename)
    {
        $user = DB::table('users')->find((int) $request->query('viewer'));
        if (!$user || !LessonFiles::validFilename($filename)
            || $user->role !== $request->query('role')
            || ($user->role !== 'admin' && ($user->verification_status ?? null) !== 'verified')
            || !hash_equals(AuthCredentials::stamp($user, (string) config('services.jwt.secret')), (string) $request->query('credential'))
            || !LessonVisibility::allowed($user, $lessonId)) {
            return response()->json(['error' => 'غير مصرّح بعرض الملف'], 403);
        }
        if (!DB::table('media')->where('lesson_id', $lessonId)->where('url', LessonFiles::path($lessonId, $filename))->exists()) {
            return response()->json(['error' => 'الملف غير موجود'], 404);
        }
        $range = $request->header('Range');
        if ($range !== null && !preg_match('/^bytes=(?:\d+-\d*|-\d+)$/', $range)) {
            return response()->json(['error' => 'نطاق غير صالح'], 416);
        }
        return $this->streamPrivateObject("lessons/{$lessonId}/{$filename}", $range);
    }
}
