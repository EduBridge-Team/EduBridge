<?php

namespace Tests\Feature;

use App\Http\Controllers\SchoolAccountActivationController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class SchoolAccountActivationTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Mail::fake();
        Schema::create('users', function (Blueprint $t) {
            $t->id(); $t->string('name'); $t->string('email')->unique();
            $t->string('role'); $t->string('password_hash');
            $t->timestamp('email_verified_at')->nullable(); $t->timestamps();
        });
        Schema::create('schools', function (Blueprint $t) {
            $t->id(); $t->string('name'); $t->string('official_email')->nullable()->unique();
            $t->timestamp('official_email_verified_at')->nullable();
            $t->unsignedBigInteger('organization_id')->nullable();
            $t->boolean('is_active'); $t->timestamps();
        });
        Schema::create('school_accounts', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id')->unique();
            $t->unsignedBigInteger('user_id')->unique(); $t->timestamps();
        });
        Schema::create('school_account_setup_tokens', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id')->unique();
            $t->string('token_hash', 64); $t->timestamp('expires_at'); $t->timestamps();
        });
        Schema::create('organizations', function (Blueprint $t) {
            $t->id(); $t->boolean('is_active');
        });
        DB::table('schools')->insert([
            'id' => 5, 'name' => 'School', 'official_email' => 'school@example.test',
            'is_active' => true, 'created_at' => now(), 'updated_at' => now(),
        ]);
    }

    protected function tearDown(): void
    {
        foreach (['school_account_setup_tokens', 'school_accounts', 'schools', 'organizations', 'users'] as $table) {
            Schema::dropIfExists($table);
        }
        parent::tearDown();
    }

    private function redeem(string $token): \Illuminate\Http\JsonResponse
    {
        return app(SchoolAccountActivationController::class)->complete(Request::create(
            '/api/school-account/complete-setup', 'POST', [
                'email' => 'school@example.test', 'token' => $token,
                'password' => 'long-test-password-123',
                'password_confirmation' => 'long-test-password-123',
            ]
        ));
    }

    public function test_setup_is_one_time_and_creates_restricted_school_role(): void
    {
        $token = str_repeat('a', 48);
        DB::table('school_account_setup_tokens')->insert([
            'school_id' => 5, 'token_hash' => hash('sha256', $token),
            'expires_at' => now()->addMinutes(30), 'created_at' => now(), 'updated_at' => now(),
        ]);
        $this->assertSame(200, $this->redeem($token)->status());
        $this->assertSame('school', DB::table('users')->value('role'));
        $this->assertSame('school@example.test', DB::table('users')->value('email'));
        $this->assertTrue(password_verify('long-test-password-123', DB::table('users')->value('password_hash')));
        $this->assertSame(5, DB::table('school_accounts')->value('school_id'));
        $this->assertNotNull(DB::table('schools')->value('official_email_verified_at'));
        $this->assertSame(0, DB::table('school_account_setup_tokens')->count());
        $this->assertSame(422, $this->redeem($token)->status());
    }

    public function test_expired_or_wrong_token_never_creates_an_account(): void
    {
        DB::table('school_account_setup_tokens')->insert([
            'school_id' => 5, 'token_hash' => hash('sha256', str_repeat('b', 48)),
            'expires_at' => now()->subMinute(), 'created_at' => now(), 'updated_at' => now(),
        ]);
        $this->assertSame(422, $this->redeem(str_repeat('b', 48))->status());
        $this->assertSame(422, $this->redeem(str_repeat('c', 48))->status());
        $this->assertSame(0, DB::table('users')->count());
    }

    public function test_unknown_email_setup_request_does_not_reveal_school_existence(): void
    {
        $response = app(SchoolAccountActivationController::class)->requestSetup(
            Request::create('/api/school-account/request-setup', 'POST', ['email' => 'unknown@example.test'])
        );
        $this->assertSame(200, $response->status());
        Mail::assertNothingSent();
    }
}
