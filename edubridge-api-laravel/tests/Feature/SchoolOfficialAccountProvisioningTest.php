<?php

namespace Tests\Feature;

use App\Http\Controllers\AuthController;
use App\Http\Controllers\SchoolProvisionController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class SchoolOfficialAccountProvisioningTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Mail::fake();
        config()->set('services.jwt.secret', str_repeat('test-jwt-secret-', 4));
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
            $t->string('email'); $t->string('phone')->nullable(); $t->string('address')->nullable();
            $t->text('settings'); $t->boolean('is_active'); $t->timestamps();
        });
        Schema::create('school_accounts', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('user_id'); $t->timestamps();
        });
        Schema::create('school_management_assignments', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('user_id');
            $t->string('role'); $t->unsignedBigInteger('appointed_by');
            $t->timestamp('starts_at'); $t->timestamp('ends_at')->nullable(); $t->timestamps();
        });
        Schema::create('school_director_invitations', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->string('email');
            $t->string('token_hash')->unique(); $t->unsignedBigInteger('invited_by');
            $t->unsignedBigInteger('expected_director_assignment_id')->nullable();
            $t->timestamp('expires_at'); $t->timestamp('accepted_at')->nullable();
            $t->timestamp('revoked_at')->nullable(); $t->timestamps();
        });
        Schema::create('password_reset_tokens', function (Blueprint $t) {
            $t->string('email')->primary(); $t->string('token'); $t->timestamp('created_at');
        });
        DB::table('organizations')->insert(['id' => 4, 'is_active' => true]);
        DB::table('organization_user')->insert([
            'organization_id' => 4, 'user_id' => 10, 'role' => 'owner', 'is_active' => true,
        ]);
    }

    protected function tearDown(): void
    {
        foreach ([
            'password_reset_tokens', 'school_director_invitations',
            'school_management_assignments', 'school_accounts', 'schools',
            'organization_user', 'organizations', 'users',
        ] as $table) Schema::dropIfExists($table);
        parent::tearDown();
    }

    private function create(array $extra = [], bool $affiliated = false): \Illuminate\Http\JsonResponse
    {
        $request = Request::create('/api/admin/school-accounts', 'POST', array_merge([
            'name' => 'Example School', 'email' => 'SCHOOL@example.test',
        ], $extra));
        $request->attributes->set('jwt_user', (object) [
            'id' => $affiliated ? 10 : 1, 'role' => $affiliated ? 'institution' : 'admin',
        ]);
        if ($affiliated) {
            $request->attributes->set('organization', (object) ['id' => 4]);
            return app(SchoolProvisionController::class)->affiliated($request, 'example');
        }
        return app(SchoolProvisionController::class)->independent($request);
    }

    private function personal(string $email, bool $verified = true): int
    {
        return DB::table('users')->insertGetId([
            'name' => 'Personal Director', 'email' => $email, 'role' => 'teacher',
            'password_hash' => password_hash('personal-password-123', PASSWORD_BCRYPT),
            'email_verified_at' => $verified ? now() : null,
            'created_at' => now(), 'updated_at' => now(),
        ]);
    }

    public function test_official_school_email_creates_independent_login_without_director(): void
    {
        $response = $this->create();
        $this->assertSame(201, $response->getStatusCode());
        $body = $response->getData(true);
        $this->assertSame('school@example.test', $body['account']['email']);
        $this->assertSame('school', $body['account']['role']);
        $this->assertTrue($body['account']['activation_pending']);
        $this->assertArrayNotHasKey('password', $body['account']);
        $this->assertArrayNotHasKey('token', $body['account']);
        $this->assertArrayNotHasKey('director', $body);
        $this->assertSame(0, DB::table('school_management_assignments')->count());
        $this->assertSame(1, DB::table('school_accounts')->count());
        $this->assertSame('school@example.test', DB::table('schools')->value('email'));
        $this->assertNull(DB::table('users')->value('email_verified_at'));
        $this->assertSame(64, strlen(DB::table('password_reset_tokens')->value('token')));
        $login = app(AuthController::class)->login(Request::create('/api/auth/login', 'POST', [
            'email' => 'school@example.test', 'password' => 'not-activated',
        ]));
        $this->assertSame(401, $login->getStatusCode());
    }

    public function test_one_time_password_setup_activates_only_the_linked_official_mailbox(): void
    {
        $this->assertSame(201, $this->create()->getStatusCode());
        DB::table('password_reset_tokens')->where('email', 'school@example.test')->update([
            'token' => hash('sha256', 'known-activation-token'),
        ]);
        $request = Request::create('/api/auth/reset-password', 'POST', [
            'email' => 'school@example.test', 'token' => 'known-activation-token',
            'password' => 'school-private-password-123',
        ]);
        $this->assertSame(200, app(AuthController::class)->resetPassword($request)->getStatusCode());
        $this->assertSame(422, app(AuthController::class)->resetPassword($request)->getStatusCode());
        $this->assertNotNull(DB::table('users')->where('email', 'school@example.test')->value('email_verified_at'));
        $login = app(AuthController::class)->login(Request::create('/api/auth/login', 'POST', [
            'email' => 'school@example.test', 'password' => 'school-private-password-123',
        ]));
        $this->assertSame(200, $login->getStatusCode());
        $this->assertSame('school', $login->getData(true)['user']['role']);
        $this->assertSame(1, DB::table('school_accounts')->count());
    }

    public function test_verified_director_has_separate_personal_identity_and_unchanged_password(): void
    {
        $directorId = $this->personal('director@example.test');
        $passwordHash = DB::table('users')->where('id', $directorId)->value('password_hash');
        $response = $this->create(['director_email' => 'director@example.test'], true);
        $this->assertSame(201, $response->getStatusCode());
        $body = $response->getData(true);
        $this->assertSame(4, $body['school']['organization_id']);
        $this->assertSame($directorId, $body['director']['id']);
        $this->assertNotSame($directorId, $body['account']['id']);
        $this->assertSame($passwordHash, DB::table('users')->where('id', $directorId)->value('password_hash'));
        $this->assertSame('teacher', DB::table('users')->where('id', $directorId)->value('role'));
        $this->assertSame($directorId, (int) DB::table('school_management_assignments')->value('user_id'));
        $this->assertSame(2, DB::table('users')->count());
    }

    public function test_director_invitation_does_not_replace_school_account(): void
    {
        $response = $this->create([
            'director_email' => 'invitee@example.test', 'invite_director' => true,
        ]);
        $this->assertSame(201, $response->getStatusCode());
        $this->assertArrayHasKey('invitation', $response->getData(true));
        $this->assertSame('invitee@example.test', DB::table('school_director_invitations')->value('email'));
        $this->assertSame('school@example.test', DB::table('users')->value('email'));
        $this->assertSame(0, DB::table('school_management_assignments')->count());
    }

    public function test_invalid_and_duplicate_school_mailboxes_do_not_create_partial_schools(): void
    {
        $this->assertSame(422, $this->create(['email' => 'director@school.edubridge'])->getStatusCode());
        $this->assertSame(422, $this->create(['director_email' => 'school@example.test'])->getStatusCode());
        $this->assertSame(422, $this->create(['invite_director' => true])->getStatusCode());
        $this->assertSame(0, DB::table('schools')->count());
        $this->assertSame(201, $this->create()->getStatusCode());
        $this->assertSame(409, $this->create()->getStatusCode());
        $this->assertSame(1, DB::table('schools')->count());
        $this->assertSame(1, DB::table('school_accounts')->count());
    }

    public function test_unverified_personal_director_cannot_receive_direct_appointment(): void
    {
        $this->personal('unverified@example.test', false);
        $this->assertSame(422, $this->create(['director_email' => 'unverified@example.test'])->getStatusCode());
        $this->assertSame(0, DB::table('schools')->count());
    }
}
