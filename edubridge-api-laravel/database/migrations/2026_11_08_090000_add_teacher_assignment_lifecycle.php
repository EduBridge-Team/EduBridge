<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('teacher_assignments', function (Blueprint $table) {
            $table->string('status', 20)->default('active');
            $table->date('starts_on')->nullable();
            $table->date('ends_on')->nullable();
        });

        // Preserve legacy assignments as active, using their recorded creation date
        // as the best available start date without inventing a different date.
        DB::table('teacher_assignments')->whereNull('starts_on')->update([
            'starts_on' => DB::raw('DATE(created_at)'),
        ]);

        Schema::table('teacher_assignments', function (Blueprint $table) {
            $table->dropUnique('teacher_assignments_section_id_subject_id_teacher_id_unique');
            $table->index(['section_id', 'subject_id', 'status'], 'teacher_assignments_active_lookup');
            $table->index(['teacher_id', 'status', 'ends_on'], 'teacher_assignments_teacher_status_end');
        });
    }

    public function down(): void
    {
        $hasRepeatedHistory = DB::table('teacher_assignments')
            ->select('section_id', 'subject_id', 'teacher_id')
            ->groupBy('section_id', 'subject_id', 'teacher_id')
            ->havingRaw('COUNT(*) > 1')->exists();

        Schema::table('teacher_assignments', function (Blueprint $table) {
            $table->dropIndex('teacher_assignments_active_lookup');
            $table->dropIndex('teacher_assignments_teacher_status_end');
            $table->dropColumn(['status', 'starts_on', 'ends_on']);
            // Do not destroy historical rows merely to restore a legacy constraint.
            if (! $hasRepeatedHistory) {
                $table->unique(['section_id', 'subject_id', 'teacher_id']);
            }
        });
    }
};
