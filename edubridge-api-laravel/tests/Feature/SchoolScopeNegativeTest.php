<?php

namespace Tests\Feature;

use App\Support\SchoolScopedAccess;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SchoolScopeNegativeTest extends SchoolDeputyManagementTest
{
    public function test_deputy_cannot_access_other_school_or_undelegated_operations(): void
    {
        $controller = app(\App\Http\Controllers\SchoolDeputyManagementController::class);
        $created = $controller->store($this->requestFor(20, ['user_email' => 'deputy@example.org']));
        $this->assertSame(201, $created->getStatusCode());
        $id = $created->getData(true)['assignment_id'];
        $delegation = $this->requestFor(20, ['permissions' => ['academic']]);
        $this->assertSame(200, app(\App\Http\Controllers\SchoolDelegationController::class)->update($delegation, $id)->getStatusCode());

        $actor = $this->requestFor(21);
        $school = SchoolScopedAccess::resolve($actor, 'academic');
        $this->assertNotNull($school);
        $this->assertSame(10, (int) $school->id);
        foreach (['enrollment', 'attendance', 'timetable', 'curriculum', 'reports'] as $permission) {
            $this->assertNull(SchoolScopedAccess::resolve($actor, $permission), $permission);
        }
        $this->assertSame(404, $controller->revoke($this->requestFor(23), $id)->getStatusCode());
    }

    public function test_deactivated_school_and_organization_block_school_context(): void
    {
        $this->assertNotNull(SchoolScopedAccess::resolve($this->requestFor(20), 'academic'));
        DB::table('schools')->where('id', 10)->update(['is_active' => false]);
        $this->assertNull(SchoolScopedAccess::resolve($this->requestFor(20), 'academic'));
        DB::table('schools')->where('id', 10)->update(['is_active' => true]);

        DB::table('organizations')->insert(['id' => 5, 'is_active' => false]);
        DB::table('schools')->where('id', 10)->update(['organization_id' => 5]);
        $this->assertNull(SchoolScopedAccess::resolve($this->requestFor(20), 'academic'));
    }

    public function test_ambiguous_active_directorship_is_denied(): void
    {
        $this->assertNotNull(SchoolScopedAccess::resolve($this->requestFor(20), 'academic'));
        DB::table('school_management_assignments')->insert([
            'school_id' => 11, 'user_id' => 20, 'role' => 'director',
            'appointed_by' => null, 'starts_at' => now(), 'ends_at' => null,
            'created_at' => now(), 'updated_at' => now(),
        ]);
        $this->assertNull(SchoolScopedAccess::resolve($this->requestFor(20), 'academic'));
    }

    private function requestFor(int $user, array $data = []): Request
    {
        $request = Request::create('/api/school/operations', 'POST', $data);
        $request->attributes->set('jwt_user', (object) ['id' => $user, 'role' => 'teacher']);
        return $request;
    }
    public function test_unassigned_actor_cannot_use_school_operations_dispatcher(): void
    {
        $request = $this->requestFor(999, ['expected_school_id' => 10]);
        $response = app(\\App\\Http\\Controllers\\SchoolOperationsController::class)->handle($request, 'years');
        $this->assertSame(403, $response->getStatusCode());
    }

}
