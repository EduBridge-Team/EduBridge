<?php

namespace Tests\Feature;

use App\Http\Controllers\CareTeamController;
use App\Http\Controllers\SpecialistSuggestionController;
use App\Services\ChildSpecialistAssignment;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class ChildSpecialistAssignmentTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('children', function (Blueprint $t) { $t->id(); $t->string('name'); });
        Schema::create('users', function (Blueprint $t) { $t->id(); $t->string('role'); $t->string('specialty')->nullable(); });
        Schema::create('child_specialist', function (Blueprint $t) {
            $t->unsignedBigInteger('child_id'); $t->unsignedBigInteger('specialist_id');
            $t->string('specialty'); $t->timestamp('assigned_at'); $t->timestamp('created_at');
        });
        Schema::create('specialist_suggestions', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('child_id'); $t->unsignedBigInteger('specialist_id');
            $t->string('specialty'); $t->string('status');
            $t->text('rejection_reason')->nullable(); $t->timestamp('responded_at')->nullable(); $t->timestamps();
        });
        DB::table('children')->insert(['id' => 10, 'name' => 'طفل اختبار']);
        DB::table('users')->insert([
            ['id' => 1, 'role' => 'specialist', 'specialty' => 'educational'],
            ['id' => 2, 'role' => 'specialist', 'specialty' => 'learning_support'],
            ['id' => 3, 'role' => 'specialist', 'specialty' => 'educational'],
            ['id' => 4, 'role' => 'specialist', 'specialty' => null],
        ]);
    }

    protected function tearDown(): void
    {
        foreach (['specialist_suggestions', 'child_specialist', 'users', 'children'] as $table) Schema::dropIfExists($table);
        parent::tearDown();
    }

    public function test_child_has_one_specialist_per_supported_specialty(): void
    {
        $this->assertTrue(ChildSpecialistAssignment::assign(10, 1, 'educational')['added']);
        $this->assertFalse(ChildSpecialistAssignment::assign(10, 1, 'educational')['added']);
        $this->assertSame(409, ChildSpecialistAssignment::assign(10, 3, 'educational')['status']);
        $this->assertTrue(ChildSpecialistAssignment::assign(10, 2, 'learning_support')['added']);
        $this->assertDatabaseCount('child_specialist', 2);
        $this->assertSame(422, ChildSpecialistAssignment::assign(10, 4, 'communication_support')['status']);
    }

    public function test_same_person_cannot_fill_both_slots_and_specialty_must_match(): void
    {
        $this->assertSame(422, ChildSpecialistAssignment::assign(10, 1, 'learning_support')['status']);
        $this->assertTrue(ChildSpecialistAssignment::assign(10, 4, 'educational')['added']);
        $this->assertSame(409, ChildSpecialistAssignment::assign(10, 4, 'learning_support')['status']);
        $this->assertDatabaseCount('child_specialist', 1);
    }

    public function test_direct_self_assignment_and_invitation_acceptance_cannot_replace_occupied_slot(): void
    {
        ChildSpecialistAssignment::assign(10, 1, 'educational');
        $request = Request::create('/api/test', 'POST', ['specialist_id' => 3, 'specialty' => 'educational']);
        $request->attributes->set('jwt_user', (object) ['id' => 3, 'role' => 'specialist']);
        $response = app(CareTeamController::class)->addSpecialist($request, 10);
        $this->assertSame(409, $response->getStatusCode());
        DB::table('specialist_suggestions')->insert([
            'id' => 99, 'child_id' => 10, 'specialist_id' => 3,
            'specialty' => 'educational', 'status' => 'pending',
        ]);
        $response = app(SpecialistSuggestionController::class)->accept($request, 99);
        $this->assertSame(409, $response->getStatusCode());
        $this->assertDatabaseHas('specialist_suggestions', ['id' => 99, 'status' => 'pending', 'responded_at' => null]);
        $this->assertDatabaseCount('child_specialist', 1);
    }

    public function test_generic_team_removal_cannot_bypass_specialist_self_removal_rule(): void
    {
        ChildSpecialistAssignment::assign(10, 1, 'educational');
        ChildSpecialistAssignment::assign(10, 2, 'learning_support');
        $request = Request::create('/api/test', 'DELETE');
        $request->attributes->set('jwt_user', (object) ['id' => 1, 'role' => 'specialist']);
        $response = app(CareTeamController::class)->removeCareTeamMember($request, 10, 2);
        $this->assertSame(403, $response->getStatusCode());
        $this->assertDatabaseCount('child_specialist', 2);
    }

    public function test_historical_full_teams_are_preserved_and_cannot_grow(): void
    {
        DB::table('child_specialist')->insert([
            ['child_id' => 10, 'specialist_id' => 50, 'specialty' => 'communication_support', 'assigned_at' => now(), 'created_at' => now()],
            ['child_id' => 10, 'specialist_id' => 51, 'specialty' => 'learning_behavior', 'assigned_at' => now(), 'created_at' => now()],
        ]);
        $this->assertSame(409, ChildSpecialistAssignment::assign(10, 1, 'educational')['status']);
        $this->assertDatabaseCount('child_specialist', 2);
    }
}
