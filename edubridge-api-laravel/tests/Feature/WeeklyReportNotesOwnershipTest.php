<?php

namespace Tests\Feature;

use App\Http\Controllers\WeeklyReportController;
use Carbon\Carbon;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class WeeklyReportNotesOwnershipTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('users', function (Blueprint $t) { $t->id(); $t->string('name'); });
        Schema::create('children', function (Blueprint $t) { $t->id(); $t->string('name'); $t->unsignedBigInteger('assigned_teacher_id'); });
        Schema::create('child_specialist', function (Blueprint $t) { $t->unsignedBigInteger('child_id'); $t->unsignedBigInteger('specialist_id'); });
        Schema::create('child_parent', function (Blueprint $t) { $t->unsignedBigInteger('child_id'); $t->unsignedBigInteger('parent_id'); });
        Schema::create('lessons', function (Blueprint $t) { $t->id(); });
        Schema::create('homeworks', function (Blueprint $t) { $t->id(); $t->text('assigned_child_ids'); });
        Schema::create('sessions', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('child_id'); $t->timestamp('scheduled_at'); $t->string('status'); });
        Schema::create('weekly_reports', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('child_id'); $t->unsignedBigInteger('author_id');
            $t->date('week_start'); $t->date('week_end'); $t->integer('lessons_completed'); $t->integer('progress_percentage');
            $t->text('teacher_notes')->nullable(); $t->text('specialist_notes')->nullable(); $t->text('parent_notes')->nullable();
            $t->text('achievements'); $t->text('concerns'); $t->timestamp('generated_at')->nullable(); $t->timestamps();
        });
        DB::table('users')->insert([['id' => 1, 'name' => 'المعلم'], ['id' => 2, 'name' => 'المختص']]);
        DB::table('children')->insert(['id' => 10, 'name' => 'طفل', 'assigned_teacher_id' => 1]);
        DB::table('child_specialist')->insert(['child_id' => 10, 'specialist_id' => 2]);
        DB::table('weekly_reports')->insert([
            'id' => 99, 'child_id' => 10, 'author_id' => 1,
            'week_start' => now()->startOfWeek(Carbon::MONDAY)->toDateString(),
            'week_end' => now()->startOfWeek(Carbon::MONDAY)->addDays(6)->toDateString(),
            'teacher_notes' => 'ملاحظات المعلم الأصلية', 'specialist_notes' => 'متابعة سابقة',
            'parent_notes' => 'ملاحظة ولي الأمر', 'lessons_completed' => 4, 'progress_percentage' => 80,
            'achievements' => json_encode(['إنجاز المعلم']), 'concerns' => '[]',
        ]);
    }

    protected function tearDown(): void
    {
        foreach (['weekly_reports', 'sessions', 'homeworks', 'lessons', 'child_parent', 'child_specialist', 'children', 'users'] as $t) Schema::dropIfExists($t);
        parent::tearDown();
    }

    public function test_specialist_cannot_write_teacher_report_through_general_endpoint(): void
    {
        $response = app(WeeklyReportController::class)->store($this->request('specialist', 2, [
            'child_id' => 10, 'teacher_notes' => 'محاولة تغيير',
        ]));
        $this->assertSame(403, $response->getStatusCode());
        $this->assertDatabaseHas('weekly_reports', ['id' => 99, 'teacher_notes' => 'ملاحظات المعلم الأصلية']);
    }

    public function test_specialist_followup_preserves_teacher_notes_author_and_metrics(): void
    {
        $response = app(WeeklyReportController::class)->storeSpecialist($this->request('specialist', 2, [
            'child_id' => 10, 'specialist_notes' => 'متابعة جديدة', 'teacher_notes' => 'محاولة تغيير',
            'recommendations' => 'توصية', 'progress_percentage' => 0,
        ]));
        $this->assertSame(200, $response->getStatusCode());
        $this->assertDatabaseHas('weekly_reports', [
            'id' => 99, 'teacher_notes' => 'ملاحظات المعلم الأصلية', 'author_id' => 1,
            'lessons_completed' => 4, 'progress_percentage' => 80, 'parent_notes' => 'ملاحظة ولي الأمر',
        ]);
        $this->assertStringContainsString('متابعة جديدة', DB::table('weekly_reports')->where('id', 99)->value('specialist_notes'));
    }

    public function test_teacher_report_update_preserves_specialist_and_parent_notes(): void
    {
        $response = app(WeeklyReportController::class)->store($this->request('teacher', 1, [
            'child_id' => 10, 'week_start' => now()->startOfWeek(Carbon::MONDAY)->toDateString(),
            'teacher_notes' => 'تحديث المعلم', 'lessons_completed' => 5, 'progress_percentage' => 90,
            'specialist_notes' => 'محاولة تغيير',
        ]));
        $this->assertSame(200, $response->getStatusCode());
        $this->assertDatabaseHas('weekly_reports', ['id' => 99, 'specialist_notes' => 'متابعة سابقة', 'parent_notes' => 'ملاحظة ولي الأمر']);
    }

    private function request(string $role, int $id, array $payload): Request
    {
        $request = Request::create('/api/reports/weekly', 'POST', $payload);
        $request->attributes->set('jwt_user', (object) ['id' => $id, 'role' => $role]);
        return $request;
    }
}
