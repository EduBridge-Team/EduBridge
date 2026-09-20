<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('lessons')) {
            Schema::table('lessons', function (Blueprint $table) {
                if (!Schema::hasColumn('lessons', 'target_type')) {
                    $table->string('target_type', 32)->default('everyone');
                }
                if (!Schema::hasColumn('lessons', 'target_child_ids')) {
                    $table->json('target_child_ids')->nullable();
                }
                if (!Schema::hasColumn('lessons', 'audio_description')) {
                    $table->text('audio_description')->nullable();
                }
            });
        }

        if (Schema::hasTable('media') && DB::getDriverName() === 'pgsql') {
            DB::statement('ALTER TABLE media DROP CONSTRAINT IF EXISTS media_type_check');
            DB::statement('ALTER TABLE media ALTER COLUMN type TYPE VARCHAR(20)');
            DB::statement('ALTER TABLE media ALTER COLUMN url TYPE VARCHAR(2048)');
            DB::statement("ALTER TABLE media ADD CONSTRAINT media_type_check CHECK (type IN ('image', 'video', 'audio', 'caption', 'sign_language'))");
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('lessons')) {
            Schema::table('lessons', function (Blueprint $table) {
                if (Schema::hasColumn('lessons', 'target_type')) {
                    $table->dropColumn('target_type');
                }
                if (Schema::hasColumn('lessons', 'target_child_ids')) {
                    $table->dropColumn('target_child_ids');
                }
                if (Schema::hasColumn('lessons', 'audio_description')) {
                    $table->dropColumn('audio_description');
                }
            });
        }

        // Keep the widened media type/url columns on rollback so existing
        // rich-media records are never destroyed by a schema rollback.
    }
};
