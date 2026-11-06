<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Contains only minimal access metadata; never store clinical records,
        // original filenames, storage paths, IP addresses, or file payloads.
        Schema::create('jabalia_admission_evidence_access_events', function (Blueprint $table) {
            $table->id();
            $table->foreignId('school_id')->constrained('schools')->restrictOnDelete();
            $table->foreignId('child_id')->constrained('children')->restrictOnDelete();
            $table->foreignId('enrollment_request_id')->constrained('school_enrollment_requests')->restrictOnDelete();
            $table->unsignedBigInteger('document_id')->nullable();
            $table->string('action', 24);
            $table->foreignId('actor_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('actor_role', 32);
            $table->timestamp('created_at');
            $table->index(['school_id', 'enrollment_request_id', 'id'], 'jabalia_admission_evidence_access_scope');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('jabalia_admission_evidence_access_events');
    }
};
