<?php

namespace Tests\Feature;

use App\Http\Controllers\InstitutionAcademicController;
use Illuminate\Database\QueryException;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\ValidationException;
use Tests\TestCase;

class InstitutionSubjectCodeUniquenessTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Schema::create('schools', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('organization_id');
        });
        Schema::create('subjects', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('school_id');
            $table->string('name', 120);
            $table->string('code', 40)->nullable();
            $table->string('code_normalized', 40)->nullable();
            $table->string('color', 20)->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->unique(['school_id', 'code_normalized'], 'subjects_school_normalized_code_unique');
        });

        DB::table('schools')->insert([
            ['id' => 1, 'organization_id' => 10],
            ['id' => 2, 'organization_id' => 10],
        ]);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('subjects');
        Schema::dropIfExists('schools');
        parent::tearDown();
    }

    private function createSubject(int $school, string $name, ?string $code): \Illuminate\Http\JsonResponse
    {
        $request = Request::create('/api/institutions/test/schools/'.$school.'/subjects', 'POST', [
            'name' => $name,
            'code' => $code,
        ]);
        $request->attributes->set('organization', (object) ['id' => 10, 'slug' => 'test']);

        return app(InstitutionAcademicController::class)->storeSubject($request, 'test', $school);
    }

    public function test_codes_are_trimmed_uppercased_and_unique_within_a_school(): void
    {
        $response = $this->createSubject(1, 'Mathematics', '  math  ');

        $this->assertSame(201, $response->getStatusCode());
        $this->assertDatabaseHas('subjects', [
            'school_id' => 1,
            'code' => 'MATH',
            'code_normalized' => 'MATH',
        ]);

        $this->expectException(ValidationException::class);
        $this->createSubject(1, 'Science', 'math');
    }

    public function test_same_code_is_allowed_in_another_school(): void
    {
        $this->assertSame(201, $this->createSubject(1, 'Mathematics', 'MATH')->getStatusCode());
        $this->assertSame(201, $this->createSubject(2, 'Mathematics', 'MATH')->getStatusCode());
    }

    public function test_multiple_legacy_or_new_null_codes_are_allowed(): void
    {
        $this->assertSame(201, $this->createSubject(1, 'Arabic', null)->getStatusCode());
        $this->assertSame(201, $this->createSubject(1, 'English', '   ')->getStatusCode());
        $this->assertSame(2, DB::table('subjects')->where('school_id', 1)->whereNull('code_normalized')->count());
    }

    public function test_database_constraint_rejects_duplicate_normalized_codes(): void
    {
        DB::table('subjects')->insert([
            'school_id' => 1, 'name' => 'Mathematics', 'code' => 'MATH',
            'code_normalized' => 'MATH', 'is_active' => true,
            'created_at' => now(), 'updated_at' => now(),
        ]);

        $this->expectException(QueryException::class);
        DB::table('subjects')->insert([
            'school_id' => 1, 'name' => 'Math', 'code' => 'math',
            'code_normalized' => 'MATH', 'is_active' => true,
            'created_at' => now(), 'updated_at' => now(),
        ]);
    }
}
