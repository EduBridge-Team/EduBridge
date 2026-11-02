<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('school_official_setup_tokens', function (Blueprint $table) {
            $table->foreignId('school_id')->primary()->constrained('schools')->cascadeOnDelete();
            $table->string('token_hash', 64);
            $table->timestamp('created_at');
        });

        if (DB::getDriverName() === 'pgsql') {
            DB::statement('ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check');
            DB::statement("ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (role IN ('parent','teacher','specialist','admin','ministry','institution','school','school_official'))");
        }
    }

    public function down(): void
    {
        if (DB::table('users')->where('role', 'school_official')->exists()) {
            throw new \RuntimeException('School official accounts exist; rollback would revoke their role.');
        }
        Schema::dropIfExists('school_official_setup_tokens');
        if (DB::getDriverName() === 'pgsql') {
            DB::statement('ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check');
            DB::statement("ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (role IN ('parent','teacher','specialist','admin','ministry','institution','school'))");
        }
    }
};
