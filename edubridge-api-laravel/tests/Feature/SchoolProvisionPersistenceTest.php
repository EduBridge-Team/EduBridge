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
        DB::table('organizations')->insert(['id' => 1, 'is_active' => true]);
        DB::table('organization_user')->insert([
            'organization_id' => 1, 'user_id' => 10, 'role' => 'owner', 'is_active' => true,
        ]);
    }

    protected function tearDown(): void
    {
        foreach (['school_accounts', 'schools', 'organization_user', 'organizations', 'email_verification_tokens', 'users'] as $table) {
            Schema::dropIfExists($table);
        }
        parent::tearDown();
    }

    private function provision(bool $affiliated, string $email): \Illuminate\Http\JsonResponse
    {
        $request = Request::create('/api/school-accounts', 'POST', [
            'name' => 'Example School', 'email' => $email,
            'password' => 'long-test-password-123', 'password_confirmation' => 'long-test-password-123',
        ]);
        if ($affiliated) {
            $request->attributes->set('jwt_user', (object) ['id' => 10, 'role' => 'institution']);
            $request->attributes->set('organization', (object) ['id' => 1]);
            return app(SchoolProvisionController::class)->affiliated($request, 'example');
        }
        $request->attributes->set('jwt_user', (object) ['id' => 1, 'role' => 'admin']);
        return app(SchoolProvisionController::class)->independent($request);
    }

    public function test_independent_school_creation_persists_scoped_account_and_hash(): void
    {
        $response = $this->provision(false, 'independent@example.test');
        $this->assertSame(201, $response->getStatusCode());
        $receipt = $response->getData(true);
        $this->assertNull($receipt['school']['organization_id']);
        $this->assertSame('school', $receipt['account']['role']);
        $user = DB::table('users')->where('id', $receipt['account']['id'])->first();
        $this->assertTrue(password_verify('long-test-password-123', $user->password_hash));
        $this->assertNotSame('long-test-password-123', $user->password_hash);
        $this->assertSame(1, DB::table('school_accounts')->where('user_id', $user->id)->count());
        $request = Request::create('/api/school/context', 'GET', ['school_id' => 999]);
        $request->attributes->set('jwt_user', (object) ['id' => $user->id, 'role' => 'school']);
        $context = app(SchoolContextController::class)->show($request);
        $this->assertSame(200, $context->getStatusCode());
        $this->assertSame($receipt['school']['id'], $context->getData(true)['school']['id']);
    }

    public function test_affiliated_school_is_tenant_scoped_and_duplicate_email_rejected(): void
    {
        $response = $this->provision(true, 'affiliated@example.test');
        $this->assertSame(201, $response->getStatusCode());
        $receipt = $response->getData(true);
        $this->assertSame(1, $receipt['school']['organization_id']);
        $this->assertSame(1, DB::table('schools')->where('id', $receipt['school']['id'])
            ->where('organization_id', 1)->count());
        $this->assertSame(409, $this->provision(false, 'affiliated@example.test')->getStatusCode());
        $this->assertSame(1, DB::table('users')->count());
        $this->assertSame(1, DB::table('schools')->count());
        $this->assertSame(1, DB::table('school_accounts')->count());
    }
    public function test_newly_provisioned_independent_school_can_log_in(): void
    {
        $created = $this->provision(false, 'signin-independent@example.test');
        $this->assertSame(201, $created->getStatusCode());
        $userId = $created->getData(true)['account']['id'];
        $request = Request::create('/api/auth/login', 'POST', [
            'email' => 'signin-independent@example.test',
            'password' => 'long-test-password-123',
        ]);
        $beforeVerification = app(AuthController::class)->login($request);
        $this->assertSame(403, $beforeVerification->getStatusCode());
        $this->assertSame('EMAIL_NOT_VERIFIED', $beforeVerification->getData(true)['code']);
        $this->assertSame(1, DB::table('email_verification_tokens')
            ->where('email', $request->input('email'))->count());
        DB::table('users')->where('email', $request->input('email'))
            ->update(['email_verified_at' => now()]);
        $login = app(AuthController::class)->login($request);
        $this->assertSame(200, $login->getStatusCode());
        $data = $login->getData(true);
        $this->assertSame($userId, $data['user']['id']);
        $this->assertSame('school', $data['user']['role']);
        $this->assertNotEmpty($data['token']);
    }

    public function test_newly_provisioned_affiliated_school_can_log_in_only_while_tenant_active(): void
    {
        $created = $this->provision(true, 'signin-affiliated@example.test');
        $this->assertSame(201, $created->getStatusCode());
        $request = Request::create('/api/auth/login', 'POST', [
            'email' => 'signin-affiliated@example.test',
            'password' => 'long-test-password-123',
        ]);
        $beforeVerification = app(AuthController::class)->login($request);
        $this->assertSame(403, $beforeVerification->getStatusCode());
        $this->assertSame('EMAIL_NOT_VERIFIED', $beforeVerification->getData(true)['code']);
        $this->assertSame(1, DB::table('email_verification_tokens')
            ->where('email', $request->input('email'))->count());
        DB::table('users')->where('email', $request->input('email'))
            ->update(['email_verified_at' => now()]);
        $login = app(AuthController::class)->login($request);
        $this->assertSame(200, $login->getStatusCode());
        $this->assertSame('school', $login->getData(true)['user']['role']);
        DB::table('organizations')->where('id', 1)->update(['is_active' => false]);
        $denied = app(AuthController::class)->login($request);
        $this->assertSame(403, $denied->getStatusCode());
        $this->assertSame('SCHOOL_ACCESS_UNAVAILABLE', $denied->getData(true)['code']);
    }

}
