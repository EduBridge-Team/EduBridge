<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('notifications', function (Blueprint $table) {
            $table->index(['user_id', 'id'], 'notifications_user_cursor_index');
            $table->index(['user_id', 'is_read'], 'notifications_user_unread_index');
        });
    }

    public function down(): void
    {
        Schema::table('notifications', function (Blueprint $table) {
            $table->dropIndex('notifications_user_cursor_index');
            $table->dropIndex('notifications_user_unread_index');
        });
    }
};
