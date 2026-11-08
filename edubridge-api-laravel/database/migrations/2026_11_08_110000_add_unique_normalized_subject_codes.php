<?php

use App\Support\SubjectCode;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

return new class extends Migration
{
    public function up(): void
    {
        // Normalize the real code column at the database layer. A separate
        // writable code_normalized column can silently drift from code when
        // imports, maintenance scripts or other writers skip that column.
        $normalizedSql = SubjectCode::normalizedSql();

        // Preflight before DDL: never silently choose a winner for legacy duplicates.
        // Evaluate the same SQL expression used by the unique index so the
        // preflight sees exactly the collisions that the database would see.
        $seen = [];
        $conflicts = [];
        DB::table('subjects')->whereNotNull('code')->orderBy('id')
            ->get(['id', 'school_id', DB::raw($normalizedSql . ' AS normalized_code')])
            ->each(function ($subject) use (&$seen, &$conflicts) {
                $normalized = $subject->normalized_code;
                if ($normalized === null) return;

                $key = $subject->school_id . ':' . $normalized;
                if (isset($seen[$key])) {
                    $conflicts[$key] ??= [$seen[$key]];
                    $conflicts[$key][] = (int) $subject->id;
                } else {
                    $seen[$key] = (int) $subject->id;
                }
            });

        if ($conflicts !== []) {
            $details = collect($conflicts)->map(fn ($ids, $key) => $key . ' (subject IDs: ' . implode(', ', $ids) . ')')->implode('; ');
            throw new RuntimeException('Cannot add unique subject codes: resolve legacy normalized duplicates first: ' . $details);
        }

        Log::info('Subject-code uniqueness migration preflight inventory', [
            'legacy_null_codes' => DB::table('subjects')->whereNull('code')->count(),
            'legacy_blank_codes' => DB::table('subjects')->whereNotNull('code')
                ->whereRaw($normalizedSql . ' IS NULL')->count(),
            'normalized_duplicate_groups' => 0,
        ]);

        // NULLIF keeps null and whitespace-only legacy codes exempt from the
        // constraint. Case/whitespace-equivalent nonblank codes are unique per
        // school even for direct SQL inserts and updates.
        DB::statement('CREATE UNIQUE INDEX subjects_school_normalized_code_unique ON subjects (school_id, (' . $normalizedSql . '))');
    }

    public function down(): void
    {
        DB::statement('DROP INDEX IF EXISTS subjects_school_normalized_code_unique');
    }
};
