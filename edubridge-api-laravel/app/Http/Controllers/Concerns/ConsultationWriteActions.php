<?php

namespace App\Http\Controllers\Concerns;

use App\Support\Notify;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait ConsultationWriteActions
{
    public function store(Request $request)
    {
        $user = $request->attributes->get('jwt_user');

        $childId = $request->input('child_id');
        $title = trim((string) $request->input('title'));
        if (!$childId || $title === '') {
            return response()->json(['error' => 'معرّف الطفل وعنوان الحالة مطلوبان'], 400);
        }
        if (!$user || !in_array($user->role, ['parent', 'teacher', 'admin'], true)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        try {
            if (!DB::table('children')->where('id', $childId)->exists()) {
                return response()->json(['error' => 'الطفل غير موجود'], 404);
            }
            if (!$this->canAccessChild($user, (int) $childId)) {
                return response()->json(['error' => 'لا تملك صلاحية على هذا الطفل'], 403);
            }

            $specialistId = $request->input('specialist_id');
            if ($specialistId && $user->role !== 'admin') {
                return response()->json(['error' => 'إسناد المختص مسبقاً متاح للأدمن فقط'], 403);
            }
            if ($specialistId && !DB::table('users')->where('id', $specialistId)->where('role', 'specialist')->exists()) {
                return response()->json(['error' => 'المختص غير موجود'], 404);
            }

            $id = DB::table('consultations')->insertGetId([
                'child_id' => $childId,
                'requester_id' => $user->id,
                'specialist_id' => $specialistId ?: null,
                'title' => $title,
                'description' => $request->input('description'),
                'status' => $specialistId ? 'assigned' : 'open',
            ]);

            if ($specialistId) {
                Notify::toUser(
                    $specialistId,
                    'طلب دراسة حالة جديد',
                    'تم إسناد دراسة حالة إليك: ' . $title,
                    'consultation'
                );
            }

            return response()->json(['consultation' => DB::table('consultations')->find($id)], 201);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    public function update(Request $request, $id)
    {
        $user = $request->attributes->get('jwt_user');

        try {
            $consultation = DB::table('consultations')->where('id', $id)->first();
            if (!$consultation) {
                return response()->json(['error' => 'الاستشارة غير موجودة'], 404);
            }

            $updates = [];

            if ($user->role === 'specialist') {
                $assignedToMe = (int) ($consultation->specialist_id ?? 0) === (int) $user->id;

                if ($request->boolean('claim')) {
                    if ($consultation->specialist_id !== null || $consultation->status !== 'open') {
                        return response()->json(['error' => 'الحالة غير متاحة للاستلام'], 409);
                    }
                    $updates['specialist_id'] = $user->id;
                    $updates['status'] = 'in_progress';
                    $assignedToMe = true;
                }

                if ($request->has('status') && !$assignedToMe) {
                    return response()->json(['error' => 'غير مصرّح بتعديل هذه الحالة'], 403);
                }
            }

            if ($request->has('status')) {
                $status = $request->input('status');
                if (!in_array($status, ['open', 'assigned', 'in_progress', 'closed'], true)) {
                    return response()->json(['error' => 'الحالة غير صالحة'], 400);
                }
                $updates['status'] = $status;
            }

            if (!empty($updates)) {
                DB::table('consultations')->where('id', $id)->update($updates);
            }

            return response()->json(['consultation' => DB::table('consultations')->find($id)]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

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
            if ($user->role !== 'admin'
                && (int) ($consultation->specialist_id ?? 0) !== (int) $user->id) {
                return response()->json(['error' => 'غير مصرّح بإضافة ملاحظة لهذه الحالة'], 403);
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
