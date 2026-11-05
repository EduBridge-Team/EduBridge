<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('jabalia_admission_documents', function (Blueprint $table) {
            $table->id();
            $table->foreignId('enrollment_request_id')->constrained('school_enrollment_requests')->restrictOnDelete();
            $table->foreignId('school_id')->constrained('schools')->restrictOnDelete();
            $table->foreignId('child_id')->constrained('children')->restrictOnDelete();
            $table->string('type', 32);
            $table->string('storage_path', 255);
            $table->string('mime_type', 100);
            $table->unsignedBigInteger('file_size');
            $table->foreignId('uploaded_by')->constrained('users')->restrictOnDelete();
            $table->timestamps();
            $table->index(['enrollment_request_id', 'type'], 'jabalia_admission_request_document_types');
            $table->index(['school_id', 'enrollment_request_id'], 'jabalia_admission_school_request_lookup');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('jabalia_admission_documents');
    }
};
