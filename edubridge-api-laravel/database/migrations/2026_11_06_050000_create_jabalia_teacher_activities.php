<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Private educational activity logs, never personnel contract/legal records.
        Schema::create('jabalia_teacher_activities', function (Blueprint $table) {
            $table->id();
            $table->foreignId('organization_id')->constrained('organizations')->restrictOnDelete();
            $table->foreignId('school_id')->constrained('schools')->restrictOnDelete();
            $table->foreignId('teacher_id')->constrained('users')->restrictOnDelete();
            $table->date('activity_on');
            $table->string('activity_type', 36);
            $table->string('title', 160);
            $table->text('summary');
            $table->foreignId('recorded_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
            $table->index(['organization_id','school_id','activity_on','id'], 'jabalia_teacher_activities_scope');
            $table->index(['school_id','teacher_id','id'], 'jabalia_teacher_activities_teacher');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('jabalia_teacher_activities');
    }
};
