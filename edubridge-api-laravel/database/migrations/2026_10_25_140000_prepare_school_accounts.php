<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Independent schools have no parent institution.
        // Preserve all existing institution links; do not delete or reassign data.
        Schema::table('schools', function (Blueprint $table) {
            $table->foreignId('organization_id')->nullable()->change();
        });

        // Separate permanent school identity from its login credentials.
        // Exactly one school per login and one login per school.
        Schema::create('school_accounts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('school_id')->unique()->constrained('schools')->restrictOnDelete();
            $table->foreignId('user_id')->unique()->constrained('users')->restrictOnDelete();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('school_accounts');

        // Independent schools cannot be represented by the original schema.
        // Refuse an unsafe rollback instead of erasing their school records.
        if (\Illuminate\Support\Facades\DB::table('schools')->whereNull('organization_id')->exists()) {
            throw new \RuntimeException('Cannot restore required organization_id while independent schools exist.');
        }

        Schema::table('schools', function (Blueprint $table) {
            $table->foreignId('organization_id')->nullable(false)->change();
        });
    }
};
