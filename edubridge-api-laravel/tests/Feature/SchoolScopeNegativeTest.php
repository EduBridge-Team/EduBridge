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
        $response = app(\App\Http\Controllers\SchoolOperationsController::class)->handle($request, 'years');
        $this->assertSame(403, $response->getStatusCode());
    }

    public function test_school_operations_reject_foreign_expected_school_id(): void
    {
        $request = $this->requestFor(20, ['expected_school_id' => 11]);
        $this->expectException(\Illuminate\Validation\ValidationException::class);
        app(\App\Http\Controllers\SchoolOperationsController::class)->handle($request, 'years');
    }

    public function test_school_operations_reject_incorrect_http_method(): void
    {
        $request = $this->requestFor(20, ['expected_school_id' => 10]);
        $response = app(\App\Http\Controllers\SchoolOperationsController::class)->handle($request, 'student-status');
        $this->assertSame(405, $response->getStatusCode());
    }

    public function test_school_operations_reject_unknown_action(): void
    {
        $request = $this->requestFor(20, ['expected_school_id' => 10]);
        $response = app(\App\Http\Controllers\SchoolOperationsController::class)->handle($request, 'nonexistent-action');
        $this->assertSame(404, $response->getStatusCode());
    }

    public function test_deputy_write_is_denied_after_permission_withdrawal(): void
    {
        $controller = app(\App\Http\Controllers\SchoolDeputyManagementController::class);
        $created = $controller->store($this->requestFor(20, ['user_email' => 'deputy@example.org']));
        $this->assertSame(201, $created->getStatusCode());
        $id = $created->getData(true)['assignment_id'];

        $delegation = app(\App\Http\Controllers\SchoolDelegationController::class);
        $this->assertSame(200, $delegation->update(
            $this->requestFor(20, ['permissions' => ['academic']]), $id
        )->getStatusCode());
        $this->assertNotNull(SchoolScopedAccess::resolve($this->requestFor(21), 'academic'));

        $this->assertSame(200, $delegation->update(
            $this->requestFor(20, ['permissions' => []]), $id
        )->getStatusCode());
        $response = app(\App\Http\Controllers\SchoolOperationsController::class)->handle(
            $this->requestFor(21, ['expected_school_id' => 10]), 'years'
        );
        $this->assertSame(403, $response->getStatusCode());
    }

    public function test_academic_deputy_cannot_write_without_enrollment_permission(): void
    {
        $controller = app(\App\Http\Controllers\SchoolDeputyManagementController::class);
        $created = $controller->store($this->requestFor(20, ['user_email' => 'deputy@example.org']));
        $this->assertSame(201, $created->getStatusCode());
        $id = $created->getData(true)['assignment_id'];
        $this->assertSame(200, app(\App\Http\Controllers\SchoolDelegationController::class)->update(
            $this->requestFor(20, ['permissions' => ['academic']]), $id
        )->getStatusCode());
        $this->assertNotNull(SchoolScopedAccess::resolve($this->requestFor(21), 'academic'));
        $response = app(\App\Http\Controllers\SchoolOperationsController::class)->handle(
            $this->requestFor(21, ['expected_school_id' => 10]), 'student-transfer'
        );
        $this->assertSame(403, $response->getStatusCode());
    }

    public function test_academic_deputy_is_denied_multiple_undelegated_operations(): void
    {
        $created = app(\App\Http\Controllers\SchoolDeputyManagementController::class)->store(
            $this->requestFor(20, ['user_email' => 'deputy@example.org'])
        );
        $this->assertSame(201, $created->getStatusCode());
        $id = $created->getData(true)['assignment_id'];
        $this->assertSame(200, app(\App\Http\Controllers\SchoolDelegationController::class)->update(
            $this->requestFor(20, ['permissions' => ['academic']]), $id
        )->getStatusCode());

        $operations = app(\App\Http\Controllers\SchoolOperationsController::class);
        foreach (['student-transfer', 'attendance-create', 'timetable-create', 'books'] as $action) {
            $response = $operations->handle(
                $this->requestFor(21, ['expected_school_id' => 10]), $action
            );
            $this->assertSame(403, $response->getStatusCode(), $action);
        }
    }

    public function test_deputy_loses_all_school_write_access_after_assignment_revocation(): void
    {
        $deputies = app(\App\Http\Controllers\SchoolDeputyManagementController::class);
        $created = $deputies->store($this->requestFor(20, ['user_email' => 'deputy@example.org']));
        $this->assertSame(201, $created->getStatusCode());
        $id = $created->getData(true)['assignment_id'];
        $this->assertSame(200, app(\App\Http\Controllers\SchoolDelegationController::class)->update(
            $this->requestFor(20, ['permissions' => ['academic']]), $id
        )->getStatusCode());
        $this->assertSame(200, $deputies->revoke($this->requestFor(20), $id)->getStatusCode());
        $response = app(\App\Http\Controllers\SchoolOperationsController::class)->handle(
            $this->requestFor(21, ['expected_school_id' => 10]), 'years'
        );
        $this->assertSame(403, $response->getStatusCode());
    }

}
