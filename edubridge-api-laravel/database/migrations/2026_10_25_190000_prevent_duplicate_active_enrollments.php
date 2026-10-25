<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // Do not silently remove or rewrite legacy student data.
        // PostgreSQL rejects this index if existing active duplicates need review.
        DB::statement("CREATE UNIQUE INDEX student_enrollments_one_active_per_child ON student_enrollments (child_id) WHERE status = 'active'");
    }

    public function down(): void
    {
        DB::statement('DROP INDEX IF EXISTS student_enrollments_one_active_per_child');
    }
};
