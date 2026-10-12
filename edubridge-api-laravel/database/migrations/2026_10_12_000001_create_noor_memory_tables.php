<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('noor_memory_preferences', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->unsignedBigInteger('child_id');
            $table->boolean('enabled')->default(false);
            $table->timestamp('consented_at')->nullable();
            $table->timestamps();
            $table->unique(['user_id', 'child_id']);
            $table->index('child_id');
        });

        Schema::create('noor_memories', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->unsignedBigInteger('child_id');
            $table->string('kind', 40);
            $table->text('content');
            $table->timestamp('expires_at')->nullable();
            $table->timestamps();
            $table->index(['user_id', 'child_id', 'expires_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('noor_memories');
        Schema::dropIfExists('noor_memory_preferences');
    }
};
