<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (!Schema::hasColumn('users', 'identity_status')) {
                $table->string('identity_status', 20)->default('pending')->after('id_document_url');
            }
        });

        DB::table('users')
            ->whereIn('role', ['teacher', 'specialist'])
            ->update([
                'identity_status' => DB::raw("CASE WHEN verification_status = 'verified' THEN 'verified' WHEN verification_status = 'rejected' THEN 'rejected' ELSE 'pending' END"),
            ]);

        DB::statement("\n            UPDATE users u\n            SET verification_status = 'pending', verified_at = NULL\n            WHERE u.role IN ('teacher', 'specialist')\n              AND u.verification_status = 'verified'\n              AND NOT EXISTS (\n                  SELECT 1 FROM certificates c\n                  WHERE c.user_id = u.id AND c.status = 'verified'\n              )\n        ");
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (Schema::hasColumn('users', 'identity_status')) {
                $table->dropColumn('identity_status');
            }
        });
    }
};
