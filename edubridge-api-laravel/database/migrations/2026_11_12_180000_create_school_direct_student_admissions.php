<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('school_direct_student_admissions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('school_id')->constrained('schools')->restrictOnDelete();
            $table->foreignId('child_id')->unique()->constrained('children')->restrictOnDelete();
            $table->string('student_number', 40);
            $table->foreignId('created_by')->constrained('users')->restrictOnDelete();
            $table->timestamps();
            $table->unique(['school_id', 'student_number'], 'school_direct_student_number_unique');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('school_direct_student_admissions');
    }
};
