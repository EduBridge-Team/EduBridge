<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('organizations', function (Blueprint $table) {
            // A fixed account namespace, not a DNS name or email domain.
            $table->string('internal_domain', 80)->nullable()->unique();
        });

        Schema::create('institution_internal_identities', function (Blueprint $table) {
            $table->id();
            $table->foreignId('organization_id')->constrained('organizations')->restrictOnDelete();
            $table->foreignId('user_id')->unique()->constrained('users')->restrictOnDelete();
            $table->string('username', 64);
            $table->boolean('is_active')->default(true);
            $table->boolean('must_change_password')->default(true);
            $table->timestamps();
            $table->unique(['organization_id', 'username']);
        });

        Schema::create('institution_internal_account_events', function (Blueprint $table) {
            $table->id();
            $table->foreignId('organization_id')->constrained('organizations')->restrictOnDelete();
            $table->foreignId('actor_id')->constrained('users')->restrictOnDelete();
            $table->foreignId('subject_id')->constrained('users')->restrictOnDelete();
            $table->string('action', 48);
            $table->timestamp('created_at');
            $table->index(['organization_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('institution_internal_account_events');
        Schema::dropIfExists('institution_internal_identities');
        Schema::table('organizations', function (Blueprint $table) {
            $table->dropUnique(['internal_domain']);
            $table->dropColumn('internal_domain');
        });
    }
};
