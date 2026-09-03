<?php

namespace App\Http\Controllers;

// البحث برقم الهوية (البطاقة 2)
// بحث سريع عن طالب/ولي أمر/موظف برقم الهوية الكامل أو الجزئي مع حالة التوثيق.
// الصلاحيات محكومة: الموظفون فقط (معلّم/مختص/أدمن/وزارة/مؤسسة).
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SearchController extends Controller
{
    // GET /api/search/national-id?q=123
    public function byNationalId(Request $request)
    {
        $q = trim((string) $request->query('q'));
        if ($q === '' || strlen($q) < 2) {
            return response()->json(['error' => 'أدخل رقم هوية (حرفان على الأقل)'], 400);
        }

        $like = '%' . $q . '%';

        try {
            // المستخدمون (موظفون وأولياء أمور) — برقم الهوية
            $users = DB::table('users')
                ->select('id', 'name', 'email', 'role', 'national_id', 'verification_status')
                ->where('national_id', 'like', $like)
                ->orderBy('name')
                ->limit(20)
                ->get()
                ->map(fn ($u) => [
                    'kind' => 'user',
                    'id' => $u->id,
                    'name' => $u->name,
                    'role' => $u->role,
                    'email' => $u->email,
                    'national_id' => $u->national_id,
                    'verification_status' => $u->verification_status,
                ]);

            // الأطفال — برقم هوية الطفل أو رقم هوية ولي الأمر
            $children = DB::table('children')
                ->select('id', 'name', 'child_national_id', 'guardian_national_id', 'doc_verification_status')
                ->where('child_national_id', 'like', $like)
                ->orWhere('guardian_national_id', 'like', $like)
                ->orderBy('name')
                ->limit(20)
                ->get()
                ->map(fn ($c) => [
                    'kind' => 'child',
                    'id' => $c->id,
                    'name' => $c->name,
                    'national_id' => $c->child_national_id,
                    'guardian_national_id' => $c->guardian_national_id,
                    'verification_status' => $c->doc_verification_status,
                ]);

            return response()->json([
                'results' => $users->concat($children)->values(),
            ]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
