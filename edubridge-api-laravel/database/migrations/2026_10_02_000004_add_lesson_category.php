<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasColumn('lessons', 'category')) {
            Schema::table('lessons', function (Blueprint $table) {
                $table->string('category', 100)->nullable();
            });
        }
    }

    public function down(): void
    {
        // Preserve classifications, including columns from older deployments.
    }
};
