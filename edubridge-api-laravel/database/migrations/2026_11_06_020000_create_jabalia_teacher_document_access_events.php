<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Append-only access evidence, separate from confidential file payloads.
        Schema::create('jabalia_teacher_document_access_events', function (Blueprint $table) {
            $table->id();
            $table->foreignId('organization_id')->constrained('organizations')->restrictOnDelete();
            $table->foreignId('school_id')->constrained('schools')->restrictOnDelete();
            $table->foreignId('teacher_id')->constrained('users')->restrictOnDelete();
            // No FK: retain the historical document identifier after authorized deletion.
            $table->unsignedBigInteger('document_id')->nullable();
            $table->string('action', 24);
            $table->foreignId('actor_id')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('created_at');
            $table->index(['organization_id', 'school_id', 'teacher_id', 'id'], 'jabalia_doc_access_scope');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('jabalia_teacher_document_access_events');
    }
};
