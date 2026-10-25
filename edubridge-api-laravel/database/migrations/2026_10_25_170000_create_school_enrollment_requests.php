<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('school_enrollment_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('child_id')->constrained('children')->restrictOnDelete();
            $table->foreignId('school_id')->constrained('schools')->restrictOnDelete();
            $table->foreignId('requested_by')->constrained('users')->restrictOnDelete();
            $table->string('status', 20)->default('pending');
            $table->unsignedInteger('version')->default(1);
            $table->text('reason')->nullable();
            $table->foreignId('decided_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('decided_at')->nullable();
            $table->timestamps();
            $table->index(['school_id', 'status', 'created_at'], 'school_requests_inbox');
            $table->index(['child_id', 'created_at'], 'school_requests_child_history');
        });

        DB::statement("ALTER TABLE school_enrollment_requests ADD CONSTRAINT school_request_status_check CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled'))");
        DB::statement('ALTER TABLE school_enrollment_requests ADD CONSTRAINT school_request_version_check CHECK (version > 0)');
        // A child must not have simultaneous pending requests to different schools.
        DB::statement("CREATE UNIQUE INDEX school_requests_one_pending_per_child ON school_enrollment_requests (child_id) WHERE status = 'pending'");
    }

    public function down(): void
    {
        Schema::dropIfExists('school_enrollment_requests');
    }
};
