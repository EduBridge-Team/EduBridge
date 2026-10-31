<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('student_account_links', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id')->unique();
            $table->unsignedBigInteger('child_id')->unique();
            $table->unsignedBigInteger('school_id');
            $table->timestamps();
            $table->index('school_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('student_account_links');
    }
};
