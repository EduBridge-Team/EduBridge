<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('school_staff_attendance', function (Blueprint $t) {
            $t->id(); $t->foreignId('school_id')->constrained('schools')->restrictOnDelete();
            $t->foreignId('user_id')->constrained('users')->restrictOnDelete();
            $t->date('attendance_date'); $t->string('status', 20);
            $t->foreignId('recorded_by')->constrained('users')->restrictOnDelete(); $t->timestamps();
            $t->unique(['school_id', 'user_id', 'attendance_date']);
        });
    }

    public function down(): void { Schema::dropIfExists('school_staff_attendance'); }
};
