<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('school_promotion_previews', function (Blueprint $t) {
            $t->id(); $t->foreignId('school_id')->constrained('schools')->restrictOnDelete();
            $t->foreignId('actor_id')->constrained('users')->restrictOnDelete();
            $t->string('token_hash', 64)->unique(); $t->string('payload_hash', 64);
            $t->timestamp('expires_at'); $t->timestamp('used_at')->nullable(); $t->timestamps();
        });
        Schema::create('school_promotion_operations', function (Blueprint $t) {
            $t->string('operation_id', 128)->primary();
            $t->foreignId('school_id')->constrained('schools')->restrictOnDelete();
            $t->foreignId('actor_id')->constrained('users')->restrictOnDelete();
            $t->unsignedBigInteger('source_year_id'); $t->unsignedBigInteger('target_year_id');
            $t->string('payload_hash', 64); $t->json('receipt'); $t->json('decisions'); $t->timestamps();
            $t->index(['school_id', 'source_year_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('school_promotion_operations');
        Schema::dropIfExists('school_promotion_previews');
    }
};
