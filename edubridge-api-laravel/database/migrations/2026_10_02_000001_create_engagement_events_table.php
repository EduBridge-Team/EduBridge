<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('engagement_events', function (Blueprint $table) {
            $table->id();
            $table->foreignId('child_id')->constrained('children')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->uuid('event_id');
            $table->string('request_hash', 64);
            $table->text('response');
            $table->timestamp('created_at')->useCurrent();
            $table->unique(['child_id', 'user_id', 'event_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('engagement_events');
    }
};
