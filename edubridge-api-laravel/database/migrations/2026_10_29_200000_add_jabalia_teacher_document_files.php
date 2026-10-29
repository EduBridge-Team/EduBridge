<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::table('jabalia_teacher_documents', function (Blueprint $table) {
            $table->string('storage_path', 255)->nullable();
            $table->string('original_filename', 255)->nullable();
            $table->string('mime_type', 120)->nullable();
            $table->unsignedBigInteger('file_size')->nullable();
        });
    }
    public function down(): void {
        Schema::table('jabalia_teacher_documents', function (Blueprint $table) {
            $table->dropColumn(['storage_path', 'original_filename', 'mime_type', 'file_size']);
        });
    }
};
