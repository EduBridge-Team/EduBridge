<?php

namespace Tests\Feature;

use App\Http\Controllers\HomeworkController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class HomeworkSpecialistScopeTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('role');
        });

        Schema::create('children', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->unsignedBigInteger('assigned_teacher_id')->nullable();
        });

        Schema::create('child_parent', function (Blueprint $table) {
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('parent_id');
        });

        Schema::create('child_teacher', function (Blueprint $table) {
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('teacher_id');
        });

        Schema::create('child_specialist', function (Blueprint $table) {
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('specialist_id');
        });

        Schema::create('homeworks', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->text('description')->nullable();
            $table->unsignedBigInteger('teacher_id');
            $table->string('subject')->nullable();
            $table->timestamp('due_date')->nullable();
            $table->text('assigned_child_ids');
            $table->text('attachment_urls')->nullable();
            $table->timestamps();
        });

        Schema::create('homework_submissions', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('homework_id');
            $table->unsignedBigInteger('child_id');
            $table->text('text_answer')->nullable();
            $table->text('file_urls')->nullable();
            $table->text('file_url')->nullable();
            $table->boolean('is_late')->default(false);
            $table->integer('grade')->nullable();
            $table->text('feedback')->nullable();
            $table->unsignedBigInteger('graded_by')->nullable();
            $table->timestamp('graded_at')->nullable();
            $table->timestamp('submitted_at')->nullable();
            $table->timestamps();
        });

        DB::table('users')->insert([
            ['id' => 1, 'name' => 'معلم', 'role' => 'teacher'],
            ['id' => 3, 'name' => 'مختص', 'role' => 'specialist'],
        ]);

        DB::table('children')->insert([
            ['id' => 10, 'name' => 'طفل أ', 'assigned_teacher_id' => 1],
            ['id' => 20, 'name' => 'طفل ب', 'assigned_teacher_id' => 1],
        ]);

        DB::table('child_specialist')->insert([
            'child_id' => 10,
            'specialist_id' => 3,
        ]);

        DB::table('homeworks')->insert([
            [
                'id' => 100,
                'title' => 'واجب أ',
                'description' => 'أ',
                'teacher_id' => 1,
                'due_date' => now()->addDay(),
                'assigned_child_ids' => json_encode([10]),
                'attachment_urls' => json_encode([]),
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'id' => 200,
                'title' => 'واجب ب',
                'description' => 'ب',
                'teacher_id' => 1,
                'due_date' => now()->addDay(),
                'assigned_child_ids' => json_encode([20]),
                'attachment_urls' => json_encode([]),
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);

        DB::table('homework_submissions')->insert([
            'id' => 500,
            'homework_id' => 200,
            'child_id' => 20,
            'text_answer' => 'حل',
            'file_urls' => json_encode([]),
            'is_late' => false,
            'submitted_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('homework_submissions');
        Schema::dropIfExists('homeworks');
        Schema::dropIfExists('child_specialist');
        Schema::dropIfExists('child_teacher');
        Schema::dropIfExists('child_parent');
        Schema::dropIfExists('children');
        Schema::dropIfExists('users');

        parent::tearDown();
    }

    public function test_specialist_only_sees_homework_for_children_in_team(): void
    {
        $response = app(HomeworkController::class)->index(
            $this->request('GET', [], 3, 'specialist')
        );

        $this->assertSame(200, $response->getStatusCode());
        $homeworks = json_decode($response->getContent(), true)['homeworks'];

        $this->assertSame([100], array_column($homeworks, 'id'));
    }

    public function test_specialist_cannot_grade_submission_for_child_outside_team(): void
    {
        $response = app(HomeworkController::class)->grade(
            $this->request('POST', ['grade' => 90], 3, 'specialist'),
            500
        );

        $this->assertSame(403, $response->getStatusCode());
    }

    private function request(string $method, array $payload, int $id, string $role): Request
    {
        $request = Request::create('/api/homeworks', $method, $payload);
        $request->headers->set('Accept', 'application/json');
        $request->attributes->set('jwt_user', (object) ['id' => $id, 'role' => $role]);

        return $request;
    }
}
