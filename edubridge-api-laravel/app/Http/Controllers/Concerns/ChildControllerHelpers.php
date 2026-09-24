<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Support\Facades\DB;

trait ChildControllerHelpers
{
    private function validateDocumentUrl($user, ?string $url, ?string $current = null): bool
    {
        if ($url === null || $url === '') return true;
        if ($user && $user->role === 'admin') return true;
        if ($current !== null && $url === $current) return true;
        if (!$user) return false;
    
        $expectedPrefix = '/api/private-files/user/' . (int) $user->id . '/';
        return str_starts_with($url, $expectedPrefix);
    }
    
    // فكّ ترميز أعمدة JSON (نقاط القوة/التحديات) وإرجاعها كمصفوفات
    private function decodeChild($child)
    {
        if (!$child) {
            return $child;
        }
        foreach (['strengths', 'challenges'] as $key) {
            if (isset($child->$key) && is_string($child->$key)) {
                $child->$key = json_decode($child->$key, true);
            }
        }
        // لا نعيد الحقول الصحية القديمة في واجهات المنتج التعليمي.
        unset($child->medical_history, $child->psychologist_notes);
    
        // للتوافق: لو ما فيه نوع إعاقة نصّي نستعمل اسم النوع من القائمة المرجعية
        if (empty($child->disability_type) && !empty($child->disability_name)) {
            $child->disability_type = $child->disability_name;
        }
        return $child;
    }
    
    private function hideIdentityFieldsForStaff($child, $user)
    {
        if (!$child || !$user || in_array($user->role, ['admin', 'parent'], true)) {
            return $child;
        }
    
        foreach (self::IDENTITY_FIELDS as $field) {
            unset($child->$field);
        }
    
        return $child;
    }
    
    private function attachSpecialists($child)
    {
        if (!$child) {
            return $child;
        }
    
        try {
            $specialists = DB::table('child_specialist as cs')
                ->join('users as u', 'u.id', '=', 'cs.specialist_id')
                ->where('cs.child_id', $child->id)
                ->orderBy('cs.assigned_at')
                ->select(
                    'u.id',
                    'u.name',
                    'cs.specialty',
                    'cs.assigned_at'
                )
                ->get();
    
            $child->specialists = $specialists;
            $child->specialist_ids = $specialists->pluck('id')->map(fn ($id) => (int) $id)->values()->all();
            $child->assigned_specialist_ids = $child->specialist_ids;
    
            if ($specialists->isNotEmpty()) {
                $first = $specialists->first();
                $child->specialist_id = (int) $first->id;
                $child->assigned_specialist_id = (int) $first->id;
                $child->specialist_name = $first->name;
            }
        } catch (\Throwable $e) {
            report($e);
            $child->specialists = [];
            $child->specialist_ids = [];
            $child->assigned_specialist_ids = [];
        }
    
        return $child;
    }
    
    // إضافة طفل (ولي أمر / أدمن)
    // POST /api/children
}
