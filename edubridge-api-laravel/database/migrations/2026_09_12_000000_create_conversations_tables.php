<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('conversations', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('participant_one_id');
            $table->unsignedBigInteger('participant_two_id');
            $table->string('subject')->nullable();
            $table->timestamps();
            $table->unique(['participant_one_id', 'participant_two_id']);
            $table->foreign('participant_one_id')->references('id')->on('users')->cascadeOnDelete();
            $table->foreign('participant_two_id')->references('id')->on('users')->cascadeOnDelete();
        });

        Schema::create('conversation_messages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('conversation_id')->constrained('conversations')->cascadeOnDelete();
            $table->unsignedBigInteger('sender_id');
            $table->text('content');
            $table->string('file_url')->nullable();
            $table->timestamps();
            $table->foreign('sender_id')->references('id')->on('users')->cascadeOnDelete();
            $table->index(['conversation_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('conversation_messages');
        Schema::dropIfExists('conversations');
    }
};
