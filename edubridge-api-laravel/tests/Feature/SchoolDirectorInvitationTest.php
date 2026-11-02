<?php

namespace Tests\Feature;

use App\Http\Controllers\DedicatedSchoolDirectorController;
use App\Http\Controllers\SchoolDirectorInvitationController;
use App\Support\SchoolDirectorInvitations;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\ValidationException;
use Tests\TestCase;

class SchoolDirectorInvitationTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Mail::fake();
        Schema::create('users', function (Blueprint $t) {
            $t->id(); $t->string('name'); $t->string('email')->unique();
            $t->string('password_hash'); $t->string('role');
            $t->timestamp('email_verified_at')->nullable(); $t->timestamps();
        });
        Schema::create('organizations', function (Blueprint $t) {
            $t->id(); $t->boolean('is_active');
        });
        Schema::create('schools', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id')->nullable();
            $t->string('name'); $t->boolean('is_active');
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
        DB::table('schools')->insert(['id' => 44, 'name' => 'Independent', 'is_active' => true]);
    }

    protected function tearDown(): void
    {
        foreach (['school_director_invitations', 'school_management_assignments', 'schools', 'organizations', 'users'] as $table) {
            Schema::dropIfExists($table);
        }
        parent::tearDown();
    }

    private function issue(string $email = 'new.director@example.test'): void
    {
        DB::table('school_director_invitations')->insert([
            'school_id' => 44, 'email' => $email,
            'token_hash' => hash('sha256', str_repeat('a', 64)),
            'invited_by' => 1, 'expires_at' => now()->addDay(),
            'created_at' => now(), 'updated_at' => now(),
        ]);
    }

    private function activate(string $token = ''): \Illuminate\Http\JsonResponse
    {
        return app(DedicatedSchoolDirectorController::class)->activate(Request::create(
            '/api/school/director-invitations/activate', 'POST', [
                'token' => $token ?: str_repeat('a', 64), 'name' => 'Director',
                'password' => 'VeryStrongPassword123',
                'password_confirmation' => 'VeryStrongPassword123',
            ]
        ));
    }

    public function test_unused_email_creates_dedicated_director_and_token_is_single_use(): void
    {
        $this->issue();
        $this->assertSame(200, $this->activate()->status());
        $user = DB::table('users')->first();
        $this->assertSame('school_director', $user->role);
        $this->assertSame('new.director@example.test', $user->email);
        $this->assertTrue(password_verify('VeryStrongPassword123', $user->password_hash));
        $this->assertNotNull($user->email_verified_at);
        $this->assertSame((int) $user->id, (int) DB::table('school_management_assignments')->value('user_id'));
        $this->assertNotNull(DB::table('school_director_invitations')->value('accepted_at'));
        $this->assertSame(409, $this->activate()->status());
        $this->assertSame(1, DB::table('users')->count());
    }

    public function test_existing_teacher_email_cannot_be_reused_for_director(): void
    {
        DB::table('users')->insert(['name' => 'Teacher', 'email' => 'teacher@example.test',
            'role' => 'teacher', 'password_hash' => 'unused']);
        $this->issue('teacher@example.test');
        $this->assertSame(409, $this->activate()->status());
        $this->assertSame(0, DB::table('school_management_assignments')->count());
    }

    public function test_expired_or_revoked_invites_cannot_create_an_account(): void
    {
        $this->issue();
        DB::table('school_director_invitations')->update(['expires_at' => now()->subSecond()]);
        $this->assertSame(409, $this->activate()->status());
        DB::table('school_director_invitations')->update(['expires_at' => now()->addDay(), 'revoked_at' => now()]);
        $this->assertSame(409, $this->activate()->status());
        $this->assertSame(0, DB::table('users')->count());
    }

    public function test_stale_director_invite_does_not_replace_newer_assignment(): void
    {
        $this->issue();
        DB::table('school_management_assignments')->insert([
            'school_id' => 44, 'user_id' => 99, 'role' => 'director',
            'appointed_by' => 1, 'starts_at' => now(), 'created_at' => now(), 'updated_at' => now(),
        ]);
        $this->assertSame(409, $this->activate()->status());
        $this->assertSame(0, DB::table('users')->count());
    }

    public function test_old_authenticated_accept_endpoint_cannot_promote_existing_users(): void
    {
        $this->assertSame(410, app(SchoolDirectorInvitationController::class)->accept(
            Request::create('/api/school/director-invitations/accept', 'POST', ['token' => str_repeat('a', 64)])
        )->status());
    }

    public function test_invitation_creation_rejects_any_registered_email(): void
    {
        DB::table('users')->insert(['name' => 'Parent', 'email' => 'parent@example.test',
            'role' => 'parent', 'password_hash' => 'unused']);
        $this->expectException(ValidationException::class);
        SchoolDirectorInvitations::issue((object) ['id' => 44, 'name' => 'Independent'], 'parent@example.test', 1);
    }
}
