<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('school_internal_identities', function (Blueprint $t) {
            $t->boolean('is_active')->default(true);
        });
        Schema::table('school_management_assignments', function (Blueprint $t) {
            $t->json('permissions')->nullable();
        });
        Schema::create('school_director_invitations', function (Blueprint $t) {
            $t->id();
            $t->foreignId('school_id')->constrained('schools')->restrictOnDelete();
            $t->string('email', 190);
            $t->string('token_hash', 64)->unique();
            $t->foreignId('invited_by')->constrained('users')->restrictOnDelete();
            $t->unsignedBigInteger('expected_director_assignment_id')->nullable();
            $t->timestamp('expires_at');
            $t->timestamp('accepted_at')->nullable();
            $t->timestamp('revoked_at')->nullable();
            $t->timestamps();
            $t->index(['school_id', 'email']);
        });
        Schema::create('school_administration_events', function (Blueprint $t) {
            $t->id(); $t->foreignId('school_id')->constrained('schools')->restrictOnDelete();
            $t->unsignedBigInteger('actor_id'); $t->string('action', 80);
            $t->unsignedBigInteger('subject_id')->nullable(); $t->timestamp('created_at');
        });
        if (DB::getDriverName() === 'pgsql') {
            DB::statement('ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check');
            DB::statement("ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (role IN ('parent','teacher','specialist','admin','ministry','institution','school','student','staff'))");
        }
    }

    public function down(): void
    {
        // Preserve supported roles when existing school identities still use them.
        Schema::dropIfExists('school_administration_events');
        Schema::dropIfExists('school_director_invitations');
        Schema::table('school_management_assignments', fn (Blueprint $t) => $t->dropColumn('permissions'));
        Schema::table('school_internal_identities', fn (Blueprint $t) => $t->dropColumn('is_active'));
    }
};
