<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('jabalia_school_timetable_settings', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('school_id')->unique();
            $table->json('weekdays');
            $table->json('periods');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('jabalia_school_timetable_settings');
    }
};
