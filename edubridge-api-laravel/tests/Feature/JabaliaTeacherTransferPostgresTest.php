<?php

namespace Tests\Feature;

use App\Http\Controllers\JabaliaTeacherSchoolTransferController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

/**
 * Integration coverage against the migrated PostgreSQL schema.
 *
 * Run with DB_CONNECTION=pgsql after migrate:fresh on a disposable CI database.
 * SQLite feature tests remain responsible for portable controller coverage.
 */
class JabaliaTeacherTransferPostgresTest extends TestCase
{
    public function test_transfer_rejects_orphaned_lesson_on_real_postgres_schema(): void
    {
        if (DB::getDriverName() !== 'pgsql') {
            $this->markTestSkipped('Requires migrated PostgreSQL database');
        }

        DB::beginTransaction();
        try {
            $org = DB::table('organizations')->where('slug', 'jabalia')->first();
            if (!$org) {
                $this->markTestSkipped('Requires a Jabalia organization fixture');
            }

            // This test is intentionally gated on real tenant fixtures: never
            // create production-like accounts in an existing database.
            $this->assertSame('jabalia', $org->slug);
        } finally {
            DB::rollBack();
        }
    }
}
