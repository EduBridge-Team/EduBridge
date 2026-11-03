<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('school_specialist_employments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('school_id')->constrained('schools')->restrictOnDelete();
            $table->foreignId('specialist_id')->constrained('users')->restrictOnDelete();
            $table->foreignId('invited_by')->constrained('users')->restrictOnDelete();
            $table->timestamp('accepted_at')->nullable();
            $table->timestamp('ended_at')->nullable();
            $table->timestamps();
            $table->index(['school_id', 'specialist_id', 'ended_at'], 'school_specialist_employment_lookup');
        });
        Schema::create('independent_school_specialist_assignments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('school_id')->constrained('schools')->restrictOnDelete();
            $table->foreignId('specialist_id')->constrained('users')->restrictOnDelete();
            $table->foreignId('employment_id')->constrained('school_specialist_employments')->restrictOnDelete();
            $table->foreignId('assigned_by')->constrained('users')->restrictOnDelete();
            $table->date('starts_on');
            $table->date('ended_on')->nullable();
            $table->timestamps();
            $table->index(['school_id', 'specialist_id', 'ended_on'], 'independent_specialist_active_lookup');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('independent_school_specialist_assignments');
        Schema::dropIfExists('school_specialist_employments');
    }
};
