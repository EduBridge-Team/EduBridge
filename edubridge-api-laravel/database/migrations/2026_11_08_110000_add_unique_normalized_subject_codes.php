<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Preflight before DDL: never silently choose a winner for legacy duplicates.
        $seen = [];
        $conflicts = [];
        DB::table('subjects')->whereNotNull('code')->orderBy('id')->get(['id', 'school_id', 'code'])
            ->each(function ($subject) use (&$seen, &$conflicts) {
                $normalized = strtoupper(trim((string) $subject->code));
                if ($normalized === '') return;

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
            'legacy_blank_codes' => DB::table('subjects')->whereNotNull('code')->whereRaw("TRIM(code) = ''")->count(),
            'normalized_duplicate_groups' => 0,
        ]);

        Schema::table('subjects', function (Blueprint $table) {
            $table->string('code_normalized', 40)->nullable();
        });

        DB::table('subjects')->select('id', 'code')->orderBy('id')->chunkById(500, function ($subjects) {
            foreach ($subjects as $subject) {
                $code = $subject->code === null ? null : strtoupper(trim((string) $subject->code));
                DB::table('subjects')->where('id', $subject->id)->update([
                    'code_normalized' => $code === '' ? null : $code,
                ]);
            }
        });

        Schema::table('subjects', function (Blueprint $table) {
            $table->unique(['school_id', 'code_normalized'], 'subjects_school_normalized_code_unique');
        });
    }

    public function down(): void
    {
        Schema::table('subjects', function (Blueprint $table) {
            $table->dropUnique('subjects_school_normalized_code_unique');
            $table->dropColumn('code_normalized');
        });
    }
};
