<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait UploadReadActions
{
    public function showChild(Request $request, int $childId, string $filename)
    {
        $user = $request->attributes->get('jwt_user');
        $allowed = $user && (
            $user->role === 'admin'
            || (
                $user->role === 'parent'
                && DB::table('child_parent')
                    ->where('child_id', $childId)
                    ->where('parent_id', $user->id)
                    ->exists()
            )
            || (
                $user->role === 'specialist'
                && DB::table('child_specialist')
                    ->where('child_id', $childId)
                    ->where('specialist_id', $user->id)
                    ->exists()
            )
        );

        if (!$allowed) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        if (!$this->validFilename($filename)) {
            return response()->json(['error' => 'اسم ملف غير صالح'], 400);
        }

        return $this->streamPrivateObject('child-files/' . $childId . '/' . $filename);
    }

    public function show(Request $request, int $userId, string $filename)
    {
        $user = $request->attributes->get('jwt_user');
        if (!$user) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        if (!$this->validFilename($filename)) {
            return response()->json(['error' => 'اسم ملف غير صالح'], 400);
        }

        $url = '/api/private-files/user/' . $userId . '/' . $filename;
        $allowed = $user->role === 'admin' || (int) $user->id === $userId;

        // Assigned specialists may read only documents that belong to a child assigned to them.
        // The relation check prevents access before accepting the child and blocks unrelated files.
        if (!$allowed && $user->role === 'specialist') {
            $allowed = DB::table('children as c')
                ->join('child_specialist as cs', 'cs.child_id', '=', 'c.id')
                ->where('cs.specialist_id', $user->id)
                ->where(function ($query) use ($url) {
                    $query->where('c.guardian_id_document_url', $url)
                        ->orWhere('c.kinship_document_url', $url)
                        ->orWhere('c.medical_report_url', $url);
                })
                ->exists();
        }

        // A conversation attachment is readable only by a participant in that same conversation.
        if (!$allowed) {
            $allowed = DB::table('conversation_messages as cm')
                ->join('conversations as c', 'c.id', '=', 'cm.conversation_id')
                ->where('cm.file_url', $url)
                ->where(function ($query) use ($user) {
                    $query->where('c.participant_one_id', $user->id)
                        ->orWhere('c.participant_two_id', $user->id);
                })
                ->exists();
        }

        if (!$allowed) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        return $this->streamPrivateObject('user-files/' . $userId . '/' . $filename);
    }
}
