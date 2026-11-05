<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('jabalia_supervisor_visits', function (Blueprint $table) {
            $table->id();
            $table->foreignId('organization_id')->constrained('organizations')->restrictOnDelete();
            $table->foreignId('school_id')->constrained('schools')->restrictOnDelete();
            $table->date('visited_on');
            $table->string('supervisor_name', 160);
            $table->text('findings');
            $table->text('corrective_action');
            $table->date('due_on')->nullable();
            $table->string('status', 16)->default('open');
            $table->foreignId('recorded_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
            $table->index(['school_id', 'visited_on'], 'jabalia_supervision_school_date');
        });

        Schema::create('jabalia_supervisor_visit_events', function (Blueprint $table) {
            $table->id();
            $table->foreignId('visit_id')->constrained('jabalia_supervisor_visits')->restrictOnDelete();
            $table->foreignId('organization_id')->constrained('organizations')->restrictOnDelete();
            $table->foreignId('school_id')->constrained('schools')->restrictOnDelete();
            $table->string('action', 24);
            $table->string('from_status', 16)->nullable();
            $table->string('to_status', 16);
            $table->text('note')->nullable();
            $table->foreignId('actor_id')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('created_at');
            $table->index(['school_id', 'visit_id', 'id'], 'jabalia_supervision_event_lookup');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('jabalia_supervisor_visit_events');
        Schema::dropIfExists('jabalia_supervisor_visits');
    }
};
