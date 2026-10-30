<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // Historical appointments are unrestricted, but each school has
        // at most one current director even under concurrent writes.
        DB::statement("CREATE UNIQUE INDEX school_one_active_director_idx
            ON school_management_assignments (school_id)
            WHERE role = 'director' AND ends_at IS NULL");
    }

    public function down(): void
    {
        DB::statement('DROP INDEX IF EXISTS school_one_active_director_idx');
    }
};
