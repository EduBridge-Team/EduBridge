<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('child_accessibility_profiles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('child_id')->unique()->constrained('children')->cascadeOnDelete();
            $table->json('profile');
            $table->foreignId('updated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('child_accessibility_profiles');
    }
};
