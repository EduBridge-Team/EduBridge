<?php

namespace Tests\\Feature;

use Illuminate\\Database\\Schema\\Blueprint;
use Illuminate\\Support\\Facades\\DB;
use Illuminate\\Support\\Facades\\Schema;
use Tests\\TestCase;

class UniqueSubjectCodeMigrationTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('subjects', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('school_id');
            $table->string('name', 120);
            $table->string('code', 40)->nullable();
        });
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('subjects');
        parent::tearDown();
    }

    public function test_migration_preserves_legacy_codes_and_allows_null_or_blank_codes(): void
    {
        DB::table('subjects')->insert([
            ['id' => 1, 'school_id' => 1, 'name' => 'Math', 'code' => ' math '],
            ['id' => 2, 'school_id' => 1, 'name' => 'Arabic', 'code' => null],
            ['id' => 3, 'school_id' => 1, 'name' => 'English', 'code' => '   '],
            ['id' => 4, 'school_id' => 2, 'name' => 'Math', 'code' => 'MATH'],
        ]);

        $migration = require database_path('migrations/2026_11_08_110000_add_unique_normalized_subject_codes.php');
        $migration->up();

        $this->assertSame(' math ', DB::table('subjects')->where('id', 1)->value('code'));
        $this->assertSame('MATH', DB::table('subjects')->where('id', 1)->value('code_normalized'));
        $this->assertNull(DB::table('subjects')->where('id', 2)->value('code_normalized'));
        $this->assertNull(DB::table('subjects')->where('id', 3)->value('code_normalized'));
        $this->assertSame('MATH', DB::table('subjects')->where('id', 4)->value('code_normalized'));

        $migration->down();
        $this->assertFalse(Schema::hasColumn('subjects', 'code_normalized'));
    }

    public function test_migration_reports_legacy_normalized_duplicates_without_mutating_schema(): void
    {
        DB::table('subjects')->insert([
            ['id' => 1, 'school_id' => 1, 'name' => 'Math', 'code' => 'math'],
            ['id' => 2, 'school_id' => 1, 'name' => 'Mathematics', 'code' => ' MATH '],
        ]);

        $migration = require database_path('migrations/2026_11_08_110000_add_unique_normalized_subject_codes.php');

        try {
            $migration->up();
            $this->fail('Expected legacy duplicate preflight to stop the migration.');
        } catch (\\RuntimeException $exception) {
            $this->assertStringContainsString('subject IDs: 1, 2', $exception->getMessage());
        }

        $this->assertFalse(Schema::hasColumn('subjects', 'code_normalized'));
        $this->assertSame(2, DB::table('subjects')->count());
    }
}
