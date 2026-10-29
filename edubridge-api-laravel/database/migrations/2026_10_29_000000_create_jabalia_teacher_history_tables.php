<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Additive schema: existing assignments remain unchanged.
        // Only Jabalia-specific services should create rows in these tables.
        Schema::create('jabalia_teacher_profiles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('organization_id')->constrained('organizations')->cascadeOnDelete();
            $table->foreignId('teacher_id')->constrained('users')->cascadeOnDelete();
            $table->string('qualification', 160)->nullable();
            $table->string('specialization', 160)->nullable();
            $table->unsignedSmallInteger('experience_years')->nullable();
            $table->text('professional_notes')->nullable();
            $table->timestamps();
            $table->unique(['organization_id', 'teacher_id']);
        });

        Schema::create('jabalia_teacher_assignment_history', function (Blueprint $table) {
            $table->id();
            $table->foreignId('organization_id')->constrained('organizations')->cascadeOnDelete();
            $table->foreignId('school_id')->constrained('schools')->cascadeOnDelete();
            $table->foreignId('teacher_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('section_id')->nullable()->constrained('sections')->nullOnDelete();
            $table->foreignId('subject_id')->nullable()->constrained('subjects')->nullOnDelete();
            $table->date('starts_on');
            $table->date('ends_on')->nullable();
            $table->string('status', 24)->default('active');
            $table->string('reason', 255)->nullable();
            $table->foreignId('recorded_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
            $table->index(['organization_id', 'teacher_id', 'starts_on'], 'jabalia_teacher_history_lookup');
            $table->index(['school_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('jabalia_teacher_assignment_history');
        Schema::dropIfExists('jabalia_teacher_profiles');
    }
};
