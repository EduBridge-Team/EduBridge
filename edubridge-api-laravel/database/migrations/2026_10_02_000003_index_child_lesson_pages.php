<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('children', fn (Blueprint $table) => $table->index(['name', 'id'], 'children_name_page_index'));
        Schema::table('lessons', fn (Blueprint $table) => $table->index(['created_at', 'id'], 'lessons_created_page_index'));
    }

    public function down(): void
    {
        Schema::table('children', fn (Blueprint $table) => $table->dropIndex('children_name_page_index'));
        Schema::table('lessons', fn (Blueprint $table) => $table->dropIndex('lessons_created_page_index'));
    }
};
