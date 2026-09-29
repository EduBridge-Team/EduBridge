<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('emergency_alerts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('child_id')->constrained('children')->cascadeOnDelete();
            $table->foreignId('triggered_by')->nullable()->constrained('users')->nullOnDelete();
            $table->string('status', 20)->default('active');
            $table->text('message')->nullable();
            $table->string('source', 20)->default('app');
            $table->timestamp('resolved_at')->nullable();
            $table->timestamps();

            $table->index(['child_id', 'status']);
            $table->index('created_at');
        });

        Schema::create('child_rewards', function (Blueprint $table) {
            $table->foreignId('child_id')->primary()->constrained('children')->cascadeOnDelete();
            $table->unsignedInteger('stars')->default(0);
            $table->timestamps();
        });

        Schema::create('game_attempts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('child_id')->constrained('children')->cascadeOnDelete();
            $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('game_key', 80);
            $table->unsignedTinyInteger('score');
            $table->unsignedTinyInteger('stars_earned')->default(0);
            $table->unsignedInteger('duration_seconds')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->index(['child_id', 'created_at']);
            $table->index(['child_id', 'game_key']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('game_attempts');
        Schema::dropIfExists('child_rewards');
        Schema::dropIfExists('emergency_alerts');
    }
};
