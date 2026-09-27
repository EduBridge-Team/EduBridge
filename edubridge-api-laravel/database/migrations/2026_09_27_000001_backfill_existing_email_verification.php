<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('users') || !Schema::hasColumn('users', 'email_verified_at')) {
            return;
        }

        // Preserve access for accounts that existed before email verification
        // became mandatory. Accounts created after this migration keep the
        // default null value until the verification link is opened.
        DB::table('users')
            ->whereNull('email_verified_at')
            ->update(['email_verified_at' => now()]);
    }

    public function down(): void
    {
        // Intentionally irreversible: reverting the deployment must not
        // unexpectedly unverify existing users.
    }
};
