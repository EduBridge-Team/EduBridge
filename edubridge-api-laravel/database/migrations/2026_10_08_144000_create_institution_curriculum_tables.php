<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('curriculum_books', function (Blueprint $table) {
            $table->id();
            $table->foreignId('school_id')->constrained('schools')->cascadeOnDelete();
            $table->foreignId('academic_year_id')->nullable()->constrained('academic_years')->nullOnDelete();
            $table->foreignId('grade_id')->constrained('grades')->cascadeOnDelete();
            $table->foreignId('subject_id')->constrained('subjects')->cascadeOnDelete();
            $table->string('title', 200);
            $table->string('semester', 40)->nullable();
            $table->string('edition', 80)->nullable();
            $table->string('source_name', 160)->nullable();
            $table->text('source_url')->nullable();
            $table->string('storage_path', 1024)->nullable();
            $table->string('status', 24)->default('draft');
            $table->timestamps();
            $table->index(['school_id', 'grade_id', 'subject_id']);
        });

        Schema::create('curriculum_units', function (Blueprint $table) {
            $table->id();
            $table->foreignId('curriculum_book_id')->constrained('curriculum_books')->cascadeOnDelete();
            $table->string('title', 200);
            $table->unsignedInteger('position')->default(1);
            $table->timestamps();
            $table->unique(['curriculum_book_id', 'position']);
        });

        Schema::create('curriculum_lessons', function (Blueprint $table) {
            $table->id();
            $table->foreignId('curriculum_unit_id')->constrained('curriculum_units')->cascadeOnDelete();
            $table->string('title', 200);
            $table->unsignedInteger('position')->default(1);
            $table->string('source_pages', 80)->nullable();
            $table->longText('content_text')->nullable();
            $table->json('metadata')->default('{}');
            $table->timestamps();
            $table->unique(['curriculum_unit_id', 'position']);
        });

        Schema::create('noor_lesson_generations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('school_id')->constrained('schools')->cascadeOnDelete();
            $table->foreignId('curriculum_lesson_id')->constrained('curriculum_lessons')->cascadeOnDelete();
            $table->foreignId('requested_by')->constrained('users')->cascadeOnDelete();
            $table->string('generation_type', 40)->default('visual_lesson_plan');
            $table->json('output');
            $table->string('status', 24)->default('draft');
            $table->foreignId('approved_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('approved_at')->nullable();
            $table->timestamps();
            $table->index(['school_id', 'curriculum_lesson_id']);
            $table->index(['requested_by', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('noor_lesson_generations');
        Schema::dropIfExists('curriculum_lessons');
        Schema::dropIfExists('curriculum_units');
        Schema::dropIfExists('curriculum_books');
    }
};
