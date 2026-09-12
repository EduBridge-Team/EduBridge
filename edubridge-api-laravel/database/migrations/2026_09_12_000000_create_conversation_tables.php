<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('conversations')) {
            Schema::create('conversations', function (Blueprint $table) {
                $table->id();
                $table->foreignId('participant_one_id')->constrained('users')->cascadeOnDelete();
                $table->foreignId('participant_two_id')->constrained('users')->cascadeOnDelete();
                $table->foreignId('created_by_id')->nullable()->constrained('users')->nullOnDelete();
                $table->string('subject', 150)->nullable();
                $table->timestamps();
                $table->unique(['participant_one_id', 'participant_two_id']);
                $table->index('updated_at');
            });
        }

        if (!Schema::hasTable('conversation_messages')) {
            Schema::create('conversation_messages', function (Blueprint $table) {
                $table->id();
                $table->foreignId('conversation_id')->constrained('conversations')->cascadeOnDelete();
                $table->foreignId('sender_id')->constrained('users')->cascadeOnDelete();
                $table->text('content')->nullable();
                $table->string('file_url', 2048)->nullable();
                $table->timestamp('created_at')->useCurrent();
                $table->index(['conversation_id', 'id']);
                $table->index('sender_id');
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('conversation_messages');
        Schema::dropIfExists('conversations');
    }
};
