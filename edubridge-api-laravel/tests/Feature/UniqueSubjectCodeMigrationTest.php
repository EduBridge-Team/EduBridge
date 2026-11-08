<?php

namespace Tests\Feature;

use App\Support\SubjectCode;
use Illuminate\Database\QueryException;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

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

    private function indexExists(): bool
    {
        return collect(DB::select("PRAGMA index_list('subjects')"))
            ->contains(fn ($index) => $index->name === 'subjects_school_normalized_code_unique');
    }

    public function test_migration_preserves_legacy_codes_and_allows_null_or_blank_codes(): void
    {
        DB::table('subjects')->insert([
            ['id' => 1, 'school_id' => 1, 'name' => 'Math', 'code' => ' math '],
            ['id' => 2, 'school_id' => 1, 'name' => 'Arabic', 'code' => null],
            ['id' => 3, 'school_id' => 1, 'name' => 'English', 'code' => " \t "],
            ['id' => 4, 'school_id' => 2, 'name' => 'Math', 'code' => 'MATH'],
        ]);

        $migration = require database_path('migrations/2026_11_08_110000_add_unique_normalized_subject_codes.php');
        $migration->up();

        $this->assertTrue($this->indexExists());
        $this->assertSame(' math ', DB::table('subjects')->where('id', 1)->value('code'));
        $normalizedSql = SubjectCode::normalizedSql();
        $this->assertSame('MATH', DB::selectOne('SELECT ' . $normalizedSql . ' AS normalized FROM subjects WHERE id = 1')->normalized);
        $this->assertNull(DB::selectOne('SELECT ' . $normalizedSql . ' AS normalized FROM subjects WHERE id = 2')->normalized);
        $this->assertNull(DB::selectOne('SELECT ' . $normalizedSql . ' AS normalized FROM subjects WHERE id = 3')->normalized);
        $this->assertSame('MATH', DB::selectOne('SELECT ' . $normalizedSql . ' AS normalized FROM subjects WHERE id = 4')->normalized);

        DB::table('subjects')->insert([
            ['id' => 5, 'school_id' => 1, 'name' => 'Blank', 'code' => '   '],
            ['id' => 6, 'school_id' => 1, 'name' => 'Null', 'code' => null],
        ]);

        $migration->down();
        $this->assertFalse($this->indexExists());
        $this->assertSame(6, DB::table('subjects')->count());
    }

    public function test_migration_reports_legacy_normalized_duplicates_without_mutating_schema(): void
    {
        DB::table('subjects')->insert([
            ['id' => 1, 'school_id' => 1, 'name' => 'Math', 'code' => 'math'],
            ['id' => 2, 'school_id' => 1, 'name' => 'Mathematics', 'code' => "\t MATH \t"],
        ]);

        $migration = require database_path('migrations/2026_11_08_110000_add_unique_normalized_subject_codes.php');

        try {
            $migration->up();
            $this->fail('Expected legacy duplicate preflight to stop the migration.');
        } catch (\RuntimeException $exception) {
            $this->assertStringContainsString('subject IDs: 1, 2', $exception->getMessage());
        }

        $this->assertFalse($this->indexExists());
        $this->assertSame(2, DB::table('subjects')->count());
    }

    public function test_migration_index_catches_direct_duplicate_inserts(): void
    {
        DB::table('subjects')->insert(['id' => 1, 'school_id' => 1, 'name' => 'Math', 'code' => 'math']);
        $migration = require database_path('migrations/2026_11_08_110000_add_unique_normalized_subject_codes.php');
        $migration->up();

        $this->expectException(QueryException::class);
        DB::table('subjects')->insert(['id' => 2, 'school_id' => 1, 'name' => 'Mathematics', 'code' => ' MATH ']);
    }

    public function test_rollback_removes_the_database_unique_constraint(): void
    {
        DB::table('subjects')->insert(['id' => 1, 'school_id' => 1, 'name' => 'Math', 'code' => 'math']);
        $migration = require database_path('migrations/2026_11_08_110000_add_unique_normalized_subject_codes.php');
        $migration->up();
        $this->assertTrue($this->indexExists());

        $migration->down();
        $this->assertFalse($this->indexExists());
        DB::table('subjects')->insert(['id' => 2, 'school_id' => 1, 'name' => 'Mathematics', 'code' => ' MATH ']);
        $this->assertSame(2, DB::table('subjects')->count());
    }
}
