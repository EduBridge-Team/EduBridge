<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('jabalia_school_closure_days', function (Blueprint $table) {
            $table->id();
            $table->foreignId('organization_id')->constrained('organizations')->cascadeOnDelete();
            $table->foreignId('school_id')->constrained('schools')->cascadeOnDelete();
            $table->date('closed_on');
            $table->string('reason', 250);
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamps();
            $table->unique(['school_id', 'closed_on'], 'jabalia_closure_school_day_unique');
            $table->index(['organization_id', 'closed_on'], 'jabalia_closure_organization_date');
        });

        Schema::create('jabalia_school_closure_events', function (Blueprint $table) {
            $table->id();
            $table->foreignId('organization_id')->constrained('organizations')->cascadeOnDelete();
            $table->foreignId('school_id')->constrained('schools')->cascadeOnDelete();
            $table->date('closed_on');
            $table->string('action', 12);
            $table->string('reason', 250);
            $table->unsignedBigInteger('actor_id')->nullable();
            $table->timestamp('created_at');
            $table->index(['school_id', 'id'], 'jabalia_closure_event_school');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('jabalia_school_closure_events');
        Schema::dropIfExists('jabalia_school_closure_days');
    }
};
