<?php

namespace App\Services\Noor;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\ValidationException;

class MemoryStore
{
    public function enabled(int $userId, int $childId): bool
    {
        return (bool) DB::table('noor_memory_preferences')
            ->where('user_id', $userId)->where('child_id', $childId)
            ->value('enabled');
    }

    public function setEnabled(int $userId, int $childId, bool $enabled): void
    {
        DB::transaction(function () use ($userId, $childId, $enabled) {
            DB::table('noor_memory_preferences')->updateOrInsert(
                ['user_id' => $userId, 'child_id' => $childId],
                ['enabled' => $enabled, 'consented_at' => $enabled ? now() : null, 'updated_at' => now()]
            );
            if (!$enabled) {
                DB::table('noor_memories')->where('user_id', $userId)->where('child_id', $childId)->delete();
            }
        });
    }

    public function remember(int $userId, int $childId, string $kind, string $content, ?int $retentionDays = 30): int
    {
        if (!$this->enabled($userId, $childId)) {
            throw ValidationException::withMessages(['memory' => 'يجب تفعيل الذاكرة قبل الحفظ.']);
        }
        if (!in_array($kind, ['learning_preference', 'learning_goal', 'learning_progress'], true)) {
            throw ValidationException::withMessages(['kind' => 'نوع الذاكرة غير مسموح.']);
        }
        if (mb_strlen($content) > 1000 || trim($content) === '') {
            throw ValidationException::withMessages(['content' => 'محتوى الذاكرة غير صالح.']);
        }
        if ($retentionDays === null || $retentionDays < 1 || $retentionDays > 90) {
            throw ValidationException::withMessages(['retention' => 'مدة الاحتفاظ يجب أن تكون بين يوم و90 يومًا.']);
        }
        return (int) DB::table('noor_memories')->insertGetId([
            'user_id' => $userId, 'child_id' => $childId, 'kind' => $kind,
            'content' => trim($content), 'expires_at' => now()->addDays($retentionDays),
            'created_at' => now(), 'updated_at' => now(),
        ]);
    }

    public function list(int $userId, int $childId): array
    {
        if (!$this->enabled($userId, $childId)) return [];
        return DB::table('noor_memories')->where('user_id', $userId)->where('child_id', $childId)
            ->where('expires_at', '>', now())->orderByDesc('id')->limit(50)->get()->all();
    }

    public function delete(int $userId, int $childId, int $memoryId): bool
    {
        return DB::table('noor_memories')->where('id', $memoryId)
            ->where('user_id', $userId)->where('child_id', $childId)->delete() > 0;
    }
}
