<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Append-only administrative preparation actions; no clinical findings,
        // medical evidence filenames, rejection or admission decisions.
        Schema::create('jabalia_admission_intake_events', function (Blueprint $table) {
            $table->id();
            $table->foreignId('organization_id')->constrained('organizations')->restrictOnDelete();
            $table->foreignId('school_id')->constrained('schools')->restrictOnDelete();
            $table->foreignId('enrollment_request_id')->constrained('school_enrollment_requests')->restrictOnDelete();
            $table->foreignId('child_id')->constrained('children')->restrictOnDelete();
            $table->unsignedInteger('request_version');
            $table->string('state', 48);
            $table->foreignId('actor_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('management_role', 32);
            $table->timestamp('created_at');
            $table->index(['organization_id', 'school_id', 'enrollment_request_id', 'id'], 'jabalia_admission_intake_scope');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('jabalia_admission_intake_events');
    }
};
