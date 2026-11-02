<?php

namespace Tests\Feature;

use App\Http\Controllers\SchoolOfficialSetupController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class SchoolOfficialSetupTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
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
            $t->string('name'); $t->string('official_email')->unique();
            $t->timestamp('official_email_verified_at')->nullable();
            $t->boolean('is_active'); $t->timestamps();
        });
        Schema::create('school_accounts', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id')->unique();
            $t->unsignedBigInteger('user_id')->unique(); $t->timestamps();
        });
        Schema::create('school_official_setup_tokens', function (Blueprint $t) {
            $t->unsignedBigInteger('school_id')->primary();
            $t->string('token_hash'); $t->timestamp('created_at');
        });
        DB::table('schools')->insert([
            'id' => 1, 'organization_id' => null,
            'name' => 'Example School', 'official_email' => 'school@example.test',
            'official_email_verified_at' => null, 'is_active' => true,
            'created_at' => now(), 'updated_at' => now(),
        ]);
    }

    protected function tearDown(): void
    {
        foreach (['school_official_setup_tokens', 'school_accounts', 'schools', 'organizations', 'users'] as $name) {
            Schema::dropIfExists($name);
        }
        parent::tearDown();
    }

    private function activate(string $token = 'valid-setup-token', string $email = 'school@example.test')
    {
        $request = Request::create('/api/school-official/activate', 'POST', [
            'email' => $email,
            'token' => $token,
            'password' => 'new-secret-school-password',
            'password_confirmation' => 'new-secret-school-password',
        ]);
        return app(SchoolOfficialSetupController::class)->activate($request);
    }

    public function test_valid_one_time_link_creates_restricted_account_and_cannot_replay(): void
    {
        DB::table('school_official_setup_tokens')->insert([
            'school_id' => 1, 'token_hash' => hash('sha256', 'valid-setup-token'),
            'created_at' => now(),
        ]);
        $this->assertSame(200, $this->activate()->status());
        $user = DB::table('users')->first();
        $this->assertSame('school_official', $user->role);
        $this->assertSame('school@example.test', $user->email);
        $this->assertTrue(password_verify('new-secret-school-password', $user->password_hash));
        $this->assertNotNull($user->email_verified_at);
        $this->assertSame(1, DB::table('school_accounts')->count());
        $this->assertNotNull(DB::table('schools')->value('official_email_verified_at'));
        $this->assertSame(0, DB::table('school_official_setup_tokens')->count());
        $this->assertSame(422, $this->activate()->status());
        $this->assertSame(1, DB::table('users')->count());
    }

    public function test_expired_or_wrong_link_never_creates_an_account(): void
    {
        DB::table('school_official_setup_tokens')->insert([
            'school_id' => 1, 'token_hash' => hash('sha256', 'valid-setup-token'),
            'created_at' => now()->subMinutes(61),
        ]);
        $this->assertSame(422, $this->activate()->status());
        DB::table('school_official_setup_tokens')->where('school_id', 1)->update([
            'created_at' => now(),
        ]);
        $this->assertSame(422, $this->activate('wrong-setup-token')->status());
        $this->assertSame(0, DB::table('users')->count());
        $this->assertSame(0, DB::table('school_accounts')->count());
    }

    public function test_inactive_school_cannot_activate(): void
    {
        DB::table('schools')->where('id', 1)->update(['is_active' => false]);
        DB::table('school_official_setup_tokens')->insert([
            'school_id' => 1, 'token_hash' => hash('sha256', 'valid-setup-token'),
            'created_at' => now(),
        ]);
        $this->assertSame(422, $this->activate()->status());
        $this->assertSame(0, DB::table('users')->count());
    }
}
