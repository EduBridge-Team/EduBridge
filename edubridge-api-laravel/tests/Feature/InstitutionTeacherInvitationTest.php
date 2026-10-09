<?php

namespace Tests\Feature;

use App\Http\Controllers\InstitutionTeacherInvitationController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class InstitutionTeacherInvitationTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('users', function (Blueprint $t) {
            $t->id(); $t->string('name'); $t->string('email');
            $t->string('role'); $t->timestamp('email_verified_at')->nullable();
        });
        Schema::create('organization_user', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id'); $t->unsignedBigInteger('user_id');
            $t->string('role'); $t->boolean('is_active'); $t->timestamps();
        });
        Schema::create('institution_teacher_invitations', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id'); $t->string('email');
            $t->string('token_hash'); $t->unsignedBigInteger('invited_by');
            $t->timestamp('expires_at'); $t->timestamp('accepted_at')->nullable();
            $t->timestamp('revoked_at')->nullable(); $t->timestamps();
        });
        DB::table('users')->insert([
            ['id' => 1, 'name' => 'Teacher', 'email' => 'teacher@example.com', 'role' => 'teacher', 'email_verified_at' => now()],
            ['id' => 2, 'name' => 'Other', 'email' => 'other@example.com', 'role' => 'teacher', 'email_verified_at' => now()],
        ]);
        DB::table('institution_teacher_invitations')->insert([
            'id' => 1, 'organization_id' => 1, 'email' => 'teacher@example.com',
            'token_hash' => hash('sha256', str_repeat('a', 64)), 'invited_by' => 2,
            'expires_at' => now()->addDays(2), 'created_at' => now(), 'updated_at' => now(),
        ]);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('institution_teacher_invitations');
        Schema::dropIfExists('organization_user');
        Schema::dropIfExists('users');
        parent::tearDown();
    }

    private function acceptAs(int $user): \Illuminate\Http\JsonResponse
    {
        $request = Request::create('/api/teacher-invitations/accept', 'POST', ['token' => str_repeat('a', 64)]);
        $request->attributes->set('jwt_user', (object) ['id' => $user]);
        return app(InstitutionTeacherInvitationController::class)->accept($request);
    }

    public function test_only_matching_verified_teacher_can_accept_invitation(): void
    {
        $this->assertSame(422, $this->acceptAs(2)->getStatusCode());
        $this->assertSame(0, DB::table('organization_user')->count());
        $this->assertSame(200, $this->acceptAs(1)->getStatusCode());
        $this->assertDatabaseHas('organization_user', [
            'organization_id' => 1, 'user_id' => 1, 'role' => 'teacher', 'is_active' => true,
        ]);
        $this->assertSame(422, $this->acceptAs(1)->getStatusCode());
    }

    public function test_expired_invitation_is_rejected(): void
    {
        DB::table('institution_teacher_invitations')->where('id', 1)->update(['expires_at' => now()->subDay()]);
        $this->assertSame(422, $this->acceptAs(1)->getStatusCode());
        $this->assertSame(0, DB::table('organization_user')->count());
    }
}
