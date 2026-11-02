<?php

namespace Tests\Feature;

use App\Http\Controllers\AuthController;
use App\Http\Controllers\SchoolOfficialAccountController;
use App\Http\Controllers\SchoolProvisionController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class SchoolOfficialAccountActivationTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Mail::fake();
        config()->set('services.jwt.secret', str_repeat('official-school-jwt-', 4));
        Schema::create('users', function (Blueprint $t) {
            $t->id(); $t->string('name'); $t->string('email')->unique();
            $t->string('password'); $t->string('password_hash');
            $t->string('role'); $t->timestamp('email_verified_at')->nullable();
            $t->unsignedInteger('session_version')->default(0); $t->timestamps();
        });
        Schema::create('organizations', function (Blueprint $t) {
            $t->id(); $t->boolean('is_active');
        });
        Schema::create('schools', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id')->nullable();
            $t->string('name'); $t->string('slug')->unique();
            $t->string('email'); $t->string('phone')->nullable(); $t->string('address')->nullable();
            $t->text('settings'); $t->boolean('is_active'); $t->timestamps();
        });
        Schema::create('school_accounts', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id')->unique();
            $t->unsignedBigInteger('user_id')->unique(); $t->timestamps();
        });
        Schema::create('school_account_activation_tokens', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id')->unique();
            $t->string('token_hash', 64)->unique(); $t->timestamp('expires_at');
            $t->timestamp('consumed_at')->nullable(); $t->timestamps();
        });
    }

    protected function tearDown(): void
    {
        foreach (['school_account_activation_tokens', 'school_accounts', 'schools', 'organizations', 'users'] as $table) {
            Schema::dropIfExists($table);
        }
        parent::tearDown();
    }

    private function provision(array $input = []): \Illuminate\Http\JsonResponse
    {
        $request = Request::create('/api/admin/school-accounts', 'POST', array_merge([
            'name' => 'Example Academy',
            'school_email' => 'office@example.test',
        ], $input));
        $request->attributes->set('jwt_user', (object) ['id' => 1, 'role' => 'admin']);
        return app(SchoolProvisionController::class)->independent($request);
    }

    private function activate(string $token, string $password = 'strong-official-password'): \Illuminate\Http\JsonResponse
    {
        return app(SchoolOfficialAccountController::class)->activate(Request::create(
            '/api/auth/school-activate', 'POST',
            ['token' => $token, 'password' => $password, 'password_confirmation' => $password]
        ));
    }

    private function setKnownToken(string $token): void
    {
        DB::table('school_account_activation_tokens')->update([
            'token_hash' => hash('sha256', $token), 'expires_at' => now()->addHour(),
        ]);
    }

    public function test_creates_independent_identity_without_director_or_administrator_known_password(): void
    {
        $response = $this->provision();
        $this->assertSame(201, $response->getStatusCode());
        $payload = $response->getData(true);
        $this->assertSame('office@example.test', $payload['school']['email']);
        $this->assertSame('pending', $payload['school']['activation_status']);
        $this->assertArrayNotHasKey('director', $payload);
        $this->assertArrayNotHasKey('password', $payload);
        $this->assertArrayNotHasKey('token', $payload);
        $account = DB::table('users')->first();
        $this->assertSame('school_identity', $account->role);
        $this->assertNull($account->email_verified_at);
        $this->assertSame(1, DB::table('school_accounts')->count());
        $this->assertSame(1, DB::table('school_account_activation_tokens')->count());
        $this->assertSame(401, app(AuthController::class)->login(Request::create('/api/auth/login', 'POST', [
            'email' => 'office@example.test', 'password' => 'strong-official-password',
        ]))->getStatusCode());
    }

    public function test_activation_is_single_use_and_login_works_only_after_email_confirmation(): void
    {
        $this->assertSame(201, $this->provision()->getStatusCode());
        $token = str_repeat('a', 64);
        $this->setKnownToken($token);
        $this->assertSame(422, $this->activate(str_repeat('b', 64))->getStatusCode());
        $this->assertSame(200, $this->activate($token)->getStatusCode());
        $this->assertSame(422, $this->activate($token)->getStatusCode());
        $account = DB::table('users')->first();
        $this->assertNotNull($account->email_verified_at);
        $this->assertTrue(password_verify('strong-official-password', $account->password_hash));
        $login = app(AuthController::class)->login(Request::create('/api/auth/login', 'POST', [
            'email' => 'office@example.test', 'password' => 'strong-official-password',
        ]));
        $this->assertSame(200, $login->getStatusCode());
        $this->assertSame('school_identity', $login->getData(true)['user']['role']);
    }

    public function test_expired_token_cannot_activate_and_duplicated_official_email_is_denied(): void
    {
        $this->assertSame(201, $this->provision()->getStatusCode());
        $token = str_repeat('c', 64);
        $this->setKnownToken($token);
        DB::table('school_account_activation_tokens')->update(['expires_at' => now()->subSecond()]);
        $this->assertSame(422, $this->activate($token)->getStatusCode());
        $this->assertSame(409, $this->provision()->getStatusCode());
        $this->assertSame(1, DB::table('schools')->count());
    }

    public function test_official_and_director_email_must_be_distinct(): void
    {
        $this->assertSame(422, $this->provision([
            'director_email' => 'office@example.test',
        ])->getStatusCode());
        $this->assertSame(0, DB::table('schools')->count());
    }

    public function test_school_identity_cannot_be_created_by_teacher(): void
    {
        $request = Request::create('/api/admin/school-accounts', 'POST', [
            'name' => 'Example Academy', 'school_email' => 'office@example.test',
        ]);
        $request->attributes->set('jwt_user', (object) ['id' => 2, 'role' => 'teacher']);
        $this->assertSame(403, app(SchoolProvisionController::class)->independent($request)->getStatusCode());
    }
}
