<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('children', function (Blueprint $table) {
            if (!Schema::hasColumn('children', 'medical_report_url')) {
                $table->string('medical_report_url', 255)->nullable()->after('kinship_document_url');
            }
        });
    }

    public function down(): void
    {
        Schema::table('children', function (Blueprint $table) {
            if (Schema::hasColumn('children', 'medical_report_url')) {
                $table->dropColumn('medical_report_url');
            }
        });
    }
};
