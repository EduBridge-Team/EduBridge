<?php

namespace Tests\Feature;

use App\Support\ChildAccess;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class ChildAccessAssignmentSecurityTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('children', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('assigned_teacher_id')->nullable();
        });
        Schema::create('child_teacher', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('child_id'); $t->unsignedBigInteger('teacher_id');
        });
        Schema::create('child_specialist', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('child_id'); $t->unsignedBigInteger('specialist_id');
        });
        Schema::create('child_parent', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('child_id'); $t->unsignedBigInteger('parent_id');
        });
        DB::table('children')->insert([
            ['id' => 1, 'assigned_teacher_id' => 11],
            ['id' => 2, 'assigned_teacher_id' => null],
            ['id' => 3, 'assigned_teacher_id' => 12],
        ]);
        DB::table('child_teacher')->insert(['child_id' => 2, 'teacher_id' => 11]);
        DB::table('child_specialist')->insert(['child_id' => 2, 'specialist_id' => 21]);
        DB::table('child_parent')->insert(['child_id' => 1, 'parent_id' => 31]);
    }

    protected function tearDown(): void
    {
        foreach (['child_parent', 'child_specialist', 'child_teacher', 'children'] as $table) {
            Schema::dropIfExists($table);
        }
        parent::tearDown();
    }

    private function actor(int $id, string $role): object
    {
        return (object) ['id' => $id, 'role' => $role];
    }

    public function test_teacher_has_access_only_to_assigned_children(): void
    {
        $teacher = $this->actor(11, 'teacher');
        $this->assertTrue(ChildAccess::allowed($teacher, 1));
        $this->assertTrue(ChildAccess::allowed($teacher, 2));
        $this->assertFalse(ChildAccess::allowed($teacher, 3));
        $this->assertFalse(ChildAccess::allowed($this->actor(99, 'teacher'), 1));
    }

    public function test_specialist_cannot_inherit_teacher_or_parent_access(): void
    {
        $specialist = $this->actor(21, 'specialist');
        $this->assertTrue(ChildAccess::allowed($specialist, 2));
        $this->assertFalse(ChildAccess::allowed($specialist, 1));
        $this->assertFalse(ChildAccess::allowed($specialist, 3));
    }

    public function test_parent_has_only_own_explicitly_linked_child(): void
    {
        $parent = $this->actor(31, 'parent');
        $this->assertTrue(ChildAccess::allowed($parent, 1));
        $this->assertFalse(ChildAccess::allowed($parent, 2));
    }

    public function test_unknown_roles_null_and_invalid_child_ids_are_rejected(): void
    {
        $this->assertFalse(ChildAccess::allowed(null, 1));
        $this->assertFalse(ChildAccess::allowed($this->actor(11, 'teacher'), 0));
        $this->assertFalse(ChildAccess::allowed($this->actor(11, 'teacher'), -1));
        $this->assertFalse(ChildAccess::allowed($this->actor(11, 'institution'), 1));
        $this->assertFalse(ChildAccess::allowed($this->actor(11, 'school'), 1));
    }
}
