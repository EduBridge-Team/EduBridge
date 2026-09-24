<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait ConsultationNoteActions
{
    public function addNote(Request $request, $id)
    {
        $user = $request->attributes->get('jwt_user');

        $content = trim((string) $request->input('content'));
        if ($content === '') {
            return response()->json(['error' => 'الملاحظة مطلوبة'], 400);
        }

        try {
            $consultation = DB::table('consultations')->where('id', $id)->first();
            if (!$consultation) {
                return response()->json(['error' => 'الاستشارة غير موجودة'], 404);
            }
            if (
                $user->role !== 'admin'
                && (int) ($consultation->specialist_id ?? 0) !== (int) $user->id
            ) {
                return response()->json([
                    'error' => 'غير مصرّح بإضافة ملاحظة لهذه الحالة',
                ], 403);
            }

            DB::table('consultation_notes')->insert([
                'consultation_id' => $id,
                'author_id' => $user->id,
                'content' => $content,
            ]);

            Notify::toUser(
                $consultation->requester_id,
                'توصية جديدة على دراسة الحالة',
                'أضاف المختص توصية على: ' . $consultation->title,
                'consultation'
            );

            $notes = DB::table('consultation_notes as n')
                ->leftJoin('users as u', 'u.id', '=', 'n.author_id')
                ->where('n.consultation_id', $id)
                ->select('n.id', 'n.content', 'n.created_at', 'u.name as author_name')
                ->orderBy('n.created_at')
                ->get();

            return response()->json(['notes' => $notes], 201);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
