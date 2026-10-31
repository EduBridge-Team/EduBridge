<?php

namespace Tests\Feature;

use App\Http\Controllers\SchoolDirectorInvitationController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Schema;

class SchoolDirectorInvitationTest extends \Tests\TestCase
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
        Schema::create('school_director_invitations', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->string('email'); $t->string('token_hash')->unique();
            $t->unsignedBigInteger('invited_by'); $t->unsignedBigInteger('expected_director_assignment_id')->nullable();
            $t->timestamp('expires_at'); $t->timestamp('accepted_at')->nullable(); $t->timestamp('revoked_at')->nullable(); $t->timestamps();
        });
        Schema::create('school_administration_events', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('actor_id');
            $t->string('action'); $t->unsignedBigInteger('subject_id')->nullable(); $t->timestamp('created_at');
        });
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('school_administration_events');
        Schema::dropIfExists('school_director_invitations');
        foreach (['school_management_assignments', 'school_accounts', 'schools', 'organization_user', 'organizations', 'email_verification_tokens', 'users'] as $table) {
            Schema::dropIfExists($table);
        }
        parent::tearDown();
    }

    private function fixture(bool $verified = true): void
    {
        DB::table('users')->insert(['id' => 55, 'name' => 'Director', 'email' => 'director@example.test',
            'role' => 'teacher', 'password_hash' => password_hash('StrongPassword123', PASSWORD_BCRYPT),
            'email_verified_at' => $verified ? now() : null]);
        DB::table('schools')->insert(['id' => 44, 'organization_id' => null, 'name' => 'Independent',
            'slug' => 'independent', 'email' => 'director@example.test', 'settings' => '{}', 'is_active' => true]);
        DB::table('school_director_invitations')->insert(['school_id' => 44, 'email' => 'director@example.test',
            'token_hash' => hash('sha256', str_repeat('a', 64)), 'invited_by' => 1,
            'expires_at' => now()->addDay(), 'created_at' => now(), 'updated_at' => now()]);
    }

    private function acceptInvitation(int $user = 55): \Illuminate\Http\JsonResponse
    {
        $request = Request::create('/api/school/director-invitations/accept', 'POST', ['token' => str_repeat('a', 64)]);
        $request->attributes->set('jwt_user', (object) ['id' => $user, 'role' => 'teacher']);
        return app(SchoolDirectorInvitationController::class)->accept($request);
    }

    public function test_verified_mailbox_accepts_once_and_preserves_school(): void
    {
        $this->fixture();
        $this->assertSame(200, $this->acceptInvitation()->getStatusCode());
        $this->assertSame(409, $this->acceptInvitation()->getStatusCode());
        $this->assertSame(1, DB::table('schools')->count());
        $this->assertSame(55, (int) DB::table('school_management_assignments')->value('user_id'));
        $this->assertSame(1, DB::table('school_administration_events')->count());
    }

    public function test_unverified_mailbox_cannot_gain_director_access(): void
    {
        $this->fixture(false);
        $this->assertSame(403, $this->acceptInvitation()->getStatusCode());
        $this->assertSame(0, DB::table('school_management_assignments')->count());
    }

    public function test_another_authenticated_user_cannot_use_invitation(): void
    {
        $this->fixture();
        DB::table('users')->insert(['id' => 56, 'name' => 'Other', 'email' => 'other@example.test',
            'role' => 'teacher', 'password_hash' => 'unused', 'email_verified_at' => now()]);
        $this->assertSame(403, $this->acceptInvitation(56)->getStatusCode());
        $this->assertSame(0, DB::table('school_management_assignments')->count());
    }

    public function test_expired_and_revoked_invites_cannot_grant_access(): void
    {
        $this->fixture();
        DB::table('school_director_invitations')->update(['expires_at' => now()->subSecond()]);
        $this->assertSame(409, $this->acceptInvitation()->getStatusCode());
        DB::table('school_director_invitations')->update(['expires_at' => now()->addDay(), 'revoked_at' => now()]);
        $this->assertSame(409, $this->acceptInvitation()->getStatusCode());
        $this->assertSame(0, DB::table('school_management_assignments')->count());
    }

    public function test_invite_cannot_overwrite_newer_director_appointment(): void
    {
        $this->fixture();
        DB::table('school_management_assignments')->insert(['school_id' => 44, 'user_id' => 99,
            'role' => 'director', 'appointed_by' => 1, 'starts_at' => now(), 'ends_at' => null]);
        $this->assertSame(409, $this->acceptInvitation()->getStatusCode());
        $this->assertSame(99, (int) DB::table('school_management_assignments')->value('user_id'));
    }

    public function test_institution_cannot_list_an_independent_school_invites(): void
    {
        $this->fixture();
        $request = Request::create('/api/admin/schools/44/director-invitations');
        $request->attributes->set('jwt_user', (object) ['id' => 10, 'role' => 'institution']);
        $this->assertSame(403, app(SchoolDirectorInvitationController::class)->index($request, 44)->getStatusCode());
    }

    public function test_invitation_directory_never_exposes_token_hash(): void
    {
        $this->fixture();
        $request = Request::create('/api/admin/schools/44/director-invitations');
        $request->attributes->set('jwt_user', (object) ['id' => 1, 'role' => 'admin']);
        $data = app(SchoolDirectorInvitationController::class)->index($request, 44)->getData(true);
        $this->assertCount(1, $data['invitations']);
        $this->assertArrayNotHasKey('token_hash', $data['invitations'][0]);
    }
}
