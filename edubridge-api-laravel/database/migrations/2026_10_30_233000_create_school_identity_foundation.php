<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('schools', function (Blueprint $table) {
            // Nullable until the director confirms a globally unique namespace.
            $table->string('internal_domain', 80)->nullable()->unique();
            $table->timestamp('internal_domain_confirmed_at')->nullable();
        });

        Schema::create('school_management_assignments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('school_id')->constrained('schools')->restrictOnDelete();
            $table->foreignId('user_id')->constrained('users')->restrictOnDelete();
            $table->string('role', 32); // director or deputy_director
            $table->foreignId('appointed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('starts_at');
            $table->timestamp('ends_at')->nullable();
            $table->timestamps();
            $table->index(['school_id', 'role', 'ends_at']);
            $table->index(['user_id', 'ends_at']);
        });

        Schema::create('school_internal_identities', function (Blueprint $table) {
            $table->id();
            $table->foreignId('school_id')->constrained('schools')->restrictOnDelete();
            $table->foreignId('user_id')->unique()->constrained('users')->restrictOnDelete();
            $table->string('username', 64);
            $table->timestamps();
            $table->unique(['school_id', 'username']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('school_internal_identities');
        Schema::dropIfExists('school_management_assignments');
        Schema::table('schools', function (Blueprint $table) {
            $table->dropUnique(['internal_domain']);
            $table->dropColumn(['internal_domain', 'internal_domain_confirmed_at']);
        });
    }
};
