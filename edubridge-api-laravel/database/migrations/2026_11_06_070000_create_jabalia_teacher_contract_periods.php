<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // A contract period is an immutable administrative snapshot. The
        // privately stored underlying signed copy remains in teacher documents.
        Schema::create('jabalia_teacher_contract_periods', function (Blueprint $table) {
            $table->id();
            $table->foreignId('organization_id')->constrained('organizations')->restrictOnDelete();
            $table->foreignId('school_id')->constrained('schools')->restrictOnDelete();
            $table->foreignId('teacher_id')->constrained('users')->restrictOnDelete();
            $table->foreignId('contract_document_id')->unique()
                ->constrained('jabalia_teacher_documents')->restrictOnDelete();
            $table->foreignId('previous_period_id')->nullable()->unique()
                ->constrained('jabalia_teacher_contract_periods')->restrictOnDelete();
            $table->string('project_name', 160);
            $table->date('starts_on');
            $table->date('ends_on');
            $table->date('signed_on')->nullable();
            $table->foreignId('recorded_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('created_at');
            $table->index(['organization_id', 'school_id', 'teacher_id', 'id'], 'jabalia_contract_period_scope');
            $table->index(['school_id', 'ends_on'], 'jabalia_contract_period_expiry');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('jabalia_teacher_contract_periods');
    }
};
