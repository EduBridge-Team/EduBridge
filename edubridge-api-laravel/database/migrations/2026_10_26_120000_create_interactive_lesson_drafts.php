<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('interactive_lesson_drafts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('author_id')->constrained('users')->cascadeOnDelete();
            $table->string('template_id', 100);
            $table->string('title', 120);
            $table->string('objective', 500);
            $table->unsignedInteger('version')->default(1);
            $table->timestamps();
            $table->index(['author_id', 'updated_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('interactive_lesson_drafts');
    }
};
