<?php

namespace Tests\Feature;

use App\Http\Controllers\InstitutionTeacherMembershipController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class InstitutionTeacherMembershipTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('users', function (Blueprint $t) {
            $t->id(); $t->string('name'); $t->string('email'); $t->string('role');
            $t->timestamp('email_verified_at')->nullable();
        });
        Schema::create('organization_user', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id'); $t->unsignedBigInteger('user_id');
            $t->string('role'); $t->boolean('is_active'); $t->timestamps();
        });
        Schema::create('schools', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id');
        });
        Schema::create('grades', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id');
        });
        Schema::create('sections', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('grade_id');
        });
        Schema::create('teacher_assignments', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('teacher_id'); $t->unsignedBigInteger('section_id');
        });
        DB::table('users')->insert([
            'id' => 7, 'name' => 'Teacher', 'email' => 'teacher@example.com',
            'role' => 'teacher', 'email_verified_at' => now(),
        ]);
        DB::table('organization_user')->insert([
            'organization_id' => 3, 'user_id' => 7, 'role' => 'teacher',
            'is_active' => true, 'created_at' => now(), 'updated_at' => now(),
        ]);
    }

    protected function tearDown(): void
    {
        foreach (['teacher_assignments', 'sections', 'grades', 'schools', 'organization_user', 'users'] as $table) {
            Schema::dropIfExists($table);
        }
        parent::tearDown();
    }

    private function change(int $org, bool $active): \Illuminate\Http\JsonResponse
    {
        $request = Request::create('/api/institutions/demo/teachers/7', 'PATCH', ['is_active' => $active]);
        $request->attributes->set('organization', (object) ['id' => $org]);
        return app(InstitutionTeacherMembershipController::class)->update($request, 'demo', 7);
    }

    public function test_teacher_membership_cannot_be_edited_from_another_organization(): void
    {
        $this->assertSame(404, $this->change(4, false)->getStatusCode());
        $this->assertDatabaseHas('organization_user', ['organization_id' => 3, 'user_id' => 7, 'is_active' => true]);
    }

    public function test_teacher_must_be_unassigned_before_deactivation(): void
    {
        DB::table('schools')->insert(['id' => 5, 'organization_id' => 3]);
        DB::table('grades')->insert(['id' => 6, 'school_id' => 5]);
        DB::table('sections')->insert(['id' => 8, 'grade_id' => 6]);
        DB::table('teacher_assignments')->insert(['teacher_id' => 7, 'section_id' => 8]);
        $this->assertSame(409, $this->change(3, false)->getStatusCode());
        $this->assertDatabaseHas('organization_user', ['organization_id' => 3, 'user_id' => 7, 'is_active' => true]);
        DB::table('teacher_assignments')->delete();
        $this->assertSame(200, $this->change(3, false)->getStatusCode());
        $this->assertDatabaseHas('organization_user', ['organization_id' => 3, 'user_id' => 7, 'is_active' => false]);
        $this->assertSame(200, $this->change(3, true)->getStatusCode());
    }
}
