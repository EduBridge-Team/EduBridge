<?php

namespace Tests\Feature;

use App\Http\Controllers\InstitutionDirectorDirectoryController;
use App\Support\InstitutionDirectorDirectorySync;
use Illuminate\Database\QueryException;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\ValidationException;
use Tests\TestCase;

class InstitutionDirectorDirectoryTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Schema::create('users', function (Blueprint $t) {
            $t->id(); $t->string('name'); $t->string('email')->unique();
            $t->string('role');
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
        DB::table('users')->insert([
            ['id' => 10, 'name' => 'Operator', 'email' => 'operator@example.test', 'role' => 'institution'],
            ['id' => 11, 'name' => 'Other', 'email' => 'other@example.test', 'role' => 'institution'],
            ['id' => 20, 'name' => 'Director', 'email' => 'director@example.test', 'role' => 'school_director'],
            ['id' => 21, 'name' => 'Former', 'email' => 'former@example.test', 'role' => 'school_director'],
        ]);
        DB::table('organizations')->insert([
            ['id' => 1, 'slug' => 'jabalia', 'is_active' => true],
            ['id' => 2, 'slug' => 'other', 'is_active' => true],
        ]);
        DB::table('organization_user')->insert([
            ['organization_id' => 1, 'user_id' => 10, 'role' => 'owner', 'is_active' => true],
            ['organization_id' => 2, 'user_id' => 11, 'role' => 'owner', 'is_active' => true],
        ]);
        DB::table('schools')->insert([
            ['id' => 1, 'name' => 'A', 'organization_id' => 1, 'is_active' => true],
            ['id' => 2, 'name' => 'B', 'organization_id' => 1, 'is_active' => true],
            ['id' => 3, 'name' => 'C', 'organization_id' => 2, 'is_active' => true],
        ]);
        $this->migration()->up();
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

    private function request(array $payload = [], int $actor = 10, string $role = 'institution', int $org = 1, string $slug = 'jabalia'): Request
    {
        $request = Request::create('/api/institutions/'.$slug.'/schools/1/directors', 'POST', $payload);
        $request->attributes->set('jwt_user', (object) ['id' => $actor, 'role' => $role]);
        $request->attributes->set('organization', (object) ['id' => $org, 'slug' => $slug]);
        return $request;
    }

    private function profileInput(string $email = 'director.new@example.test'): array
    {
        return [
            'name' => ' New Director ', 'email' => $email,
            'phone' => '0500000000', 'qualification' => 'Education',
            'experience_years' => 5,
        ];
    }

    public function test_directory_starts_empty_and_profiles_create_without_login_accounts(): void
    {
        $controller = app(InstitutionDirectorDirectoryController::class);
        $empty = $controller->index($this->request(), 'jabalia', 1)->getData(true);
        $this->assertSame(1, $empty['school_id']);
        $this->assertSame([], $empty['directors']);
        $this->assertSame([], $empty['assignments']);

        $response = $controller->store($this->request($this->profileInput()), 'jabalia', 1);
        $this->assertSame(201, $response->status());
        $created = $response->getData(true)['director'];
        $this->assertSame('New Director', $created['name']);
        $this->assertSame('director.new@example.test', $created['email']);
        $this->assertSame(1, $created['school_id']);
        $this->assertSame(4, DB::table('users')->count());
        $this->assertNull(DB::table('institution_director_profiles')->value('identity_user_id'));
        $this->assertSame(0, DB::table('school_management_assignments')->count());

        $listing = $controller->index($this->request(), 'jabalia', 1)->getData(true);
        $this->assertCount(1, $listing['directors']);
        $this->assertSame([], $listing['assignments']);
    }

    public function test_profile_updates_preserve_identity_and_audit_actor(): void
    {
        $controller = app(InstitutionDirectorDirectoryController::class);
        $id = $controller->store($this->request($this->profileInput()), 'jabalia', 1)
            ->getData(true)['director']['id'];
        $input = $this->profileInput('DIRECTOR.NEW@EXAMPLE.TEST');
        $input['name'] = ' Updated ';
        $input['experience_years'] = 8;
        $updated = $controller->update($this->request($input), 'jabalia', 1, $id);
        $this->assertSame(200, $updated->status());
        $this->assertSame('Updated', $updated->getData(true)['director']['name']);
        $this->assertSame('director.new@example.test', $updated->getData(true)['director']['email']);
        $this->assertSame(10, DB::table('institution_director_profiles')->where('id', $id)->value('updated_by'));
    }

    public function test_case_insensitive_duplicate_email_rejected_per_school(): void
    {
        $controller = app(InstitutionDirectorDirectoryController::class);
        $this->assertSame(201, $controller->store(
            $this->request($this->profileInput()), 'jabalia', 1
        )->status());
        $this->assertSame(422, $controller->store(
            $this->request($this->profileInput('DIRECTOR.NEW@EXAMPLE.TEST')), 'jabalia', 1
        )->status());
        $this->assertSame(1, DB::table('institution_director_profiles')->count());
    }

    public function test_duplicate_email_cannot_bypass_database_constraint(): void
    {
        DB::table('institution_director_profiles')->insert([
            'school_id' => 1, 'name' => 'A', 'email' => 'dup@example.test',
            'created_at' => now(), 'updated_at' => now(),
        ]);
        $this->expectException(QueryException::class);
        DB::table('institution_director_profiles')->insert([
            'school_id' => 1, 'name' => 'B', 'email' => 'DUP@EXAMPLE.TEST',
            'created_at' => now(), 'updated_at' => now(),
        ]);
    }

    public function test_tenant_school_and_role_isolation(): void
    {
        $controller = app(InstitutionDirectorDirectoryController::class);
        $this->assertSame(404, $controller->index($this->request(), 'jabalia', 3)->status());
        $this->assertSame(403, $controller->index($this->request([], 11, 'institution'), 'jabalia', 1)->status());
        $this->assertSame(403, $controller->index($this->request([], 10, 'teacher'), 'jabalia', 1)->status());
        $this->assertSame(403, $controller->store($this->request($this->profileInput(), 10, 'teacher'), 'jabalia', 1)->status());
        $this->assertSame(403, $controller->index($this->request([], 10, 'institution', 2, 'other'), 'other', 1)->status());
        DB::table('organization_user')->where('user_id', 10)->update(['role' => 'school_admin']);
        $this->assertSame(403, $controller->index($this->request(), 'jabalia', 1)->status());
        DB::table('organization_user')->where('user_id', 10)->update(['role' => 'owner', 'is_active' => false]);
        $this->assertSame(403, $controller->index($this->request(), 'jabalia', 1)->status());
    }

    public function test_cross_school_profile_edit_is_hidden(): void
    {
        $id = DB::table('institution_director_profiles')->insertGetId([
            'school_id' => 2, 'name' => 'Other', 'email' => 'other.director@example.test',
            'created_at' => now(), 'updated_at' => now(),
        ]);
        $controller = app(InstitutionDirectorDirectoryController::class);
        $this->assertSame(404, $controller->update(
            $this->request($this->profileInput()), 'jabalia', 1, $id
        )->status());
    }

    public function test_verified_email_cannot_be_changed_to_another_identity(): void
    {
        $id = DB::table('institution_director_profiles')->insertGetId([
            'school_id' => 1, 'name' => 'Verified', 'email' => 'director@example.test',
            'identity_user_id' => 20, 'created_at' => now(), 'updated_at' => now(),
        ]);
        $controller = app(InstitutionDirectorDirectoryController::class);
        $this->assertSame(409, $controller->update(
            $this->request($this->profileInput('other@example.test')), 'jabalia', 1, $id
        )->status());
    }

    public function test_activation_mirrors_verified_director_history_without_creating_accounts(): void
    {
        DB::table('institution_director_profiles')->insert([
            'school_id' => 1, 'name' => 'Draft', 'email' => 'director@example.test',
            'created_at' => now(), 'updated_at' => now(),
        ]);
        $school = DB::table('schools')->find(1);
        $invite = (object) ['email' => 'director@example.test', 'invited_by' => 10];

        InstitutionDirectorDirectorySync::activated($school, $invite, 20, 'Director');
        $this->assertSame(20, DB::table('institution_director_profiles')->value('identity_user_id'));
        $this->assertSame(1, DB::table('institution_director_assignments')->whereNull('ended_on')->count());
        $this->assertSame(0, DB::table('school_management_assignments')->count());

        InstitutionDirectorDirectorySync::activated($school, $invite, 20, 'Director');
        $this->assertSame(1, DB::table('institution_director_assignments')->count());

        InstitutionDirectorDirectorySync::activated(
            $school, (object) ['email' => 'former@example.test', 'invited_by' => 10], 21, 'Former'
        );
        $this->assertSame(2, DB::table('institution_director_assignments')->count());
        $this->assertSame(1, DB::table('institution_director_assignments')->whereNull('ended_on')->count());
    }

    public function test_migration_backfills_existing_directors_and_historical_appointments(): void
    {
        $this->migration()->down();
        DB::table('school_management_assignments')->insert([
            [
                'school_id' => 1, 'user_id' => 21, 'role' => 'director', 'appointed_by' => 10,
                'starts_at' => '2026-09-01 08:00:00', 'ends_at' => '2026-10-01 08:00:00',
                'created_at' => now(), 'updated_at' => now(),
            ],
            [
                'school_id' => 1, 'user_id' => 20, 'role' => 'director', 'appointed_by' => 10,
                'starts_at' => '2026-10-01 08:00:00', 'ends_at' => null,
                'created_at' => now(), 'updated_at' => now(),
            ],
        ]);
        $this->migration()->up();
        $directory = app(InstitutionDirectorDirectoryController::class)
            ->index($this->request(), 'jabalia', 1)->getData(true);
        $this->assertCount(2, $directory['directors']);
        $this->assertCount(2, $directory['assignments']);
        $this->assertCount(1, DB::table('institution_director_assignments')->whereNull('ended_on')->get());
        $this->assertSame(2, DB::table('school_management_assignments')->count());
    }

    public function test_one_current_director_index_rejects_duplicate_active_records(): void
    {
        DB::table('institution_director_profiles')->insert([
            ['id' => 1, 'school_id' => 1, 'name' => 'A', 'email' => 'a@example.test'],
            ['id' => 2, 'school_id' => 1, 'name' => 'B', 'email' => 'b@example.test'],
        ]);
        DB::table('institution_director_assignments')->insert([
            'school_id' => 1, 'director_id' => 1, 'starts_on' => '2026-10-01',
        ]);
        $this->expectException(QueryException::class);
        DB::table('institution_director_assignments')->insert([
            'school_id' => 1, 'director_id' => 2, 'starts_on' => '2026-10-02',
        ]);
    }
}
