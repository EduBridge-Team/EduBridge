<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('school_account_activation_tokens', function (Blueprint $table) {
            $table->id();
            $table->foreignId('school_id')->unique()->constrained('schools')->restrictOnDelete();
            $table->string('token_hash', 64)->unique();
            $table->timestamp('expires_at');
            $table->timestamp('consumed_at')->nullable();
            $table->timestamps();
        });

        // Official school identity is deliberately separate from the legacy
        // school role, whose academic permissions must remain unchanged.
        if (DB::getDriverName() === 'pgsql') {
            DB::statement('ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check');
            DB::statement("ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (role IN ('parent','teacher','specialist','admin','ministry','institution','school','school_identity','student','staff'))");
        }
    }

    public function down(): void
    {
        if (DB::table('users')->where('role', 'school_identity')->exists()) {
            throw new \RuntimeException('Cannot remove official school identity support while accounts exist.');
        }
        Schema::dropIfExists('school_account_activation_tokens');
        if (DB::getDriverName() === 'pgsql') {
            DB::statement('ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check');
            DB::statement("ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (role IN ('parent','teacher','specialist','admin','ministry','institution','school','student','staff'))");
        }
    }
};
