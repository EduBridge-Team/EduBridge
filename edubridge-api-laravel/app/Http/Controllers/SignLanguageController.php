<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SignLanguageController extends Controller
{
    public function language()
    {
        $language = DB::table('sign_languages')->where('code', 'psl')->first();

        if (!$language) {
            return response()->json(['error' => 'لغة الإشارة غير متاحة'], 404);
        }

        $counts = DB::table('sign_entries')
            ->where('sign_language_id', $language->id)
            ->where('review_status', 'verified')
            ->selectRaw('category, COUNT(*) as total')
            ->groupBy('category')
            ->orderBy('category')
            ->get();

        return response()->json([
            'language' => [
                'code' => $language->code,
                'name_ar' => $language->name_ar,
                'name_en' => $language->name_en,
                'region' => $language->region,
                'source_name' => $language->source_name,
                'source_url' => $language->source_url,
                'license' => $language->license,
                'media_available' => false,
            ],
            'categories' => $counts,
            'verified_signs' => (int) $counts->sum('total'),
        ]);
    }

    public function categories()
    {
        $languageId = DB::table('sign_languages')->where('code', 'psl')->value('id');

        $categories = DB::table('sign_entries')
            ->where('sign_language_id', $languageId)
            ->where('review_status', 'verified')
            ->selectRaw('category, COUNT(*) as total')
            ->groupBy('category')
            ->orderBy('category')
            ->get();

        return response()->json(['categories' => $categories]);
    }

    public function index(Request $request)
    {
        $languageId = DB::table('sign_languages')->where('code', 'psl')->value('id');
        if (!$languageId) {
            return response()->json(['signs' => [], 'pagination' => ['page' => 1, 'per_page' => 30, 'total' => 0, 'last_page' => 1]]);
        }

        $query = DB::table('sign_entries')
            ->where('sign_language_id', $languageId);

        $user = $request->attributes->get('jwt_user');
        $isAdmin = is_object($user) && (($user->role ?? null) === 'admin');
        if (!$isAdmin || !$request->boolean('include_review')) {
            $query->where('review_status', 'verified');
        }

        if ($category = trim((string) $request->query('category', ''))) {
            $query->where('category', $category);
        }

        if ($q = trim((string) $request->query('q', ''))) {
            $englishNeedle = '%'.strtolower($q).'%';
            $needle = '%'.$q.'%';
            $query->where(function ($builder) use ($englishNeedle, $needle) {
                $builder->whereRaw('LOWER(english_label) LIKE ?', [$englishNeedle])
                    ->orWhere('arabic_label', 'like', $needle)
                    ->orWhere('canonical_label', 'like', $needle);
            });
        }

        $perPage = max(1, min((int) $request->query('per_page', 30), 100));
        $page = max(1, (int) $request->query('page', 1));
        $total = (clone $query)->count();
        $lastPage = max(1, (int) ceil($total / $perPage));

        $signs = $query
            ->orderBy('category')
            ->orderBy('external_label_id')
            ->forPage($page, $perPage)
            ->get($this->fields());

        return response()->json([
            'signs' => $signs,
            'pagination' => [
                'page' => $page,
                'per_page' => $perPage,
                'total' => $total,
                'last_page' => $lastPage,
            ],
        ]);
    }

    public function show(Request $request, int $id)
    {
        $languageId = DB::table('sign_languages')->where('code', 'psl')->value('id');
        $query = DB::table('sign_entries')
            ->where('sign_language_id', $languageId)
            ->where('id', $id);

        $user = $request->attributes->get('jwt_user');
        $isAdmin = is_object($user) && (($user->role ?? null) === 'admin');
        if (!$isAdmin || !$request->boolean('include_review')) {
            $query->where('review_status', 'verified');
        }

        $sign = $query->first($this->fields());

        if (!$sign) {
            return response()->json(['error' => 'الإشارة غير موجودة'], 404);
        }

        return response()->json(['sign' => $sign]);
    }

    private function fields(): array
    {
        return [
            'id',
            'external_label_id',
            'category',
            'arabic_label',
            'english_label',
            'canonical_label',
            'media_url',
            'thumbnail_url',
            'duration_ms',
            'review_status',
        ];
    }
}
