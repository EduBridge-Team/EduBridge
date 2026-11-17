<?php

namespace Tests\Feature;

use App\Http\Controllers\InstitutionSubstitutionController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class InstitutionSubstitutionWeekdayTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('organizations', function (Blueprint $t) {
            $t->id(); $t->string('slug');
        });
        Schema::create('schools', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id');
        });
        Schema::create('users', function (Blueprint $t) {
            $t->id(); $t->string('name');
        });
        Schema::create('organization_user', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id');
            $t->unsignedBigInteger('user_id'); $t->string('role');
            $t->boolean('is_active');
        });
        Schema::create('grades', function (Blueprint $t) {
            $t->id(); $t->string('name');
        });
        Schema::create('sections', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('grade_id'); $t->string('name');
        });
        Schema::create('subjects', function (Blueprint $t) {
            $t->id(); $t->string('name');
        });
        Schema::create('timetable_entries', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id');
            $t->unsignedBigInteger('section_id'); $t->unsignedBigInteger('subject_id');
            $t->unsignedBigInteger('teacher_id'); $t->integer('weekday');
            $t->integer('period_number');
        });
        Schema::create('teacher_absences', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id');
            $t->unsignedBigInteger('teacher_id'); $t->date('absence_date');
            $t->string('reason')->nullable(); $t->string('status');
            $t->unsignedBigInteger('reported_by')->nullable(); $t->timestamps();
        });
        Schema::create('class_substitutions', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('timetable_entry_id');
            $t->date('class_date'); $t->unsignedBigInteger('original_teacher_id');
            $t->unsignedBigInteger('substitute_teacher_id'); $t->string('status');
            $t->string('notes')->nullable(); $t->unsignedBigInteger('assigned_by');
            $t->timestamps();
        });

        DB::table('organizations')->insert([
            ['id' => 1, 'slug' => 'jabalia'], ['id' => 2, 'slug' => 'demo'],
        ]);
        DB::table('schools')->insert([
            ['id' => 1, 'organization_id' => 1],
            ['id' => 2, 'organization_id' => 2],
        ]);
        DB::table('users')->insert([
            ['id' => 10, 'name' => 'Original'],
            ['id' => 11, 'name' => 'Substitute'],
            ['id' => 99, 'name' => 'Operator'],
        ]);
        foreach ([1, 2] as $organization) {
            foreach ([10, 11] as $teacher) {
                DB::table('organization_user')->insert([
                    'organization_id' => $organization, 'user_id' => $teacher,
                    'role' => 'teacher', 'is_active' => true,
                ]);
            }
        }
        DB::table('grades')->insert(['id' => 1, 'name' => 'Grade']);
        DB::table('sections')->insert(['id' => 1, 'grade_id' => 1, 'name' => 'A']);
        DB::table('subjects')->insert(['id' => 1, 'name' => 'Math']);
        DB::table('timetable_entries')->insert([
            ['id' => 101, 'school_id' => 1, 'section_id' => 1, 'subject_id' => 1,
                'teacher_id' => 10, 'weekday' => 7, 'period_number' => 1],
            ['id' => 102, 'school_id' => 2, 'section_id' => 1, 'subject_id' => 1,
                'teacher_id' => 10, 'weekday' => 1, 'period_number' => 1],
        ]);
    }

    protected function tearDown(): void
    {
        foreach (['class_substitutions', 'teacher_absences', 'timetable_entries',
            'subjects', 'sections', 'grades', 'organization_user',
            'users', 'schools', 'organizations'] as $table) {
            Schema::dropIfExists($table);
        }
        parent::tearDown();
    }

    private function requestFor(int $orgId, array $data): Request
    {
        $request = Request::create('/api/institutions/test', 'POST', $data);
        $request->attributes->set('organization', DB::table('organizations')->find($orgId));
        $request->attributes->set('jwt_user', (object) ['id' => 99]);
        return $request;
    }

    public function test_sunday_absence_matches_jabalia_iso_slots_and_legacy_slots(): void
    {
        foreach ([[1, 'jabalia', 101], [2, 'demo', 102]] as [$orgId, $slug, $entry]) {
            $response = app(InstitutionSubstitutionController::class)->reportAbsence(
                $this->requestFor($orgId, [
                    'teacher_id' => 10, 'absence_date' => '2026-10-25',
                ]), $slug, $orgId
            );
            $this->assertSame(201, $response->status());
            $ids = collect($response->getData(true)['affected_classes'])->pluck('id')->all();
            $this->assertSame([$entry], $ids);
        }
    }

    public function test_sunday_substitute_uses_correct_weekday_for_each_tenant(): void
    {
        foreach ([[1, 'jabalia', 101], [2, 'demo', 102]] as [$orgId, $slug, $entry]) {
            $response = app(InstitutionSubstitutionController::class)->assign(
                $this->requestFor($orgId, [
                    'class_date' => '2026-10-25', 'substitute_teacher_id' => 11,
                ]), $slug, $orgId, $entry
            );
            $this->assertSame(201, $response->status());
            $this->assertSame(11, (int) $response->getData(true)['substitution']['substitute_teacher_id']);
        }
        $this->assertSame(2, DB::table('class_substitutions')->count());
    }

    public function test_wrong_weekday_cannot_assign_substitute(): void
    {
        $response = app(InstitutionSubstitutionController::class)->assign(
            $this->requestFor(1, [
                'class_date' => '2026-10-26', 'substitute_teacher_id' => 11,
            ]), 'jabalia', 1, 101
        );
        $this->assertSame(422, $response->status());
        $this->assertSame(0, DB::table('class_substitutions')->count());
    }
}
