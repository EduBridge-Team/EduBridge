<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration {
    public function up(): void
    {
        if (DB::getDriverName() !== 'pgsql') return;
        DB::statement('ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check');
        DB::statement("ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (role IN ('parent','teacher','specialist','admin','ministry','institution','school','school_director','student','staff'))");
    }
    public function down(): void
    {
        if (DB::getDriverName() !== 'pgsql') return;
        if (DB::table('users')->where('role', 'school_director')->exists()) {
            throw new RuntimeException('Cannot remove school_director role with active accounts');
        }
        DB::statement('ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check');
        DB::statement("ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (role IN ('parent','teacher','specialist','admin','ministry','institution','school','student','staff'))");
    }
};
