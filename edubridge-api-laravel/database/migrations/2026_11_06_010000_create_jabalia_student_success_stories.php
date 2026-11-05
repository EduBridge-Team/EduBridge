<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Internal-only school progress records. No publication or guardian endpoint.
        Schema::create('jabalia_student_success_stories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('organization_id')->constrained('organizations')->restrictOnDelete();
            $table->foreignId('school_id')->constrained('schools')->restrictOnDelete();
            $table->foreignId('child_id')->constrained('children')->restrictOnDelete();
            $table->date('observed_on');
            $table->string('title', 160);
            $table->text('narrative');
            $table->foreignId('recorded_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
            $table->index(['organization_id', 'school_id', 'observed_on'], 'jabalia_story_tenant_date');
            $table->index(['school_id', 'child_id', 'id'], 'jabalia_story_child_lookup');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('jabalia_student_success_stories');
    }
};
