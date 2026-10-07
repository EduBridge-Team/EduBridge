<?php

namespace App\Services\Noor;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class StudentContextService
{
    public function build(int $childId, object $user): array
    {
        $child = DB::table('children')->where('id', $childId)->first();
        abort_if(!$child, 404, 'الطالب غير موجود.');

        $role = (string) ($user->role ?? 'user');
        abort_unless($this->canAccess($childId, $child, $user, $role), 403, 'لا تملك صلاحية الوصول إلى بيانات هذا الطالب.');

        $context = [
            'child_id' => $childId,
            'role' => $role,
            'student' => $this->student($child),
            'recent_lessons' => $this->lessons($childId),
            'recent_homeworks' => $this->homeworks($childId),
            'recent_progress' => $this->progress($childId, $role),
        ];
        if ($role === 'specialist') $context['recent_sessions'] = $this->sessions($childId);
        $context['signals'] = $this->signals($context);

        return array_filter($context, static fn ($v) => $v !== [] && $v !== null && $v !== '');
    }

    public function toPromptContext(array $context): string
    {
        $lines = ['سياق الطالب من EduBridge:', 'اعتمد فقط على البيانات التالية ولا تخمّن معلومات غير موجودة.'];
        foreach ($context as $key => $value) {
            if (in_array($key, ['child_id', 'role'], true)) continue;
            if (!is_array($value) || $value === []) continue;
            $lines[] = $key.': '.json_encode($value, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        }
        return mb_substr(implode("\n", $lines), 0, 3200);
    }

    private function canAccess(int $childId, object $child, object $user, string $role): bool
    {
        if ($role === 'admin') return true;
        $id = (int) ($user->id ?? 0);
        if ($id < 1) return false;

        if ($role === 'parent' && Schema::hasTable('child_parent')) {
            return DB::table('child_parent')->where('child_id', $childId)->where('parent_id', $id)->exists();
        }
        if ($role === 'teacher') {
            if ((int) ($child->assigned_teacher_id ?? 0) === $id) return true;
            return Schema::hasTable('child_teacher') && DB::table('child_teacher')->where('child_id', $childId)->where('teacher_id', $id)->exists();
        }
        if ($role === 'specialist' && Schema::hasTable('child_specialist')) {
            return DB::table('child_specialist')->where('child_id', $childId)->where('specialist_id', $id)->exists();
        }
        return false;
    }

    private function student(object $child): array
    {
        return array_filter([
            'display_name' => $child->name ?? null,
            'age' => $child->age ?? null,
            'learning_style' => $child->preferred_learning_style ?? null,
            'strengths' => $this->jsonList($child->strengths ?? null),
            'challenges' => $this->jsonList($child->challenges ?? null),
        ], static fn ($v) => $v !== null && $v !== '' && $v !== []);
    }

    private function jsonList(mixed $value): array
    {
        if (is_array($value)) return array_values(array_filter($value));
        $decoded = is_string($value) ? json_decode($value, true) : null;
        return is_array($decoded) ? array_values(array_filter($decoded)) : [];
    }

    private function lessons(int $childId): array
    {
        if (!Schema::hasTable('progress') || !Schema::hasTable('lessons')) return [];
        return DB::table('progress')
            ->join('lessons', 'lessons.id', '=', 'progress.lesson_id')
            ->where('progress.child_id', $childId)
            ->select('lessons.id', 'lessons.title', 'progress.status', 'progress.score', 'progress.completed_at')
            ->orderByDesc('progress.id')->limit(5)->get()->map(fn ($r) => (array) $r)->all();
    }

    private function homeworks(int $childId): array
    {
        if (!Schema::hasTable('homeworks')) return [];
        $query = DB::table('homeworks')->select('id', 'title', 'subject', 'due_date', 'created_at');
        if (Schema::hasColumn('homeworks', 'assigned_child_ids')) $query->whereJsonContains('assigned_child_ids', $childId);
        elseif (Schema::hasColumn('homeworks', 'child_id')) $query->where('child_id', $childId);
        else return [];

        $items = $query->orderByDesc('due_date')->limit(5)->get()->map(fn ($r) => (array) $r)->all();
        if (!Schema::hasTable('homework_submissions')) return $items;
        foreach ($items as &$item) {
            $submission = DB::table('homework_submissions')->where('homework_id', $item['id'])->where('child_id', $childId)->first();
            $item['submission_status'] = !$submission ? 'pending' : (($submission->grade ?? null) !== null ? 'graded' : 'submitted');
            if (($submission->grade ?? null) !== null) $item['grade'] = $submission->grade;
        }
        return $items;
    }

    private function progress(int $childId, string $role): array
    {
        if (!Schema::hasTable('weekly_reports')) return [];
        $fields = ['id', 'week_start', 'week_end', 'lessons_completed', 'progress_percentage'];
        if (in_array($role, ['teacher', 'specialist', 'admin'], true)) $fields[] = 'teacher_notes';
        if (in_array($role, ['specialist', 'admin'], true)) $fields[] = 'specialist_notes';
        if (in_array($role, ['parent', 'teacher', 'specialist', 'admin'], true)) $fields[] = 'parent_notes';
        $fields = array_values(array_filter($fields, fn ($f) => Schema::hasColumn('weekly_reports', $f)));
        return DB::table('weekly_reports')->where('child_id', $childId)->orderByDesc('week_start')->limit(5)->get($fields)->map(fn ($r) => (array) $r)->all();
    }

    private function sessions(int $childId): array
    {
        if (!Schema::hasTable('sessions')) return [];
        $fields = array_values(array_filter(['id', 'scheduled_at', 'status', 'type', 'goals', 'recommendations'], fn ($f) => Schema::hasColumn('sessions', $f)));
        return DB::table('sessions')->where('child_id', $childId)->orderByDesc('scheduled_at')->limit(5)->get($fields)->map(fn ($r) => (array) $r)->all();
    }

    private function signals(array $context): array
    {
        $signals = [];
        $pending = collect($context['recent_homeworks'] ?? [])->where('submission_status', 'pending')->count();
        if ($pending) $signals[] = ['type' => 'homework_follow_up', 'message' => "يوجد {$pending} واجب/واجبات تحتاج متابعة."];
        $latest = collect($context['recent_progress'] ?? [])->first();
        if (!$latest) $signals[] = ['type' => 'missing_progress', 'message' => 'لا يوجد تقرير تقدم أسبوعي حديث.'];
        elseif (isset($latest['progress_percentage']) && (float) $latest['progress_percentage'] < 50) $signals[] = ['type' => 'low_progress', 'message' => 'آخر نسبة تقدم مسجلة أقل من 50% وتحتاج متابعة تعليمية.'];
        return $signals;
    }
}
