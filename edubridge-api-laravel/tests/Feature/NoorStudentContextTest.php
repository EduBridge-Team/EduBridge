<?php

namespace Tests\Feature;

use App\Services\Noor\StudentContextService;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Symfony\Component\HttpKernel\Exception\HttpException;
use Tests\TestCase;

class NoorStudentContextTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Schema::create('children', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->integer('age')->nullable();
            $table->unsignedBigInteger('assigned_teacher_id')->nullable();
            $table->string('preferred_learning_style')->nullable();
            $table->text('strengths')->nullable();
            $table->text('challenges')->nullable();
            $table->string('child_national_id')->nullable();
            $table->text('medical_history')->nullable();
        });
        Schema::create('child_parent', function (Blueprint $table) {
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('parent_id');
        });
        Schema::create('child_specialist', function (Blueprint $table) {
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('specialist_id');
        });

        DB::table('children')->insert([
            'id' => 10,
            'name' => 'سارة',
            'age' => 9,
            'assigned_teacher_id' => 2,
            'preferred_learning_style' => 'بصري',
            'strengths' => json_encode(['الصور'], JSON_UNESCAPED_UNICODE),
            'challenges' => json_encode(['القراءة'], JSON_UNESCAPED_UNICODE),
            'child_national_id' => '123456789',
            'medical_history' => 'بيانات حساسة لا يجب إرسالها لنور',
        ]);
        DB::table('child_parent')->insert(['child_id' => 10, 'parent_id' => 1]);
        DB::table('child_specialist')->insert(['child_id' => 10, 'specialist_id' => 3]);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('child_specialist');
        Schema::dropIfExists('child_parent');
        Schema::dropIfExists('children');
        parent::tearDown();
    }

    public function test_assigned_roles_can_build_student_context_without_sensitive_fields(): void
    {
        $service = app(StudentContextService::class);

        foreach ([[1, 'parent'], [2, 'teacher'], [3, 'specialist']] as [$id, $role]) {
            $context = $service->build(10, (object) ['id' => $id, 'role' => $role]);
            $this->assertSame('سارة', $context['student']['display_name']);
            $encoded = json_encode($context, JSON_UNESCAPED_UNICODE);
            $this->assertStringNotContainsString('123456789', $encoded);
            $this->assertStringNotContainsString('بيانات حساسة', $encoded);
        }
    }

    public function test_unassigned_user_is_forbidden(): void
    {
        $this->expectException(HttpException::class);
        app(StudentContextService::class)->build(10, (object) ['id' => 99, 'role' => 'teacher']);
    }
}
