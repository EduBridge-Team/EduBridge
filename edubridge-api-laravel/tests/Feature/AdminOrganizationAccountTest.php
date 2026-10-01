<?php
namespace Tests\Feature;

use App\Http\Controllers\UserController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class AdminOrganizationAccountTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('users', function (Blueprint $t) {
            $t->id(); $t->string('name'); $t->string('email')->unique(); $t->string('role');
            $t->string('password'); $t->string('password_hash'); $t->string('phone')->nullable();
            $t->string('verification_status')->default('pending'); $t->timestamps();
        });
    }
    protected function tearDown(): void
    {
        Schema::dropIfExists('users');
        parent::tearDown();
    }
    public function test_admin_creates_institution_and_ministry_with_hashed_credentials(): void
    {
        foreach (['institution', 'ministry'] as $role) {
            $response = $this->create('admin', ['role' => $role, 'email' => "$role@example.com", 'verification_status' => 'verified']);
            $this->assertSame(201, $response->getStatusCode());
            $user = DB::table('users')->where('email', "$role@example.com")->first();
            $this->assertTrue(password_verify('secure-pass-123', $user->password_hash));
            $this->assertTrue(password_verify('secure-pass-123', $user->password));
            $this->assertSame('pending', $user->verification_status);
            $payload = $response->getData(true)['user'];
            $this->assertArrayNotHasKey('password', $payload);
            $this->assertArrayNotHasKey('password_hash', $payload);
        }
    }
    public function test_other_roles_cannot_create_accounts(): void
    {
        foreach (['parent', 'teacher', 'specialist', 'institution', 'ministry'] as $role) {
            $this->assertSame(403, $this->create($role)->getStatusCode());
        }
        $this->assertSame(0, DB::table('users')->count());
    }
    public function test_invalid_role_password_confirmation_and_duplicate_email_are_rejected(): void
    {
        foreach ([['role' => 'admin'], ['email' => 'invalid'], ['password' => 'short'], ['password_confirmation' => 'different']] as $invalid) {
            $this->assertSame(422, $this->create('admin', $invalid)->getStatusCode());
        }
        $this->assertSame(201, $this->create('admin')->getStatusCode());
        $this->assertSame(409, $this->create('admin', ['email' => 'ORGANIZATION@EXAMPLE.COM'])->getStatusCode());
        $this->assertSame(1, DB::table('users')->count());
    }
    private function create(string $actor, array $patch = [])
    {
        $request = Request::create('/api/users', 'POST', array_merge([
            'name' => 'مؤسسة تعليمية', 'email' => 'organization@example.com', 'role' => 'institution',
            'password' => 'secure-pass-123', 'password_confirmation' => 'secure-pass-123',
        ], $patch));
        $request->attributes->set('jwt_user', (object) ['id' => 100, 'role' => $actor]);
        return app(UserController::class)->store($request);
    }
}
