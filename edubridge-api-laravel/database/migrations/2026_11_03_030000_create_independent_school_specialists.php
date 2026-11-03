<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('school_specialist_employments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('school_id')->constrained('schools')->restrictOnDelete();
            $table->foreignId('specialist_id')->constrained('users')->restrictOnDelete();
            $table->foreignId('invited_by')->constrained('users')->restrictOnDelete();
            $table->timestamp('offered_at');
            $table->timestamp('accepted_at')->nullable();
            $table->timestamp('ended_at')->nullable();
            $table->timestamps();
            $table->index(['school_id', 'ended_at']);
            $table->index(['specialist_id', 'ended_at']);
        });
        Schema::create('school_specialist_assignments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('school_id')->constrained('schools')->restrictOnDelete();
            $table->foreignId('employment_id')->constrained('school_specialist_employments')->restrictOnDelete();
            $table->foreignId('specialist_id')->constrained('users')->restrictOnDelete();
            $table->foreignId('assigned_by')->constrained('users')->restrictOnDelete();
            $table->date('starts_on');
            $table->date('ended_on')->nullable();
            $table->timestamps();
            $table->index(['school_id', 'ended_on']);
            $table->index(['specialist_id', 'ended_on']);
        });

        // Enforce one live offer/employment and one live assignment per school
        // and specialist even when distinct director sessions race.
        if (DB::getDriverName() === 'pgsql') {
            DB::statement('CREATE UNIQUE INDEX school_specialist_employment_one_live ON school_specialist_employments (school_id, specialist_id) WHERE ended_at IS NULL');
            DB::statement('CREATE UNIQUE INDEX school_specialist_assignment_one_live ON school_specialist_assignments (school_id, specialist_id) WHERE ended_on IS NULL');
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('school_specialist_assignments');
        Schema::dropIfExists('school_specialist_employments');
    }
};
