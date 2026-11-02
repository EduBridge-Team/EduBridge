<?php

namespace Tests\Feature;

use App\Http\Controllers\SchoolProvisionController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class SchoolOfficialEmailProvisionTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('users', function (Blueprint $t) {
            $t->id();
            $t->string('name');
            $t->string('email')->unique();
            $t->string('role');
            $t->timestamp('email_verified_at')->nullable();
            $t->timestamps();
        });
        Schema::create('schools', function (Blueprint $t) {
            $t->id();
            $t->unsignedBigInteger('organization_id')->nullable();
            $t->string('name');
            $t->string('slug')->unique();
            $t->string('email');
            $t->string('official_email')->nullable()->unique();
            $t->timestamp('official_email_verified_at')->nullable();
            $t->string('phone')->nullable();
            $t->string('address')->nullable();
            $t->text('settings');
            $t->boolean('is_active');
            $t->timestamps();
        });
        Schema::create('school_management_assignments', function (Blueprint $t) {
            $t->id();
            $t->unsignedBigInteger('school_id');
            $t->unsignedBigInteger('user_id');
            $t->string('role');
            $t->unsignedBigInteger('appointed_by');
            $t->timestamp('starts_at');
            $t->timestamp('ends_at')->nullable();
            $t->timestamps();
        });
    }

    protected function tearDown(): void
    {
        foreach (['school_management_assignments', 'schools', 'users'] as $table) {
            Schema::dropIfExists($table);
        }
        parent::tearDown();
    }

    private function createSchool(array $payload): \Illuminate\Http\JsonResponse
    {
        $request = Request::create('/api/admin/school-accounts', 'POST', $payload);
        $request->attributes->set('jwt_user', (object) ['id' => 100, 'role' => 'admin']);
        return app(SchoolProvisionController::class)->independent($request);
    }

    public function test_school_can_be_created_without_director_or_password(): void
    {
        $response = $this->createSchool([
            'name' => 'Example School',
            'official_email' => 'SCHOOL@example.test',
        ]);
        $this->assertSame(201, $response->status());
        $body = $response->getData(true);
        $this->assertSame('school@example.test', $body['school']['official_email']);
        $this->assertFalse($body['school']['official_email_verified']);
        $this->assertSame('pending_verification', $body['account_setup']['status']);
        $this->assertArrayNotHasKey('director', $body);
        $this->assertSame(0, DB::table('users')->count());
        $this->assertSame(0, DB::table('school_management_assignments')->count());
        $this->assertNull(DB::table('schools')->value('official_email_verified_at'));
    }

    public function test_official_email_must_be_unique_case_insensitively(): void
    {
        $this->assertSame(201, $this->createSchool([
            'name' => 'First', 'official_email' => 'school@example.test',
        ])->status());
        $this->assertSame(409, $this->createSchool([
            'name' => 'Second', 'official_email' => 'SCHOOL@example.test',
        ])->status());
        $this->assertSame(1, DB::table('schools')->count());
    }

    public function test_school_email_cannot_claim_an_existing_user_identity(): void
    {
        DB::table('users')->insert([
            'name' => 'Director', 'email' => 'taken@example.test',
            'role' => 'teacher', 'created_at' => now(), 'updated_at' => now(),
        ]);
        $this->assertSame(409, $this->createSchool([
            'name' => 'Second', 'official_email' => 'taken@example.test',
        ])->status());
        $this->assertSame(0, DB::table('schools')->count());
    }

    public function test_director_invitation_requires_a_distinct_email(): void
    {
        $this->assertSame(422, $this->createSchool([
            'name' => 'Second',
            'official_email' => 'school@example.test',
            'director_email' => 'school@example.test',
            'invite_director' => true,
        ])->status());
        $this->assertSame(422, $this->createSchool([
            'name' => 'Second', 'official_email' => 'school@example.test',
            'invite_director' => true,
        ])->status());
        $this->assertSame(0, DB::table('schools')->count());
    }
}
