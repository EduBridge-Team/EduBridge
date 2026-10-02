<?php

namespace Tests\Feature;

use App\Support\AuthCredentials;
use Firebase\JWT\JWT;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class IdentityVerificationMiddlewareTest extends TestCase
{
    private const SECRET = 'identity-route-test-secret-32-bytes-minimum';

    protected function setUp(): void
    {
        parent::setUp();
        config(['services.jwt.secret' => self::SECRET]);
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('email');
            $table->string('role');
            $table->string('password_hash');
            $table->string('verification_status');
        });
        Schema::create('disability_types', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->text('description')->nullable();
        });
        DB::table('users')->insert(['id' => 1, 'name' => 'Parent', 'email' => 'parent@example.test',
            'role' => 'parent', 'password_hash' => 'credential', 'verification_status' => 'pending']);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('disability_types');
        Schema::dropIfExists('users');
        parent::tearDown();
    }

    private function headers(): array
    {
        $user = DB::table('users')->find(1);
        return ['Authorization' => 'Bearer ' . JWT::encode(['id' => 1, 'role' => $user->role,
            'exp' => time() + 300, 'credential_stamp' => AuthCredentials::stamp($user, self::SECRET)], self::SECRET, 'HS256')];
    }

    public function test_pending_and_rejected_accounts_cannot_bypass_ui_but_can_open_profile(): void
    {
        foreach (['pending', 'rejected'] as $status) {
            DB::table('users')->where('id', 1)->update(['verification_status' => $status]);
            $this->getJson('/api/children', $this->headers())->assertForbidden()->assertJsonPath('code', 'IDENTITY_NOT_VERIFIED');
            $this->getJson('/api/me', $this->headers())->assertOk()->assertJsonPath('user.id', 1);
        }
    }

    public function test_verified_accounts_and_admin_are_allowed_and_revocation_is_immediate(): void
    {
        DB::table('users')->where('id', 1)->update(['verification_status' => 'verified']);
        $headers = $this->headers();
        $this->getJson('/api/disability-types', $headers)->assertOk();
        DB::table('users')->where('id', 1)->update(['verification_status' => 'rejected']);
        $this->getJson('/api/disability-types', $headers)->assertForbidden();
        DB::table('users')->where('id', 1)->update(['role' => 'admin']);
        $this->getJson('/api/disability-types', $this->headers())->assertOk();
    }
}
