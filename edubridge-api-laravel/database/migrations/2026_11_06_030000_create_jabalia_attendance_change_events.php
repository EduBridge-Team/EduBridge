<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Historical child attendance changes are append-only, not rewritable notes.
        // No names, medical information or guardian contact details are stored here.
        Schema::create('jabalia_attendance_change_events', function (Blueprint $table) {
            $table->id();
            $table->foreignId('organization_id')->constrained('organizations')->restrictOnDelete();
            $table->foreignId('school_id')->constrained('schools')->restrictOnDelete();
            $table->foreignId('attendance_session_id')->constrained('attendance_sessions')->restrictOnDelete();
            $table->foreignId('child_id')->constrained('children')->restrictOnDelete();
            $table->string('previous_status', 20)->nullable();
            $table->string('new_status', 20);
            $table->foreignId('actor_id')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('created_at');
            $table->index(['organization_id', 'school_id', 'attendance_session_id', 'id'], 'jabalia_attendance_change_scope');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('jabalia_attendance_change_events');
    }
};
