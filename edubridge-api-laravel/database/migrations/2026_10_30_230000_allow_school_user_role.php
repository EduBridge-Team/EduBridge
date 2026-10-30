<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // The school provisioning endpoint creates users with role=school.
        // Keep all existing roles and add only the missing school role.
        DB::statement("ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check");
        DB::statement("ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (role IN ('parent', 'teacher', 'specialist', 'admin', 'ministry', 'institution', 'school'))");
    }

    public function down(): void
    {
        // Do not remove the role while any school account uses it.
        $hasSchoolUsers = DB::table('users')->where('role', 'school')->exists();
        if ($hasSchoolUsers) {
            throw new \RuntimeException('Cannot roll back school role while school users exist.');
        }
        DB::statement("ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check");
        DB::statement("ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (role IN ('parent', 'teacher', 'specialist', 'admin', 'ministry', 'institution'))");
    }
};
