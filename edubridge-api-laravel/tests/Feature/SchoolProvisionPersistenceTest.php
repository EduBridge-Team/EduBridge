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

    public function test_school_creation_reuses_verified_personal_identity_without_changing_credentials(): void
    {
        $id = $this->personal('director@example.test');
        $hash = DB::table('users')->where('id', $id)->value('password_hash');
        $response = $this->provision(false, 'DIRECTOR@example.test');
        $this->assertSame(201, $response->getStatusCode());
        $receipt = $response->getData(true);
        $this->assertSame($id, $receipt['director']['id']);
        $this->assertNull($receipt['school']['organization_id']);
        $this->assertArrayNotHasKey('account', $receipt);
        $this->assertSame(1, DB::table('users')->count());
        $this->assertSame(0, DB::table('school_accounts')->count());
        $this->assertSame($hash, DB::table('users')->where('id', $id)->value('password_hash'));
        $this->assertSame('teacher', DB::table('users')->where('id', $id)->value('role'));
        $this->assertSame($receipt['school']['id'], $this->context($id)->getData(true)['school']['id']);
        $this->assertSame(1, DB::table('school_management_assignments')->where('appointed_by', 1)->count());
        Mail::assertNothingSent();
    }

    public function test_affiliated_school_and_director_access_follow_tenant_state(): void
    {
        $id = $this->personal('affiliated@example.test');
        $response = $this->provision(true, 'affiliated@example.test');
        $this->assertSame(201, $response->getStatusCode());
        $this->assertSame(1, $response->getData(true)['school']['organization_id']);
        $this->assertSame(200, $this->context($id)->getStatusCode());
        DB::table('organizations')->where('id', 1)->update(['is_active' => false]);
        $this->assertSame(403, $this->context($id)->getStatusCode());
    }

    public function test_missing_unverified_internal_and_legacy_directors_cannot_create_a_school(): void
    {
        $this->personal('unverified@example.test', false);
        $this->personal('deputy@school.edubridge');
        $this->personal('legacy@example.test', true, 'school');
        foreach (['missing@example.test', 'unverified@example.test', 'deputy@school.edubridge', 'legacy@example.test'] as $email) {
            $this->assertSame(422, $this->provision(false, $email)->getStatusCode());
        }
        $this->assertSame(0, DB::table('schools')->count());
        $this->assertSame(0, DB::table('school_management_assignments')->count());
    }

    public function test_approval_status_does_not_replace_mailbox_verification(): void
    {
        Schema::table('users', fn (Blueprint $t) => $t->string('verification_status')->nullable());
        $id = $this->personal('approved@example.test', false);
        DB::table('users')->where('id', $id)->update(['verification_status' => 'approved']);
        $this->assertSame(422, $this->provision(false, 'approved@example.test')->getStatusCode());
        $this->assertSame(0, DB::table('schools')->count());
    }

    public function test_duplicate_active_director_assignment_is_rejected_without_partial_school(): void
    {
        $this->personal('director@example.test');
        $this->assertSame(201, $this->provision(false, 'director@example.test')->getStatusCode());
        $this->assertSame(409, $this->provision(true, 'director@example.test')->getStatusCode());
        $this->assertSame(1, DB::table('schools')->count());
        $this->assertSame(1, DB::table('school_management_assignments')->count());
    }

    public function test_ended_assignment_removes_access_and_allows_new_school(): void
    {
        $id = $this->personal('director@example.test');
        $this->assertSame(201, $this->provision(false, 'director@example.test')->getStatusCode());
        DB::table('school_management_assignments')->where('user_id', $id)->update(['ends_at' => now()]);
        $this->assertSame(403, $this->context($id)->getStatusCode());
        $this->assertSame(201, $this->provision(true, 'director@example.test')->getStatusCode());
        $this->assertSame(2, DB::table('schools')->count());
        $this->assertSame(1, $this->context($id)->getData(true)['school']['organization_id']);
    }

    public function test_verified_director_logs_in_with_existing_personal_credentials(): void
    {
        $id = $this->personal('director@example.test');
        $this->assertSame(201, $this->provision(false, 'director@example.test')->getStatusCode());
        $login = app(AuthController::class)->login(Request::create('/api/auth/login', 'POST', [
            'email' => 'director@example.test', 'password' => 'long-test-password-123',
        ]));
        $this->assertSame(200, $login->getStatusCode());
        $this->assertSame($id, $login->getData(true)['user']['id']);
        $this->assertSame('teacher', $login->getData(true)['user']['role']);
        $this->assertNotEmpty($login->getData(true)['token']);
    }

    public function test_blank_school_name_is_rejected(): void
    {
        $this->personal('director@example.test');
        $this->assertSame(422, $this->provision(false, 'director@example.test', '   ')->getStatusCode());
        $this->assertSame(0, DB::table('schools')->count());
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
