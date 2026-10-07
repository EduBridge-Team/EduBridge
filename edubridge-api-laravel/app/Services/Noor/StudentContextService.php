<?php

namespace App\Services\Noor;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class StudentContextService
{
    public function build(int $childId, object $user): array
    {
        abort_unless(Schema::hasTable('children'), 503, 'بيانات الطلاب غير متاحة.');
        $child = DB::table('children')->where('id', $childId)->first();
        abort_if(!$child, 404, 'الطالب غير موجود.');

        $role = (string) ($user->role ?? 'user');
        abort_unless($this->canAccessChild($childId, $user, $role, $child), 403, 'لا تملك صلاحية الوصول إلى بيانات هذا الطالب.');

        $context = [
            'child_id' => $childId,
            'role' => $role,
            'student' => $this->studentSummary($child),
            'recent_lessons' => $this->recentRows('lessons', $childId, ['id', 'title', 'category', 'status', 'created_at', 'updated_at']),
            'recent_homeworks' => $this->recentRows('homeworks', $childId, ['id', 'title', 'status', 'due_date', 'created_at', 'updated_at']),
            'recent_progress' => $this->recentRows('weekly_reports', $childId, ['id', 'summary', 'progress', 'status', 'week_start', 'week_end', 'created_at', 'updated_at']),
        ];

        if ($role === 'specialist') {
            $context['adaptations'] = $this->recentRows('adaptations', $childId, ['id', 'title', 'description', 'status', 'created_at', 'updated_at']);
        }

        $context['signals'] = $this->deriveSignals($context);

        return array_filter($context, static fn ($value) => $value !== [] && $value !== null && $value !== '');
    }

    public function toPromptContext(array $context): string
    {
        $lines = [
            'سياق الطالب من EduBridge:',
            'استخدم هذه البيانات فقط ولا تستنتج حقائق غير موجودة.',
        ];

        $student = $context['student'] ?? [];
        if (!empty($student['display_name'])) $lines[] = 'الطالب: '.$student['display_name'];
        if (!empty($student['age'])) $lines[] = 'العمر التقريبي: '.$student['age'];
        if (!empty($student['grade'])) $lines[] = 'الصف/المستوى: '.$student['grade'];

        foreach ([
            'recent_lessons' => 'الدروس الأخيرة',
            'recent_homeworks' => 'الواجبات الأخيرة',
            'recent_progress' => 'التقدم الأسبوعي الأخير',
            'adaptations' => 'التكييفات التعليمية',
            'signals' => 'إشارات المتابعة',
        ] as $key => $label) {
            $items = $context[$key] ?? [];
            if (!$items) continue;
            $lines[] = $label.':';
            foreach (array_slice($items, 0, 5) as $item) {
                $parts = [];
                foreach ((array) $item as $field => $value) {
                    if ($value === null || $value === '' || is_array($value) || is_object($value)) continue;
                    $parts[] = $field.'='.trim((string) $value);
                }
                if ($parts) $lines[] = '• '.implode('، ', $parts);
            }
        }

        return mb_substr(implode("\n", $lines), 0, 3200);
    }

    private function studentSummary(object $child): array
    {
        $age = $child->age ?? null;
        if ($age === null && !empty($child->birth_date)) {
            try {
                $age = now()->diffInYears($child->birth_date);
            } catch (\Throwable) {
                $age = null;
            }
        }

        return array_filter([
            'display_name' => isset($child->name) ? trim((string) $child->name) : null,
            'age' => $age,
            'grade' => $child->grade ?? $child->grade_level ?? $child->level ?? null,
        ], static fn ($value) => $value !== null && $value !== '');
    }

    private function canAccessChild(int $childId, object $user, string $role, object $child): bool
    {
        if ($role === 'admin') return true;
        $userId = (int) ($user->id ?? 0);
        if ($userId <= 0) return false;

        if ($role === 'parent') {
            if (Schema::hasTable('child_parent') && Schema::hasColumn('child_parent', 'parent_id')) {
                if (DB::table('child_parent')->where('child_id', $childId)->where('parent_id', $userId)->exists()) return true;
            }
            if (Schema::hasColumn('children', 'parent_id') && (int) ($child->parent_id ?? 0) === $userId) return true;
        }

        if ($role === 'teacher') {
            if (Schema::hasColumn('children', 'assigned_teacher_id') && (int) ($child->assigned_teacher_id ?? 0) === $userId) return true;
            if (Schema::hasTable('child_teacher') && Schema::hasColumn('child_teacher', 'teacher_id')) {
                if (DB::table('child_teacher')->where('child_id', $childId)->where('teacher_id', $userId)->exists()) return true;
            }
        }

        if ($role === 'specialist') {
            if (Schema::hasColumn('children', 'assigned_specialist_id') && (int) ($child->assigned_specialist_id ?? 0) === $userId) return true;
            foreach (['child_specialist', 'child_specialists'] as $table) {
                if (Schema::hasTable($table) && Schema::hasColumn($table, 'specialist_id')) {
                    if (DB::table($table)->where('child_id', $childId)->where('specialist_id', $userId)->exists()) return true;
                }
            }
        }

        if (in_array($role, ['institution', 'ministry'], true)) {
            // These roles may inspect only records already available through their own child listing scope.
            // Until that scope is centralized, do not grant broad Noor access.
            return false;
        }

        return false;
    }

    private function recentRows(string $table, int $childId, array $fields): array
    {
        if (!Schema::hasTable($table) || !Schema::hasColumn($table, 'child_id')) return [];

        $select = array_values(array_filter($fields, fn ($field) => Schema::hasColumn($table, $field)));
        if (!$select) return [];

        $query = DB::table($table)->where('child_id', $childId);
        if (Schema::hasColumn($table, 'updated_at')) $query->orderByDesc('updated_at');
        elseif (Schema::hasColumn($table, 'created_at')) $query->orderByDesc('created_at');
        elseif (Schema::hasColumn($table, 'id')) $query->orderByDesc('id');

        return $query->limit(5)->get($select)->map(fn ($row) => (array) $row)->all();
    }

    private function deriveSignals(array $context): array
    {
        $signals = [];
        $pending = collect($context['recent_homeworks'] ?? [])->filter(function ($row) {
            $status = strtolower((string) ($row['status'] ?? ''));
            return in_array($status, ['pending', 'new', 'late', 'overdue', 'معلق', 'جديد'], true);
        })->count();

        if ($pending > 0) {
            $signals[] = ['type' => 'homework_follow_up', 'message' => "يوجد {$pending} واجب/واجبات حديثة تحتاج متابعة."];
        }
        if (empty($context['recent_progress'])) {
            $signals[] = ['type' => 'missing_progress', 'message' => 'لا يوجد تقدم أسبوعي حديث ضمن السياق المتاح.'];
        }

        return $signals;
    }
}
