<?php

namespace Tests\Feature;

use App\Http\Controllers\SchoolContextController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\SchoolProvisionController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class SchoolProvisionPersistenceTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Mail::fake();
        // Login issues a signed token: use a deterministic test-only secret.
        config()->set('services.jwt.secret', str_repeat('test-jwt-secret-', 4));
        Schema::create('users', function (Blueprint $t) {
            $t->id(); $t->string('name'); $t->string('email')->unique();
            $t->string('password_hash'); $t->string('role');
            $t->timestamp('email_verified_at')->nullable(); $t->timestamps();
        });
        Schema::create('email_verification_tokens', function (Blueprint $t) {
            $t->string('email')->primary(); $t->string('token'); $t->timestamp('created_at');
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
            $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('user_id'); $t->timestamps();
        });
        Schema::create('school_management_assignments', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('user_id');
            $t->string('role'); $t->unsignedBigInteger('appointed_by');
            $t->timestamp('starts_at'); $t->timestamp('ends_at')->nullable(); $t->timestamps();
        });
        DB::table('organizations')->insert(['id' => 1, 'is_active' => true]);
        DB::table('organization_user')->insert([
            'organization_id' => 1, 'user_id' => 10, 'role' => 'owner', 'is_active' => true,
        ]);
    }

    protected function tearDown(): void
    {
        foreach (['school_management_assignments', 'school_accounts', 'schools', 'organization_user', 'organizations', 'email_verification_tokens', 'users'] as $table) {
            Schema::dropIfExists($table);
        }
        parent::tearDown();
    }

    private function provision(bool $affiliated, string $email, string $name = 'Example School'): \Illuminate\Http\JsonResponse
    {
        $request = Request::create('/api/school-accounts', 'POST', [
            'name' => $name, 'director_email' => $email,
        ]);
        $request->attributes->set('jwt_user', (object) [
            'id' => $affiliated ? 10 : 1, 'role' => $affiliated ? 'institution' : 'admin',
        ]);
        if ($affiliated) {
            $request->attributes->set('organization', (object) ['id' => 1]);
            return app(SchoolProvisionController::class)->affiliated($request, 'example');
        }
        return app(SchoolProvisionController::class)->independent($request);
    }

    private function personal(string $email, bool $verified = true, string $role = 'teacher'): int
    {
        return DB::table('users')->insertGetId([
            'name' => 'Personal Director', 'email' => $email, 'role' => $role,
            'password_hash' => password_hash('long-test-password-123', PASSWORD_BCRYPT),
            'email_verified_at' => $verified ? now() : null,
            'created_at' => now(), 'updated_at' => now(),
        ]);
    }

    private function context(int $user): \Illuminate\Http\JsonResponse
    {
        $request = Request::create('/api/school/context', 'GET', ['school_id' => 999]);
        $request->attributes->set('jwt_user', (object) ['id' => $user, 'role' => 'teacher']);
        return app(SchoolContextController::class)->show($request);
    }

    public function test_existing_teacher_account_cannot_be_reused_as_director(): void
    {
        $id = $this->personal('director@example.test');
        $hash = DB::table('users')->where('id', $id)->value('password_hash');
        $this->assertSame(422, $this->provision(false, 'director@example.test')->status());
        $this->assertSame(0, DB::table('schools')->count());
        $this->assertSame(0, DB::table('school_management_assignments')->count());
        $this->assertSame($hash, DB::table('users')->where('id', $id)->value('password_hash'));
    }

    public function test_no_legacy_director_role_can_create_school_through_old_payload(): void
    {
        foreach (['teacher', 'specialist', 'parent', 'student', 'school'] as $role) {
            $email = $role.'@example.test';
            $this->personal($email, true, $role);
            $this->assertSame(422, $this->provision(false, $email)->status());
        }
        $this->assertSame(0, DB::table('schools')->count());
        $this->assertSame(0, DB::table('school_management_assignments')->count());
    }

    // Existing school accounts keep their original email verification lifecycle.
    private function legacySchool(bool $affiliated, string $email): \Illuminate\Http\JsonResponse
    {
        $id = $this->personal($email, false, 'school');
        $school = DB::table('schools')->insertGetId([
            'organization_id' => $affiliated ? 1 : null, 'name' => 'Legacy School',
            'slug' => 'legacy-school', 'email' => $email, 'settings' => '{}', 'is_active' => true,
            'created_at' => now(), 'updated_at' => now(),
        ]);
        DB::table('school_accounts')->insert(['school_id' => $school, 'user_id' => $id]);
        app(\App\Support\EmailVerificationSender::class)->send(DB::table('users')->find($id));
        return response()->json(['school' => ['id' => $school], 'account' => ['id' => $id]], 201);
    }

    public function test_school_email_verification_rejects_invalid_and_expired_tokens(): void
    {
        $email = 'verify-school@example.test';
        $created = $this->legacySchool(false, $email);
        $this->assertSame(201, $created->getStatusCode());

        $record = DB::table('email_verification_tokens')->where('email', $email)->first();
        $this->assertNotNull($record);
        $this->assertSame(64, strlen($record->token));
        $this->assertNull(DB::table('users')->where('email', $email)->value('email_verified_at'));

        $invalid = Request::create('/api/auth/verify-email', 'GET', [
            'email' => $email, 'token' => 'incorrect-verification-token',
        ]);
        $response = app(AuthController::class)->verifyEmail($invalid);
        $this->assertSame(302, $response->getStatusCode());
        $this->assertStringContainsString('verified=0', $response->headers->get('Location'));
        $this->assertNull(DB::table('users')->where('email', $email)->value('email_verified_at'));

        DB::table('email_verification_tokens')->where('email', $email)
            ->update(['token' => hash('sha256', 'known-expired-token'),
                'created_at' => now()->subHours(25)]);
        $expiredRequest = Request::create('/api/auth/verify-email', 'GET', [
            'email' => $email, 'token' => 'known-expired-token',
        ]);
        $expired = app(AuthController::class)->verifyEmail($expiredRequest);
        $this->assertSame(302, $expired->getStatusCode());
        $this->assertStringContainsString('verified=0', $expired->headers->get('Location'));
        $this->assertNull(DB::table('users')->where('email', $email)->value('email_verified_at'));
    }

    public function test_verified_school_email_link_is_single_use_and_allows_login(): void
    {
        $email = 'single-use-school@example.test';
        $created = $this->legacySchool(false, $email);
        $this->assertSame(201, $created->getStatusCode());
        $this->assertSame(403, app(AuthController::class)->login(
            Request::create('/api/auth/login', 'POST', [
                'email' => $email, 'password' => 'long-test-password-123',
            ])
        )->getStatusCode());

        // The plaintext verification token exists only in the email;
        // simulate that delivered token using a known hash in test storage.
        $plaintextToken = 'fixture-verification-token';
        DB::table('email_verification_tokens')->where('email', $email)
            ->update([
                'token' => hash('sha256', $plaintextToken),
                'created_at' => now(),
            ]);
        $verifyRequest = Request::create('/api/auth/verify-email', 'GET', [
            'email' => $email, 'token' => $plaintextToken,
        ]);
        $verified = app(AuthController::class)->verifyEmail($verifyRequest);
        $this->assertSame(302, $verified->getStatusCode());
        $this->assertStringContainsString('verified=1', $verified->headers->get('Location'));
        $this->assertNotNull(DB::table('users')->where('email', $email)->value('email_verified_at'));
        $this->assertSame(0, DB::table('email_verification_tokens')->where('email', $email)->count());

        $replayed = app(AuthController::class)->verifyEmail($verifyRequest);
        $this->assertSame(302, $replayed->getStatusCode());
        $this->assertStringContainsString('verified=0', $replayed->headers->get('Location'));

        $login = app(AuthController::class)->login(
            Request::create('/api/auth/login', 'POST', [
                'email' => $email, 'password' => 'long-test-password-123',
            ])
        );
        $this->assertSame(200, $login->getStatusCode());
        $this->assertSame('school', $login->getData(true)['user']['role']);
        $this->assertNotEmpty($login->getData(true)['token']);
    }

    public function test_affiliated_school_can_activate_email_then_login_in_own_school_context(): void
    {
        $email = 'activation-affiliated@example.test';
        $created = $this->legacySchool(true, $email);
        $this->assertSame(201, $created->getStatusCode());
        $schoolId = $created->getData(true)['school']['id'];

        $token = 'affiliated-verification-fixture';
        DB::table('email_verification_tokens')->where('email', $email)
            ->update(['token' => hash('sha256', $token), 'created_at' => now()]);
        $verification = Request::create('/api/auth/verify-email', 'GET', [
            'email' => $email, 'token' => $token,
        ]);
        $response = app(AuthController::class)->verifyEmail($verification);
        $this->assertSame(302, $response->getStatusCode());
        $this->assertStringContainsString('verified=1', $response->headers->get('Location'));
        $this->assertNotNull(DB::table('users')->where('email', $email)->value('email_verified_at'));

        $login = app(AuthController::class)->login(Request::create('/api/auth/login', 'POST', [
            'email' => $email, 'password' => 'long-test-password-123',
        ]));
        $this->assertSame(200, $login->getStatusCode());
        $this->assertSame('school', $login->getData(true)['user']['role']);

        $contextRequest = Request::create('/api/school/context', 'GET');
        $contextRequest->attributes->set('jwt_user', (object) [
            'id' => $login->getData(true)['user']['id'], 'role' => 'school',
        ]);
        $context = app(SchoolContextController::class)->show($contextRequest);
        $this->assertSame(200, $context->getStatusCode());
        $this->assertSame($schoolId, $context->getData(true)['school']['id']);
        $this->assertSame(1, $context->getData(true)['school']['organization_id']);
    }

}
