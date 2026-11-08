<?php

namespace Tests\Feature;

use App\Http\Controllers\InstitutionDirectorDirectoryController;
use App\Http\Middleware\JwtAuth;
use App\Support\AuthCredentials;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\ValidationException;
use Tests\TestCase;

class InstitutionDirectorAssignmentTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        config()->set('services.jwt.secret', 'director-assignments-jwt-test-secret');
        Schema::create('users', function (Blueprint $t) {
            $t->id(); $t->string('name'); $t->string('email')->unique();
            $t->string('role'); $t->string('password_hash')->default('unused');
            $t->unsignedBigInteger('session_version')->default(0);
            $t->timestamp('email_verified_at')->nullable();
            $t->string('verification_status')->default('verified');
        });
        Schema::create('organizations', function (Blueprint $t) {
            $t->id(); $t->string('slug'); $t->boolean('is_active')->default(true);
        });
        Schema::create('organization_user', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id'); $t->unsignedBigInteger('user_id');
            $t->string('role'); $t->boolean('is_active')->default(true);
        });
        Schema::create('schools', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id')->nullable();
            $t->boolean('is_active')->default(true); $t->string('name');
        });
        Schema::create('school_management_assignments', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id');
            $t->unsignedBigInteger('user_id'); $t->string('role');
            $t->unsignedBigInteger('appointed_by')->nullable();
            $t->timestamp('starts_at'); $t->timestamp('ends_at')->nullable(); $t->timestamps();
        });
        $users = [
            ['id' => 10, 'name' => 'Owner', 'email' => 'owner@example.test', 'role' => 'institution'],
            ['id' => 11, 'name' => 'Other Owner', 'email' => 'foreign@example.test', 'role' => 'institution'],
            ['id' => 20, 'name' => 'Director A', 'email' => 'a@example.test',
                'role' => 'school_director', 'email_verified_at' => now()],
            ['id' => 21, 'name' => 'Director B', 'email' => 'b@example.test',
                'role' => 'school_director', 'email_verified_at' => now()],
            ['id' => 22, 'name' => 'Unverified', 'email' => 'unverified@example.test',
                'role' => 'school_director'],
            ['id' => 23, 'name' => 'Teacher', 'email' => 'teacher@example.test', 'role' => 'teacher',
                'email_verified_at' => now()],
        ];
        // Every row in a bulk SQLite insert must have identical columns.
        // Profiles deliberately include both verified and unverified accounts.
        DB::table('users')->insert(array_map(
            fn (array $user) => array_merge(['email_verified_at' => null], $user),
            $users
        ));
        DB::table('organizations')->insert([
            ['id' => 1, 'slug' => 'jabalia', 'is_active' => true],
            ['id' => 2, 'slug' => 'other', 'is_active' => true],
        ]);
        DB::table('organization_user')->insert([
            ['organization_id' => 1, 'user_id' => 10, 'role' => 'owner', 'is_active' => true],
            ['organization_id' => 2, 'user_id' => 11, 'role' => 'owner', 'is_active' => true],
        ]);
        DB::table('schools')->insert([
            ['id' => 1, 'organization_id' => 1, 'name' => 'Jabalia A', 'is_active' => true],
            ['id' => 2, 'organization_id' => 1, 'name' => 'Jabalia B', 'is_active' => true],
            ['id' => 3, 'organization_id' => 2, 'name' => 'Foreign', 'is_active' => true],
        ]);
        $this->migration()->up();
        DB::table('institution_director_profiles')->insert([
            ['id' => 101, 'school_id' => 1, 'name' => 'Director A',
                'email' => 'a@example.test', 'identity_user_id' => 20],
            ['id' => 102, 'school_id' => 1, 'name' => 'Director B',
                'email' => 'b@example.test', 'identity_user_id' => 21],
            ['id' => 103, 'school_id' => 1, 'name' => 'Unverified',
                'email' => 'unverified@example.test', 'identity_user_id' => 22],
            ['id' => 104, 'school_id' => 1, 'name' => 'Draft',
                'email' => 'draft@example.test', 'identity_user_id' => null],
            ['id' => 105, 'school_id' => 1, 'name' => 'Teacher',
                'email' => 'teacher@example.test', 'identity_user_id' => 23],
            ['id' => 106, 'school_id' => 2, 'name' => 'Director B other school',
                'email' => 'second@example.test', 'identity_user_id' => null],
        ]);
    }

    protected function tearDown(): void
    {
        $this->migration()->down();
        foreach (['school_management_assignments', 'schools', 'organization_user', 'organizations', 'users'] as $table) {
            Schema::dropIfExists($table);
        }
        parent::tearDown();
    }

    private function migration(): object
    {
        return require __DIR__.'/../../database/migrations/2026_11_08_140000_create_institution_director_directory.php';
    }

    private function req(array $body, int $userId = 10, string $role = 'institution', int $orgId = 1, string $slug = 'jabalia'): Request
    {
        $request = Request::create('/api/institutions/'.$slug.'/schools/1/director-assignments', 'POST', $body);
        $request->attributes->set('jwt_user', (object) ['id' => $userId, 'role' => $role]);
        $request->attributes->set('organization', (object) ['id' => $orgId, 'slug' => $slug]);
        return $request;
    }

    private function assign(int $directorId, ?int $replace = null, ?string $date = null, int $school = 1): \Illuminate\Http\JsonResponse
    {
        return app(InstitutionDirectorDirectoryController::class)->assign(
            $this->req([
                'director_id' => $directorId,
                'starts_on' => $date ?? now()->toDateString(),
                'replace_assignment_id' => $replace,
            ]), 'jabalia', $school
        );
    }

    private function end(int $assignment, int $directorId, ?string $date = null, int $school = 1): \Illuminate\Http\JsonResponse
    {
        return app(InstitutionDirectorDirectoryController::class)->endAssignment(
            $this->req([
                'ended_on' => $date ?? now()->toDateString(),
                'expected_director_id' => $directorId,
            ]), 'jabalia', $school, $assignment
        );
    }

    private function token(int $userId): string
    {
        return AuthCredentials::issue(
            DB::table('users')->where('id', $userId)->first(), config('services.jwt.secret')
        );
    }

    private function authenticated(string $jwt): int
    {
        $request = Request::create('/api/me', 'GET', [], [], [], [
            'HTTP_AUTHORIZATION' => 'Bearer '.$jwt,
        ]);
        return app(JwtAuth::class)->handle(
            $request, fn (Request $req) => response()->json(['id' => $req->attributes->get('jwt_user')->id])
        )->status();
    }

    public function test_new_verified_director_assignment_grants_access_and_records_actor(): void
    {
        $response = $this->assign(101);
        $this->assertSame(201, $response->status());
        $this->assertSame(101, $response->getData(true)['assignment']['director_id']);
        $this->assertSame(1, DB::table('school_management_assignments')->whereNull('ends_at')->count());
        $this->assertSame(20, DB::table('school_management_assignments')->value('user_id'));
        $this->assertSame(10, DB::table('institution_director_assignments')->value('appointed_by'));
        $this->assertSame(200, $this->authenticated($this->token(20)));
    }

    public function test_replacement_ends_previous_appointment_and_revokes_previous_jwt(): void
    {
        $old = $this->assign(101)->getData(true)['assignment']['id'];
        $jwt = $this->token(20);
        $this->assertSame(200, $this->authenticated($jwt));
        $response = $this->assign(102, $old);
        $this->assertSame(201, $response->status());
        $this->assertSame(401, $this->authenticated($jwt));
        $this->assertSame(1, (int) DB::table('users')->where('id', 20)->value('session_version'));
        $this->assertSame(0, (int) DB::table('users')->where('id', 21)->value('session_version'));
        $this->assertSame(200, $this->authenticated($this->token(21)));
        $this->assertSame(2, DB::table('institution_director_assignments')->count());
        $this->assertSame(1, DB::table('institution_director_assignments')->whereNull('ended_on')->count());
        $this->assertSame(10, (int) DB::table('institution_director_assignments')
            ->where('id', $old)->value('ended_by'));
        $this->assertSame(1, DB::table('school_management_assignments')->whereNull('ends_at')->count());
    }

    public function test_ending_current_appointment_revokes_jwt_and_cannot_repeat(): void
    {
        $id = $this->assign(101)->getData(true)['assignment']['id'];
        $jwt = $this->token(20);
        $result = $this->end($id, 101);
        $this->assertSame(200, $result->status());
        $this->assertNotNull($result->getData(true)['assignment']['ended_on']);
        $this->assertSame(401, $this->authenticated($jwt));
        $this->assertSame(409, $this->end($id, 101)->status());
        $this->assertSame(0, DB::table('school_management_assignments')->whereNull('ends_at')->count());
    }

    public function test_missing_or_stale_replacement_assertion_is_rejected(): void
    {
        $this->expectException(ValidationException::class);
        app(InstitutionDirectorDirectoryController::class)->assign(
            $this->req(['director_id' => 101, 'starts_on' => now()->toDateString()]), 'jabalia', 1
        );
    }

    public function test_stale_assignments_do_not_mutate_state(): void
    {
        $this->assertSame(409, $this->assign(101, 999)->status());
        $id = $this->assign(101)->getData(true)['assignment']['id'];
        $this->assertSame(409, $this->assign(102)->status());
        $this->assertSame(409, $this->assign(102, $id + 100)->status());
        $this->assertSame(409, $this->assign(101, $id)->status());
        $this->assertSame(409, $this->end($id, 102)->status());
        $this->assertSame(1, DB::table('institution_director_assignments')->count());
        $this->assertSame(1, DB::table('school_management_assignments')->whereNull('ends_at')->count());
    }

    public function test_unverified_and_unactivated_profiles_cannot_grant_director_access(): void
    {
        foreach ([103, 104, 105] as $id) {
            $this->assertSame(409, $this->assign($id)->status());
        }
        $this->assertSame(0, DB::table('school_management_assignments')->count());
        $this->assertSame(0, DB::table('institution_director_assignments')->count());
    }

    public function test_director_appointed_to_other_school_is_rejected(): void
    {
        DB::table('school_management_assignments')->insert([
            'school_id' => 2, 'user_id' => 20, 'role' => 'director',
            'appointed_by' => 10, 'starts_at' => now(), 'ends_at' => null,
            'created_at' => now(), 'updated_at' => now(),
        ]);
        $this->assertSame(409, $this->assign(101)->status());
        $this->assertSame(0, DB::table('institution_director_assignments')->count());
    }

    public function test_wrong_tenant_school_or_role_cannot_assign_or_end(): void
    {
        $c = app(InstitutionDirectorDirectoryController::class);
        $body = ['director_id' => 101, 'starts_on' => now()->toDateString(),
            'replace_assignment_id' => null];
        $this->assertSame(404, $c->assign($this->req($body), 'jabalia', 3)->status());
        $this->assertSame(403, $c->assign($this->req($body, 11), 'jabalia', 1)->status());
        $this->assertSame(403, $c->assign($this->req($body, 10, 'teacher'), 'jabalia', 1)->status());
        $this->assertSame(403, $c->assign($this->req($body, 10, 'institution', 2, 'other'), 'other', 1)->status());
        $this->assertSame(404, $c->endAssignment(
            $this->req(['ended_on' => now()->toDateString(), 'expected_director_id' => 101]),
            'jabalia', 3, 999
        )->status());
        $this->assertSame(0, DB::table('school_management_assignments')->count());
    }

    public function test_end_date_before_start_or_future_date_is_rejected(): void
    {
        $id = $this->assign(101)->getData(true)['assignment']['id'];
        $this->assertSame(422, $this->end(
            $id, 101, now()->subDay()->toDateString()
        )->status());
        $this->assertSame(1, DB::table('institution_director_assignments')->whereNull('ended_on')->count());
    }

    public function test_future_assignment_effective_date_is_rejected(): void
    {
        $this->expectException(ValidationException::class);
        $this->assign(101, null, now()->addDay()->toDateString());
    }

    public function test_unrelated_legacy_account_session_is_not_revoked_by_ending_appointment(): void
    {
        $id = DB::table('institution_director_assignments')->insertGetId([
            'school_id' => 1, 'director_id' => 105,
            'starts_on' => now()->toDateString(),
            'appointed_by' => 10, 'created_at' => now(), 'updated_at' => now(),
        ]);
        DB::table('school_management_assignments')->insert([
            'school_id' => 1, 'user_id' => 23, 'role' => 'director',
            'appointed_by' => 10, 'starts_at' => now(), 'ends_at' => null,
            'created_at' => now(), 'updated_at' => now(),
        ]);
        $this->assertSame(200, $this->end($id, 105)->status());
        $this->assertSame(0, (int) DB::table('users')->where('id', 23)->value('session_version'));
        $this->assertSame(1, DB::table('school_management_assignments')->count());
        $this->assertSame(0, DB::table('school_management_assignments')->whereNull('ends_at')->count());
    }
}
