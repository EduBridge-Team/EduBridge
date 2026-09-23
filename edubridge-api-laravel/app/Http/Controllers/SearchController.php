<?php

namespace App\Http\Controllers;

// البحث برقم الهوية (البطاقة 2)
// بحث دقيق عن طالب/ولي أمر/موظف برقم الهوية الكامل مع حالة التوثيق.
// الصلاحيات محكومة: الموظفون فقط (معلّم/مختص/أدمن/وزارة/مؤسسة).
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SearchController extends Controller
{
    // GET /api/search/national-id?q=123
    public function byNationalId(Request $request)
    {
        $q = trim((string) $request->query('q'));
        if (!preg_match('/^\d{6,20}$/', $q)) {
            return response()->json(['error' => 'أدخل رقم الهوية الكامل بالأرقام فقط'], 422);
        }

        $mask = static function (?string $value): ?string {
            if (!$value) return null;
            $length = strlen($value);
            if ($length <= 4) return str_repeat('•', $length);

            return str_repeat('•', $length - 4) . substr($value, -4);
        };

        try {
            // المستخدمون (موظفون وأولياء أمور) — برقم الهوية
            $users = DB::table('users')
                ->select('id', 'name', 'role', 'national_id', 'verification_status')
                ->where('national_id', $q)
                ->orderBy('name')
                ->limit(20)
                ->get()
                ->map(fn ($u) => [
                    'kind' => 'user',
                    'id' => $u->id,
                    'name' => $u->name,
                    'role' => $u->role,
                    'national_id' => $mask($u->national_id),
                    'verification_status' => $u->verification_status,
                ]);

            // الأطفال — برقم هوية الطفل أو رقم هوية ولي الأمر
            $children = DB::table('children')
                ->select('id', 'name', 'child_national_id', 'guardian_national_id', 'doc_verification_status')
                ->where(function ($query) use ($q) {
                    $query->where('child_national_id', $q)
                        ->orWhere('guardian_national_id', $q);
                })
                ->orderBy('name')
                ->limit(20)
                ->get()
                ->map(fn ($c) => [
                    'kind' => 'child',
                    'id' => $c->id,
                    'name' => $c->name,
                    'national_id' => $mask($c->child_national_id),
                    'guardian_national_id' => $mask($c->guardian_national_id),
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
