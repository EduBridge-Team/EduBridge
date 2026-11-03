<?php

namespace Tests\Feature;

use App\Http\Controllers\IndependentSchoolSpecialistController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class IndependentSchoolSpecialistEmploymentTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('organizations', function (Blueprint $t) {
            $t->id(); $t->boolean('is_active')->default(true);
        });
        Schema::create('schools', function (Blueprint $t) {
            $t->id(); $t->string('name'); $t->unsignedBigInteger('organization_id')->nullable();
            $t->boolean('is_active')->default(true);
        });
        Schema::create('users', function (Blueprint $t) {
            $t->id(); $t->string('name'); $t->string('email')->unique();
            $t->string('role'); $t->timestamp('email_verified_at')->nullable();
        });
        Schema::create('school_management_assignments', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('user_id');
            $t->string('role'); $t->timestamp('ends_at')->nullable();
        });
        Schema::create('school_specialist_employments', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('specialist_id');
            $t->unsignedBigInteger('invited_by'); $t->timestamp('offered_at');
            $t->timestamp('accepted_at')->nullable(); $t->timestamp('ended_at')->nullable(); $t->timestamps();
        });
        Schema::create('school_specialist_assignments', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('employment_id');
            $t->unsignedBigInteger('specialist_id'); $t->unsignedBigInteger('assigned_by');
            $t->date('starts_on'); $t->date('ended_on')->nullable();
            $t->string('idempotency_key')->unique();
            $t->string('end_idempotency_key')->nullable()->unique();
            $t->timestamps();
        });
        DB::table('organizations')->insert(['id' => 1, 'is_active' => true]);
        DB::table('schools')->insert([
            ['id' => 10, 'name' => 'Independent A', 'organization_id' => null, 'is_active' => true],
            ['id' => 11, 'name' => 'Independent B', 'organization_id' => null, 'is_active' => true],
            ['id' => 12, 'name' => 'Institution school', 'organization_id' => 1, 'is_active' => true],
        ]);
        DB::table('users')->insert([
            ['id' => 1, 'name' => 'Director', 'email' => 'director@example.test',
                'role' => 'school_director', 'email_verified_at' => now()],
            ['id' => 2, 'name' => 'Specialist A', 'email' => 'specialist@example.test',
                'role' => 'specialist', 'email_verified_at' => now()],
            ['id' => 3, 'name' => 'Other specialist', 'email' => 'other@example.test',
                'role' => 'specialist', 'email_verified_at' => now()],
            ['id' => 4, 'name' => 'Not verified', 'email' => 'pending@example.test',
                'role' => 'specialist', 'email_verified_at' => null],
            ['id' => 5, 'name' => 'Teacher', 'email' => 'teacher@example.test',
                'role' => 'teacher', 'email_verified_at' => now()],
            ['id' => 6, 'name' => 'Other director', 'email' => 'otherdirector@example.test',
                'role' => 'school_director', 'email_verified_at' => now()],
        ]);
        DB::table('school_management_assignments')->insert([
            ['school_id' => 10, 'user_id' => 1, 'role' => 'director', 'ends_at' => null],
            ['school_id' => 11, 'user_id' => 6, 'role' => 'director', 'ends_at' => null],
        ]);
    }

    protected function tearDown(): void
    {
        foreach (['school_specialist_assignments', 'school_specialist_employments',
            'school_management_assignments', 'users', 'schools', 'organizations'] as $table) {
            Schema::dropIfExists($table);
        }
        parent::tearDown();
    }

    private function call(string $method, string $path, string $handler,
        int $actor = 1, string $role = 'school_director', array $body = [],
        ?int $routeId = null): \Illuminate\Http\JsonResponse
    {
        $request = Request::create($path, $method, $body);
        $request->attributes->set('jwt_user', (object) ['id' => $actor, 'role' => $role]);
        $controller = app(IndependentSchoolSpecialistController::class);
        return $routeId === null ? $controller->{$handler}($request)
            : $controller->{$handler}($request, $routeId);
    }

    private function offer(string $email = 'specialist@example.test', int $actor = 1): \Illuminate\Http\JsonResponse
    {
        return $this->call('POST', '/api/school/specialist-employments',
            'invite', $actor, 'school_director',
            ['expected_school_id' => $actor === 6 ? 11 : 10, 'email' => $email]);
    }

    private function snapshot(): array
    {
        return $this->call('GET', '/api/school/specialist-assignments', 'assignments')->getData(true);
    }

    private function assign(int $specialist, string $revision, string $key = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'): \Illuminate\Http\JsonResponse
    {
        return $this->call('POST', '/api/school/specialist-assignments', 'assign', 1, 'school_director', [
            'expected_school_id' => 10, 'specialist_id' => $specialist,
            'expected_revision' => $revision, 'effective_on' => now()->toDateString(),
            'idempotency_key' => $key,
        ]);
    }

    public function test_verified_specialist_accepts_offer_before_director_can_assign(): void
    {
        $offer = $this->offer();
        $this->assertSame(201, $offer->getStatusCode());
        $employment = (int) $offer->getData(true)['employment_id'];
        $before = $this->snapshot();
        $this->assertSame([], $before['eligible_specialists']);
        $this->assertSame(422, $this->assign(2, $before['revision'])->getStatusCode());

        $pending = $this->call('GET', '/api/specialists/me/school-employments', 'myOffers', 2, 'specialist');
        $this->assertSame(1, count($pending->getData(true)['employments']));
        $this->assertSame(200, $this->call('POST', '/api/specialists/me/school-employments/1/accept',
            'accept', 2, 'specialist', [], $employment)->getStatusCode());

        $active = $this->snapshot();
        $this->assertSame([2], array_column($active['eligible_specialists'], 'id'));
        $this->assertSame(409, $this->assign(2, $before['revision'])->getStatusCode());
        $assigned = $this->assign(2, $active['revision']);
        $this->assertSame(201, $assigned->getStatusCode());
        $assignment = $assigned->getData(true)['assignment'];
        $this->assertSame(2, $assignment['specialist_id']);
        $this->assertSame(409, $this->assign(2, $active['revision'], 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb')->getStatusCode());

        $directory = $this->call('GET', '/api/specialists/me/schools', 'mySchools', 2, 'specialist');
        $this->assertSame([10], array_column($directory->getData(true)['schools'], 'school_id'));
        $this->assertSame(1, DB::table('school_specialist_assignments')->count());
        $this->assertSame(200, $this->call('POST', '/api/school/specialist-employments/1/end',
            'endEmployment', 1, 'school_director', ['expected_school_id' => 10], $employment)->getStatusCode());
        $this->assertSame([], $this->call('GET', '/api/specialists/me/schools',
            'mySchools', 2, 'specialist')->getData(true)['schools']);
        $this->assertSame(0, DB::table('school_specialist_assignments')->whereNull('ended_on')->count());
        $this->assertSame(1, DB::table('school_specialist_assignments')->count());
        $this->assertSame(201, $this->offer()->getStatusCode());
    }

    public function test_director_and_specialist_ids_are_school_scoped(): void
    {
        $this->assertSame(403, $this->offer('specialist@example.test', 3)->getStatusCode());
        $this->assertSame(422, $this->offer('teacher@example.test')->getStatusCode());
        $this->assertSame(422, $this->offer('pending@example.test')->getStatusCode());

        $offer = $this->offer();
        $id = $offer->getData(true)['employment_id'];
        $this->assertSame(409, $this->offer()->getStatusCode());
        $this->assertSame(404, $this->call('POST', '/api/specialists/me/school-employments/1/accept',
            'accept', 3, 'specialist', [], $id)->getStatusCode());
        $this->assertSame(404, $this->call('POST', '/api/school/specialist-employments/1/end',
            'endEmployment', 6, 'school_director', ['expected_school_id' => 11], $id)->getStatusCode());
        $this->assertNull(DB::table('school_specialist_employments')->where('id', $id)->value('ended_at'));

        DB::table('school_management_assignments')->where('user_id', 1)->update(['school_id' => 12]);
        $this->assertSame(403, $this->offer()->getStatusCode());
        $this->assertSame(403, $this->call('GET', '/api/school/specialist-assignments',
            'assignments')->getStatusCode());
    }

    public function test_assignment_can_end_without_deleting_history_and_replay_is_idempotent(): void
    {
        $id = $this->offer()->getData(true)['employment_id'];
        $this->call('POST', '/api/specialists/me/school-employments/1/accept',
            'accept', 2, 'specialist', [], $id);
        $state = $this->snapshot();
        $receipt = $this->assign(2, $state['revision']);
        $this->assertSame(201, $receipt->getStatusCode());
        $assignment = (int) $receipt->getData(true)['assignment']['id'];
        $this->assertSame($assignment, $this->assign(2, $state['revision'])->getData(true)['assignment']['id']);
        $revision = $this->snapshot()['revision'];
        $ending = $this->call('POST', '/api/school/specialist-assignments/'.$assignment.'/end',
            'endAssignment', 1, 'school_director', [
                'expected_school_id' => 10, 'expected_specialist_id' => 2,
                'expected_revision' => $revision, 'effective_on' => now()->toDateString(),
                'idempotency_key' => 'cccccccccccccccccccccccccccccccc',
            ], $assignment);
        $this->assertSame(200, $ending->getStatusCode());
        $this->assertFalse($ending->getData(true)['assignment']['can_end']);
        $this->assertSame(1, DB::table('school_specialist_assignments')->count());
        $this->assertSame([], $this->call('GET', '/api/specialists/me/schools',
            'mySchools', 2, 'specialist')->getData(true)['schools']);
    }

    public function test_expired_offers_and_inactive_schools_cannot_be_accepted(): void
    {
        $id = $this->offer()->getData(true)['employment_id'];
        DB::table('school_specialist_employments')->where('id', $id)
            ->update(['offered_at' => now()->subDays(8)]);
        $this->assertSame(410, $this->call('POST', '/api/specialists/me/school-employments/1/accept',
            'accept', 2, 'specialist', [], $id)->getStatusCode());
        DB::table('schools')->where('id', 10)->update(['is_active' => false]);
        $this->assertSame(403, $this->call('POST', '/api/specialists/me/school-employments/1/accept',
            'accept', 2, 'specialist', [], $id)->getStatusCode());
        $this->assertSame(403, $this->call('GET', '/api/school/specialist-assignments',
            'assignments')->getStatusCode());
    }
}
