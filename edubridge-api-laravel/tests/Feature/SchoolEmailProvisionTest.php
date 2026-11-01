<?php

namespace Tests\Feature;

use App\Http\Controllers\AuthController;
use App\Http\Controllers\SchoolProvisionController;
use App\Support\SchoolScopedAccess;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class SchoolEmailProvisionTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Mail::fake();
        config()->set('services.jwt.secret', str_repeat('school-test-secret-', 4));
        Schema::create('users', function (Blueprint $t) {
            $t->id(); $t->string('name'); $t->string('email')->unique();
            $t->string('password_hash'); $t->string('role');
            $t->timestamp('email_verified_at')->nullable(); $t->timestamps();
        });
        Schema::create('organizations', function (Blueprint $t) {
            $t->id(); $t->boolean('is_active');
        });
        Schema::create('organization_user', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id');
            $t->unsignedBigInteger('user_id'); $t->string('role'); $t->boolean('is_active');
        });
        Schema::create('schools', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id')->nullable();
            $t->string('name'); $t->string('slug')->unique();
            $t->string('address')->nullable(); $t->string('phone')->nullable();
            $t->string('email'); $t->text('settings'); $t->boolean('is_active'); $t->timestamps();
        });
        Schema::create('school_accounts', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id')->unique();
            $t->unsignedBigInteger('user_id')->unique(); $t->timestamps();
        });
        Schema::create('school_management_assignments', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('user_id');
            $t->string('role'); $t->unsignedBigInteger('appointed_by');
            $t->timestamp('starts_at'); $t->timestamp('ends_at')->nullable(); $t->timestamps();
        });
        Schema::create('email_verification_tokens', function (Blueprint $t) {
            $t->string('email')->primary(); $t->string('token'); $t->timestamp('created_at');
        });
        DB::table('organizations')->insert(['id' => 5, 'is_active' => true]);
        DB::table('organization_user')->insert([
            'organization_id' => 5, 'user_id' => 7, 'role' => 'owner', 'is_active' => true,
        ]);
    }

    protected function tearDown(): void
    {
        foreach (['email_verification_tokens', 'school_management_assignments', 'school_accounts',
            'schools', 'organization_user', 'organizations', 'users'] as $table) {
            Schema::dropIfExists($table);
        }
        parent::tearDown();
    }

    private function provision(bool $affiliated = false, array $override = []): \Illuminate\Http\JsonResponse
    {
        $payload = array_merge([
            'name' => 'Test School', 'email' => 'SCHOOL@EXAMPLE.ORG',
            'password' => 'school-password-12345',
            'password_confirmation' => 'school-password-12345',
        ], $override);
        $request = Request::create('/api/school-accounts', 'POST', $payload);
        $request->attributes->set('jwt_user', (object) [
            'id' => $affiliated ? 7 : 1, 'role' => $affiliated ? 'institution' : 'admin',
        ]);
        if ($affiliated) {
            $request->attributes->set('organization', (object) ['id' => 5]);
            return app(SchoolProvisionController::class)->affiliated($request, 'example');
        }
        return app(SchoolProvisionController::class)->independent($request);
    }

    public function test_school_email_creates_its_own_login_without_assigning_director(): void
    {
        $response = $this->provision();
        $this->assertSame(201, $response->getStatusCode());
        $payload = $response->getData(true);
        $this->assertSame('school@example.org', $payload['account']['email']);
        $this->assertSame('school', $payload['account']['role']);
        $this->assertNull($payload['school']['organization_id']);
        $this->assertSame('school@example.org', $payload['school']['email']);
        $this->assertArrayNotHasKey('password', $payload);
        $this->assertArrayNotHasKey('director', $payload);
        $this->assertSame(0, DB::table('school_management_assignments')->count());
        $this->assertSame(1, DB::table('school_accounts')->count());
        $this->assertSame(1, DB::table('email_verification_tokens')->count());
        $user = DB::table('users')->first();
        $this->assertSame('school', $user->role);
        $this->assertNull($user->email_verified_at);
        $this->assertTrue(password_verify('school-password-12345', $user->password_hash));
        $this->assertStringNotContainsString('school-password-12345', $user->password_hash);

        $login = fn () => app(AuthController::class)->login(Request::create('/api/auth/login', 'POST', [
            'email' => 'school@example.org', 'password' => 'school-password-12345',
        ]));
        $this->assertSame(403, $login()->getStatusCode());
        DB::table('users')->update(['email_verified_at' => now()]);
        $this->assertSame(200, $login()->getStatusCode());

        $request = Request::create('/api/school/context', 'GET');
        $request->attributes->set('jwt_user', (object) ['id' => $user->id, 'role' => 'school']);
        $this->assertSame($payload['school']['id'], (int) SchoolScopedAccess::resolve($request, 'context')->id);
    }

    public function test_affiliated_school_identity_is_scoped_to_its_institution(): void
    {
        $response = $this->provision(true);
        $this->assertSame(201, $response->getStatusCode());
        $this->assertSame(5, $response->getData(true)['school']['organization_id']);
        $user = DB::table('users')->first();
        DB::table('users')->update(['email_verified_at' => now()]);
        $request = Request::create('/api/school/context', 'GET');
        $request->attributes->set('jwt_user', (object) ['id' => $user->id, 'role' => 'school']);
        $this->assertNotNull(SchoolScopedAccess::resolve($request, 'context'));
        DB::table('organizations')->where('id', 5)->update(['is_active' => false]);
        $this->assertNull(SchoolScopedAccess::resolve($request, 'context'));
    }

    public function test_duplicate_school_mailbox_does_not_create_partial_records(): void
    {
        $this->assertSame(201, $this->provision()->getStatusCode());
        $this->assertSame(409, $this->provision(true)->getStatusCode());
        $this->assertSame(1, DB::table('schools')->count());
        $this->assertSame(1, DB::table('users')->count());
        $this->assertSame(1, DB::table('school_accounts')->count());
    }

    public function test_invalid_credentials_and_director_fields_are_rejected(): void
    {
        foreach ([
            ['password_confirmation' => 'different-password'],
            ['password' => 'too-short', 'password_confirmation' => 'too-short'],
            ['email' => 'staff@school.edubridge'],
            ['director_email' => 'director@example.org'],
        ] as $input) {
            $this->assertSame(422, $this->provision(false, $input)->getStatusCode());
        }
        $this->assertSame(0, DB::table('schools')->count());
    }

    public function test_existing_personal_account_cannot_be_repurposed_as_school_login(): void
    {
        DB::table('users')->insert([
            'name' => 'Director', 'email' => 'school@example.org', 'role' => 'teacher',
            'password_hash' => password_hash('existing-secret', PASSWORD_BCRYPT),
            'email_verified_at' => now(), 'created_at' => now(), 'updated_at' => now(),
        ]);
        $this->assertSame(409, $this->provision()->getStatusCode());
        $this->assertSame('teacher', DB::table('users')->value('role'));
        $this->assertSame(0, DB::table('schools')->count());
    }
}
