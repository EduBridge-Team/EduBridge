<?php

namespace Tests\Feature;

use App\Http\Controllers\SchoolOperationsController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\ValidationException;
use Tests\TestCase;

/**
 * Synthetic, isolated school director acceptance scenario.
 * NEVER run against a production database or an operator's real school.
 */
class SchoolFinalIsolatedAcceptanceTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Schema::create('organizations', function (Blueprint $t) {
            $t->id(); $t->string('slug'); $t->boolean('is_active')->default(true);
        });
        Schema::create('schools', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id')->nullable();
            $t->string('name'); $t->boolean('is_active')->default(true);
            $t->timestamp('official_email_verified_at')->nullable();
        });
        Schema::create('users', function (Blueprint $t) {
            $t->id(); $t->string('name'); $t->string('role');
        });
        Schema::create('school_accounts', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('user_id');
        });
        Schema::create('school_management_assignments', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('user_id');
            $t->string('role'); $t->json('permissions')->nullable();
            $t->timestamp('ends_at')->nullable();
        });
        Schema::create('school_internal_identities', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('user_id');
            $t->boolean('is_active');
        });
        Schema::create('academic_years', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->string('name');
            $t->date('starts_on'); $t->date('ends_on');
            $t->boolean('is_current')->default(false); $t->timestamps();
        });
        Schema::create('academic_terms', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('academic_year_id'); $t->string('name');
            $t->integer('position'); $t->date('starts_on'); $t->date('ends_on'); $t->timestamps();
        });
        Schema::create('grades', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->string('name');
            $t->string('code')->nullable(); $t->integer('position')->default(1);
            $t->boolean('is_active')->default(true); $t->timestamps();
        });
        Schema::create('subjects', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->string('name');
            $t->string('code')->nullable(); $t->string('color')->nullable();
            $t->boolean('is_active')->default(true); $t->timestamps();
        });
        Schema::create('sections', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('grade_id'); $t->unsignedBigInteger('academic_year_id');
            $t->string('name'); $t->integer('capacity')->nullable();
            $t->unsignedBigInteger('homeroom_teacher_id')->nullable(); $t->timestamps();
        });
        Schema::create('teacher_assignments', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('section_id'); $t->unsignedBigInteger('subject_id');
            $t->unsignedBigInteger('teacher_id'); $t->timestamps();
        });
        Schema::create('timetable_entries', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('academic_year_id');
            $t->unsignedBigInteger('section_id'); $t->unsignedBigInteger('subject_id');
            $t->unsignedBigInteger('teacher_id')->nullable(); $t->integer('weekday');
            $t->integer('period_number'); $t->string('starts_at')->nullable();
            $t->string('ends_at')->nullable(); $t->string('room')->nullable(); $t->timestamps();
        });
        Schema::create('curriculum_books', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id');
            $t->unsignedBigInteger('academic_year_id')->nullable();
            $t->unsignedBigInteger('grade_id'); $t->unsignedBigInteger('subject_id');
            $t->string('title'); $t->string('semester')->nullable();
            $t->string('edition')->nullable(); $t->string('source_name')->nullable();
            $t->string('source_url')->nullable(); $t->string('storage_path')->nullable();
            $t->string('status')->default('draft'); $t->timestamps();
        });
        Schema::create('curriculum_units', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('curriculum_book_id');
            $t->string('title'); $t->integer('position'); $t->timestamps();
        });
        Schema::create('curriculum_lessons', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('curriculum_unit_id'); $t->string('title');
            $t->integer('position'); $t->string('source_pages')->nullable();
            $t->text('content_text')->nullable(); $t->text('metadata')->nullable(); $t->timestamps();
        });
        Schema::create('children', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id')->nullable(); $t->string('name');
        });
        Schema::create('student_enrollments', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('section_id'); $t->unsignedBigInteger('child_id');
            $t->string('status'); $t->date('enrolled_on'); $t->date('left_on')->nullable(); $t->timestamps();
        });
        Schema::create('attendance_sessions', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('section_id');
            $t->unsignedBigInteger('subject_id')->nullable(); $t->unsignedBigInteger('teacher_id')->nullable();
            $t->date('attendance_date'); $t->integer('period_number')->nullable();
            $t->string('status')->default('open'); $t->text('notes')->nullable(); $t->timestamps();
        });
        Schema::create('attendance_records', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('attendance_session_id'); $t->unsignedBigInteger('child_id');
            $t->string('status'); $t->string('note')->nullable();
            $t->unsignedBigInteger('marked_by')->nullable(); $t->timestamp('marked_at')->nullable();
            $t->timestamps();
        });
        Schema::create('school_staff_attendance', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('user_id');
            $t->date('attendance_date'); $t->string('status');
            $t->unsignedBigInteger('recorded_by'); $t->timestamps();
            $t->unique(['school_id', 'user_id', 'attendance_date']);
        });

        DB::table('organizations')->insert([
            ['id' => 1, 'slug' => 'demo', 'is_active' => true],
            ['id' => 2, 'slug' => 'foreign', 'is_active' => true],
        ]);
        DB::table('schools')->insert([
            ['id' => 10, 'organization_id' => 1, 'name' => 'Acceptance school', 'is_active' => true, 'official_email_verified_at' => now()],
            ['id' => 20, 'organization_id' => 1, 'name' => 'Sibling school', 'is_active' => true, 'official_email_verified_at' => null],
            ['id' => 30, 'organization_id' => 2, 'name' => 'Foreign school', 'is_active' => true, 'official_email_verified_at' => null],
        ]);
        DB::table('users')->insert([
            ['id' => 10, 'name' => 'Old director', 'role' => 'school_director'],
            ['id' => 11, 'name' => 'New director', 'role' => 'school_director'],
            ['id' => 12, 'name' => 'Teacher', 'role' => 'teacher'],
            ['id' => 13, 'name' => 'Staff', 'role' => 'staff'],
            ['id' => 14, 'name' => 'Deputy', 'role' => 'teacher'],
            ['id' => 90, 'name' => 'Official school account', 'role' => 'school'],
        ]);
        DB::table('school_accounts')->insert(['school_id' => 10, 'user_id' => 90]);
        DB::table('school_management_assignments')->insert([
            ['school_id' => 10, 'user_id' => 10, 'role' => 'director', 'permissions' => null, 'ends_at' => null],
            ['school_id' => 10, 'user_id' => 14, 'role' => 'deputy_director', 'permissions' => json_encode([]), 'ends_at' => null],
        ]);
        DB::table('school_internal_identities')->insert([
            ['school_id' => 10, 'user_id' => 12, 'is_active' => true],
            ['school_id' => 10, 'user_id' => 13, 'is_active' => true],
        ]);
        DB::table('children')->insert(['id' => 50, 'organization_id' => 1, 'name' => 'Synthetic pupil']);
    }

    protected function tearDown(): void
    {
        foreach ([
            'school_staff_attendance', 'attendance_records', 'attendance_sessions',
            'student_enrollments', 'children', 'curriculum_lessons', 'curriculum_units',
            'curriculum_books', 'timetable_entries', 'teacher_assignments', 'sections',
            'subjects', 'grades', 'academic_terms', 'academic_years',
            'school_internal_identities', 'school_management_assignments',
            'school_accounts', 'users', 'schools', 'organizations',
        ] as $table) Schema::dropIfExists($table);
        parent::tearDown();
    }

    private function operation(string $action, string $method = 'GET', array $body = [], int $actor = 10): \Illuminate\Http\JsonResponse
    {
        $request = Request::create('/api/school/operations/'.$action, $method, $body);
        $request->attributes->set('jwt_user', (object) [
            'id' => $actor, 'role' => $actor === 90 ? 'school' : 'school_director',
        ]);
        return app(SchoolOperationsController::class)->handle($request, $action);
    }

    private function write(string $action, array $body = [], int $actor = 10, string $method = 'POST'): \Illuminate\Http\JsonResponse
    {
        return $this->operation($action, $method, ['expected_school_id' => 10, ...$body], $actor);
    }

    public function test_director_creates_real_school_operations_and_successor_keeps_every_record(): void
    {
        $year = $this->write('years', [
            'name' => '2026/2027', 'starts_on' => '2026-09-01',
            'ends_on' => '2027-06-30', 'is_current' => true,
        ]);
        $this->assertSame(201, $year->getStatusCode());
        $yearId = $year->getData(true)['academic_year']['id'];

        $grade = $this->write('grades', ['name' => 'Grade 2', 'position' => 2]);
        $this->assertSame(201, $grade->getStatusCode());
        $gradeId = $grade->getData(true)['grade']['id'];

        $subject = $this->write('subjects', ['name' => 'Arabic']);
        $this->assertSame(201, $subject->getStatusCode());
        $subjectId = $subject->getData(true)['subject']['id'];

        $section = $this->write('sections', [
            'name' => 'A', 'academic_year_id' => $yearId, 'grade_id' => $gradeId, 'capacity' => 30,
        ]);
        $this->assertSame(201, $section->getStatusCode());
        $sectionId = $section->getData(true)['section']['id'];

        $term = $this->write('terms', [
            'academic_year_id' => $yearId, 'name' => 'First term',
            'position' => 1, 'starts_on' => '2026-09-01', 'ends_on' => '2026-12-30',
        ]);
        $this->assertSame(201, $term->getStatusCode());

        $teacher = $this->write('assign-teacher', [
            'section_id' => $sectionId, 'subject_id' => $subjectId, 'teacher_id' => 12,
        ]);
        $this->assertSame(201, $teacher->getStatusCode());

        $timetable = $this->write('timetable-create', [
            'academic_year_id' => $yearId, 'section_id' => $sectionId,
            'subject_id' => $subjectId, 'teacher_id' => 12,
            'weekday' => 1, 'period_number' => 2,
        ]);
        $this->assertSame(201, $timetable->getStatusCode());
        $this->assertSame(409, $this->write('timetable-create', [
            'academic_year_id' => $yearId, 'section_id' => $sectionId,
            'subject_id' => $subjectId, 'teacher_id' => 12,
            'weekday' => 1, 'period_number' => 2,
        ])->getStatusCode());

        $book = $this->write('books', [
            'grade_id' => $gradeId, 'subject_id' => $subjectId, 'title' => 'Arabic workbook',
        ]);
        $this->assertSame(201, $book->getStatusCode());
        $bookId = $book->getData(true)['book']['id'];
        $unit = $this->write('units', ['book_id' => $bookId, 'title' => 'Reading', 'position' => 1]);
        $this->assertSame(201, $unit->getStatusCode());
        $unitId = $unit->getData(true)['unit']['id'];
        $lesson = $this->write('lessons', [
            'unit_id' => $unitId, 'title' => 'Freedom is beautiful',
            'position' => 1, 'content_text' => 'Synthetic acceptance lesson',
        ]);
        $this->assertSame(201, $lesson->getStatusCode());
        DB::table('student_enrollments')->insert([
            'section_id' => $sectionId, 'child_id' => 50, 'status' => 'active',
            'enrolled_on' => '2026-09-01', 'created_at' => now(), 'updated_at' => now(),
        ]);

        $attendance = $this->write('attendance-create', [
            'section_id' => $sectionId, 'attendance_date' => '2026-11-03',
            'period_number' => 2,
        ]);
        $this->assertSame(201, $attendance->getStatusCode());
        $sessionId = $attendance->getData(true)['attendance_session']['id'];
        $this->assertSame(200, $this->write('attendance-mark', [
            'session_id' => $sessionId, 'records' => [['child_id' => 50, 'status' => 'excused']],
        ], 10, 'PUT')->getStatusCode());
        $this->assertSame(200, $this->write('staff-attendance-mark', [
            'date' => '2026-11-03', 'records' => [['user_id' => 13, 'status' => 'present']],
        ], 10, 'PUT')->getStatusCode());

        $report = $this->operation('attendance-report', 'GET', [
            'from' => '2026-11-03', 'to' => '2026-11-03', 'section_id' => $sectionId,
        ])->getData(true);
        $this->assertSame(10, $report['school_id']);
        $this->assertSame(1, $report['summary']['excused']);
        $this->assertCount(1, $report['students']);
        $this->assertSame(1, $this->operation('reports')->getData(true)['statistics']['teachers']);

        // Changing the director is an assignment change, not a data migration.
        DB::table('school_management_assignments')->where('school_id', 10)
            ->where('user_id', 10)->update(['ends_at' => now()]);
        DB::table('school_management_assignments')->insert([
            'school_id' => 10, 'user_id' => 11, 'role' => 'director',
            'permissions' => null, 'ends_at' => null,
        ]);
        foreach (['academic', 'students', 'attendance', 'timetable', 'curriculum', 'reports'] as $action) {
            $this->assertSame(403, $this->operation($action, 'GET', [], 10)->getStatusCode(), $action);
            $this->assertSame(200, $this->operation($action, 'GET', [], 11)->getStatusCode(), $action);
        }
        $newAcademic = $this->operation('academic', 'GET', [], 11)->getData(true);
        $this->assertCount(1, $newAcademic['academic_years']);
        $this->assertCount(1, $newAcademic['sections']);
        $this->assertCount(1, $newAcademic['academic_terms']);
        $this->assertCount(1, $this->operation('curriculum', 'GET', [], 11)->getData(true)['lessons']);
        $this->assertSame(1, $this->operation('reports', 'GET', [], 11)->getData(true)['statistics']['students']);
        $this->assertSame(1, $this->operation('attendance-report', 'GET', [
            'from' => '2026-11-03', 'to' => '2026-11-03',
        ], 11)->getData(true)['summary']['excused']);
        $this->assertSame(403, $this->write('years', [
            'name' => 'Forbidden 2027', 'starts_on' => '2027-09-01',
            'ends_on' => '2028-06-30',
        ])->getStatusCode());
        $this->assertDatabaseHas('school_staff_attendance', [
            'school_id' => 10, 'user_id' => 13, 'status' => 'present',
        ]);
    }

    public function test_official_school_and_deputy_cannot_escape_permission_or_school_boundaries(): void
    {
        $this->assertSame(403, $this->write('grades', [
            'name' => 'Unauthorized grade',
        ], 90)->getStatusCode());
        $this->assertSame(200, $this->operation('academic', 'GET', [], 90)->getStatusCode());
        $this->assertSame(403, $this->operation('attendance', 'GET', [], 14)->getStatusCode());
        DB::table('school_management_assignments')->where('user_id', 14)
            ->update(['permissions' => json_encode(['attendance'])]);
        $this->assertSame(200, $this->operation('attendance', 'GET', [], 14)->getStatusCode());
        $this->assertSame(403, $this->operation('curriculum', 'GET', [], 14)->getStatusCode());
        DB::table('school_management_assignments')->where('user_id', 14)
            ->update(['permissions' => json_encode([])]);
        $this->assertSame(403, $this->operation('attendance', 'GET', [], 14)->getStatusCode());

        $this->expectException(ValidationException::class);
        $this->write('grades', ['name' => 'Foreign grade', 'expected_school_id' => 20]);
    }
}
