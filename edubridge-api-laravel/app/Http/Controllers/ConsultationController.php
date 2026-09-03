<?php

namespace App\Http\Controllers;

// دراسة الحالة مع المختصين (البطاقة 7)
// ولي الأمر/المعلّم يطلب استشارة لحالة طفل؛ تُسند لمختص يسجّل ملاحظاته.
// خصوصية: لا يرى الطلب إلا صاحبه، والمختص المُسند، والأدمن، وأولياء أمر الطفل.
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Support\Notify;

class ConsultationController extends Controller
{
    // هل يحق للمستخدم الاطلاع على هذه الاستشارة؟
    private function canAccess($user, $consultation): bool
    {
        if (in_array($user->role, ['admin', 'specialist'], true)) {
            // المختص: فقط المُسند إليه أو غير المُسندة (متاحة للاستلام)
            if ($user->role === 'specialist') {
                return $consultation->specialist_id === null
                    || (int) $consultation->specialist_id === (int) $user->id;
            }
            return true; // أدمن
        }
        if ((int) $consultation->requester_id === (int) $user->id) {
            return true;
        }
        // ولي أمر الطفل
        return DB::table('child_parent')
            ->where('child_id', $consultation->child_id)
            ->where('parent_id', $user->id)
            ->exists();
    }

    // إنشاء طلب دراسة حالة
    // POST /api/consultations   body: { child_id, title, description?, specialist_id? }
    public function store(Request $request)
    {
        $user = $request->attributes->get('jwt_user');

        $childId = $request->input('child_id');
        $title = trim((string) $request->input('title'));
        if (!$childId || $title === '') {
            return response()->json(['error' => 'معرّف الطفل وعنوان الحالة مطلوبان'], 400);
        }

        try {
            if (!DB::table('children')->where('id', $childId)->exists()) {
                return response()->json(['error' => 'الطفل غير موجود'], 404);
            }

            $specialistId = $request->input('specialist_id');
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
                Notify::toUser($specialistId, 'طلب دراسة حالة جديد',
                    'تم إسناد دراسة حالة إليك: ' . $title, 'consultation');
            }

            return response()->json(['consultation' => DB::table('consultations')->find($id)], 201);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // قائمة الاستشارات المتاحة للمستخدم حسب دوره
    // GET /api/consultations
    public function index(Request $request)
    {
        $user = $request->attributes->get('jwt_user');

        try {
            $query = DB::table('consultations as k')
                ->leftJoin('children as c', 'c.id', '=', 'k.child_id')
                ->leftJoin('users as r', 'r.id', '=', 'k.requester_id')
                ->leftJoin('users as s', 's.id', '=', 'k.specialist_id')
                ->select('k.*', 'c.name as child_name',
                    'r.name as requester_name', 's.name as specialist_name')
                ->orderByDesc('k.created_at');

            if ($user->role === 'admin') {
                // الكل
            } elseif ($user->role === 'specialist') {
                // المُسندة إليه + الطلبات المفتوحة غير المُسندة
                $query->where(function ($q) use ($user) {
                    $q->where('k.specialist_id', $user->id)
                      ->orWhereNull('k.specialist_id');
                });
            } else {
                // صاحب الطلب أو ولي أمر الطفل
                $query->where(function ($q) use ($user) {
                    $q->where('k.requester_id', $user->id)
                      ->orWhereIn('k.child_id', function ($sub) use ($user) {
                          $sub->from('child_parent')
                              ->select('child_id')
                              ->where('parent_id', $user->id);
                      });
                });
            }

            return response()->json(['consultations' => $query->get()]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // تفاصيل استشارة + ملاحظات المختص
    // GET /api/consultations/:id
    public function show(Request $request, $id)
    {
        $user = $request->attributes->get('jwt_user');

        try {
            $consultation = DB::table('consultations as k')
                ->leftJoin('children as c', 'c.id', '=', 'k.child_id')
                ->leftJoin('users as r', 'r.id', '=', 'k.requester_id')
                ->leftJoin('users as s', 's.id', '=', 'k.specialist_id')
                ->where('k.id', $id)
                ->select('k.*', 'c.name as child_name',
                    'r.name as requester_name', 's.name as specialist_name')
                ->first();

            if (!$consultation) {
                return response()->json(['error' => 'الاستشارة غير موجودة'], 404);
            }
            if (!$this->canAccess($user, $consultation)) {
                return response()->json(['error' => 'غير مصرّح'], 403);
            }

            $notes = DB::table('consultation_notes as n')
                ->leftJoin('users as u', 'u.id', '=', 'n.author_id')
                ->where('n.consultation_id', $id)
                ->select('n.id', 'n.content', 'n.created_at', 'u.name as author_name')
                ->orderBy('n.created_at')
                ->get();

            return response()->json(['consultation' => $consultation, 'notes' => $notes]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    // المختص يستلم الحالة و/أو يغيّر حالتها
    // PUT /api/consultations/:id   body: { status?, claim? }   (مختص/أدمن)
    public function update(Request $request, $id)
    {
        $user = $request->attributes->get('jwt_user');

        try {
            $consultation = DB::table('consultations')->where('id', $id)->first();
            if (!$consultation) {
                return response()->json(['error' => 'الاستشارة غير موجودة'], 404);
            }

            $updates = [];

            // استلام الحالة من قِبل المختص
            if ($request->boolean('claim') && $user->role === 'specialist') {
                $updates['specialist_id'] = $user->id;
                $updates['status'] = 'in_progress';
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

    // إضافة ملاحظة/توصية من المختص على الحالة
    // POST /api/consultations/:id/notes   body: { content }   (مختص/أدمن)
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

            DB::table('consultation_notes')->insert([
                'consultation_id' => $id,
                'author_id' => $user->id,
                'content' => $content,
            ]);

            // إشعار صاحب الطلب بوجود توصية جديدة
            Notify::toUser($consultation->requester_id, 'توصية جديدة على دراسة الحالة',
                'أضاف المختص توصية على: ' . $consultation->title, 'consultation');

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
