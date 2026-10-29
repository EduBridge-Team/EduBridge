<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('jabalia_teacher_school_transfers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('organization_id')->constrained('organizations')->cascadeOnDelete();
            $table->foreignId('teacher_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('from_school_id')->constrained('schools')->restrictOnDelete();
            $table->foreignId('to_school_id')->constrained('schools')->restrictOnDelete();
            $table->date('effective_on');
            $table->string('reason', 255)->nullable();
            $table->foreignId('recorded_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
            $table->index(['organization_id', 'teacher_id', 'effective_on'], 'jabalia_transfer_history_lookup');
        });
    }
    public function down(): void {
        Schema::dropIfExists('jabalia_teacher_school_transfers');
    }
};
