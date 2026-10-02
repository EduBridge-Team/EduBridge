<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('sign_entries', function (Blueprint $table) {
            $table->text('animation_url')->nullable()->after('thumbnail_url');
            $table->string('animation_format', 32)->nullable()->after('animation_url');
            $table->string('animation_status', 32)->default('pending')->after('animation_format')->index();
        });
    }

    public function down(): void
    {
        Schema::table('sign_entries', function (Blueprint $table) {
            $table->dropIndex(['animation_status']);
            $table->dropColumn(['animation_url', 'animation_format', 'animation_status']);
        });
    }
};
