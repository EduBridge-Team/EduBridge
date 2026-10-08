<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('timetable_entries', function (Blueprint $table) {
            $table->id();
            $table->foreignId('school_id')->constrained('schools')->cascadeOnDelete();
            $table->foreignId('academic_year_id')->constrained('academic_years')->cascadeOnDelete();
            $table->foreignId('section_id')->constrained('sections')->cascadeOnDelete();
            $table->foreignId('subject_id')->constrained('subjects')->cascadeOnDelete();
            $table->foreignId('teacher_id')->nullable()->constrained('users')->nullOnDelete();
            $table->unsignedTinyInteger('weekday'); // 1=Sunday ... 7=Saturday
            $table->unsignedTinyInteger('period_number');
            $table->time('starts_at')->nullable();
            $table->time('ends_at')->nullable();
            $table->string('room', 80)->nullable();
            $table->timestamps();

            $table->unique(['section_id', 'weekday', 'period_number'], 'uq_timetable_section_slot');
            $table->index(['school_id', 'weekday', 'period_number']);
            $table->index(['teacher_id', 'weekday', 'period_number']);
        });

        Schema::create('teacher_absences', function (Blueprint $table) {
            $table->id();
            $table->foreignId('school_id')->constrained('schools')->cascadeOnDelete();
            $table->foreignId('teacher_id')->constrained('users')->cascadeOnDelete();
            $table->date('absence_date');
            $table->text('reason')->nullable();
            $table->string('status', 20)->default('confirmed');
            $table->foreignId('reported_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
            $table->unique(['school_id', 'teacher_id', 'absence_date']);
        });

        Schema::create('class_substitutions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('timetable_entry_id')->constrained('timetable_entries')->cascadeOnDelete();
            $table->date('class_date');
            $table->foreignId('original_teacher_id')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('substitute_teacher_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('status', 20)->default('assigned');
            $table->text('notes')->nullable();
            $table->foreignId('assigned_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
            $table->unique(['timetable_entry_id', 'class_date']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('class_substitutions');
        Schema::dropIfExists('teacher_absences');
        Schema::dropIfExists('timetable_entries');
    }
};
