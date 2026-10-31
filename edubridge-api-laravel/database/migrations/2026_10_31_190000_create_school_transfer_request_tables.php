<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('school_transfer_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('child_id')->constrained('children')->restrictOnDelete();
            $table->foreignId('source_enrollment_id')->constrained('student_enrollments')->restrictOnDelete();
            $table->foreignId('source_school_id')->constrained('schools')->restrictOnDelete();
            $table->foreignId('destination_school_id')->constrained('schools')->restrictOnDelete();
            $table->foreignId('requested_by')->constrained('users')->restrictOnDelete();
            $table->foreignId('guardian_decided_by')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('destination_decided_by')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('destination_section_id')->nullable()->constrained('sections')->nullOnDelete();
            $table->foreignId('destination_enrollment_id')->nullable()->constrained('student_enrollments')->nullOnDelete();
            $table->string('status', 32)->default('pending_guardian');
            $table->unsignedInteger('version')->default(1);
            $table->string('idempotency_key', 128)->nullable()->unique();
            $table->string('reason', 500)->nullable();
            $table->timestamp('guardian_decided_at')->nullable();
            $table->timestamp('destination_decided_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->timestamp('expires_at')->nullable();
            $table->timestamps();
            $table->index(['child_id', 'status']);
            $table->index(['source_school_id', 'status']);
            $table->index(['destination_school_id', 'status']);
        });

        Schema::create('school_transfer_events', function (Blueprint $table) {
            $table->id();
            $table->foreignId('transfer_request_id')->constrained('school_transfer_requests')->restrictOnDelete();
            $table->foreignId('actor_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('event_type', 64);
            $table->string('previous_status', 32)->nullable();
            $table->string('next_status', 32);
            $table->json('metadata')->nullable();
            $table->timestamps();
            $table->index(['transfer_request_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('school_transfer_events');
        Schema::dropIfExists('school_transfer_requests');
    }
};
