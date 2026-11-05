<?php

namespace Tests\Feature;

use App\Http\Controllers\JabaliaSuccessStoryController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\ValidationException;
use Tests\TestCase;

class JabaliaSuccessStoryTest extends TestCase
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
        Schema::create('children', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id');
        });
        Schema::create('grades', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id');
        });
        Schema::create('sections', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('grade_id');
        });
        Schema::create('student_enrollments', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('child_id');
            $t->unsignedBigInteger('section_id'); $t->string('status');
        });
        Schema::create('jabalia_student_success_stories', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id'); $t->unsignedBigInteger('school_id');
            $t->unsignedBigInteger('child_id'); $t->date('observed_on'); $t->string('title');
            $t->text('narrative'); $t->unsignedBigInteger('recorded_by')->nullable();
            $t->timestamps();
        });
        DB::table('organizations')->insert([['id'=>1,'slug'=>'jabalia'], ['id'=>2,'slug'=>'other']]);
        DB::table('schools')->insert([
            ['id'=>1,'organization_id'=>1], ['id'=>2,'organization_id'=>1], ['id'=>3,'organization_id'=>2],
        ]);
        DB::table('children')->insert([
            ['id'=>10,'organization_id'=>1], ['id'=>11,'organization_id'=>1], ['id'=>12,'organization_id'=>2],
        ]);
        DB::table('grades')->insert([['id'=>1,'school_id'=>1],['id'=>2,'school_id'=>2],['id'=>3,'school_id'=>3]]);
        DB::table('sections')->insert([['id'=>1,'grade_id'=>1],['id'=>2,'grade_id'=>2],['id'=>3,'grade_id'=>3]]);
        DB::table('student_enrollments')->insert([
            ['id'=>1,'child_id'=>10,'section_id'=>1,'status'=>'withdrawn'],
            ['id'=>2,'child_id'=>11,'section_id'=>2,'status'=>'active'],
            ['id'=>3,'child_id'=>12,'section_id'=>3,'status'=>'active'],
        ]);
    }

    protected function tearDown(): void
    {
        foreach (['jabalia_student_success_stories','student_enrollments','sections','grades','children','schools','organizations'] as $table) {
            Schema::dropIfExists($table);
        }
        parent::tearDown();
    }

    private function request(array $data = [], int $organization = 1, string $slug = 'jabalia', string $role = 'institution'): Request
    {
        $r = Request::create('/api/institutions/'.$slug.'/schools/1/success-stories', 'POST', $data);
        $r->attributes->set('organization', (object) ['id'=>$organization,'slug'=>$slug]);
        $r->attributes->set('jwt_user', (object) ['id'=>30,'role'=>$role]);
        return $r;
    }

    private function payload(): array
    {
        return [
            'child_id'=>10, 'observed_on'=>now()->subDay()->toDateString(),
            'title'=>'Improved class participation',
            'narrative'=>'The student completed the visual reading exercises in class.',
        ];
    }

    public function test_private_story_can_be_added_to_an_enrolled_child_even_after_transfer_and_listed_within_school(): void
    {
        $controller = app(JabaliaSuccessStoryController::class);
        $response = $controller->store($this->request($this->payload()), 'jabalia', 1);
        $this->assertSame(201, $response->status());
        $this->assertSame('internal_only', $response->getData(true)['publication_status']);
        $this->assertSame(30, DB::table('jabalia_student_success_stories')->value('recorded_by'));
        $listed = $controller->index($this->request(), 'jabalia', 1)->getData(true);
        $this->assertCount(1, $listed['stories']['data']);
        $this->assertSame(10, $listed['stories']['data'][0]['child_id']);
        $this->assertSame('internal_only', $listed['publication_status']);
        $this->assertCount(0, $controller->index($this->request(), 'jabalia', 2)->getData(true)['stories']['data']);
    }

    public function test_cross_school_cross_tenant_and_non_institution_actors_cannot_access_or_create(): void
    {
        $controller = app(JabaliaSuccessStoryController::class);
        $payload = $this->payload();
        $this->assertSame(404, $controller->store($this->request($payload), 'jabalia', 2)->status());
        $this->assertSame(404, $controller->store($this->request($payload, 2, 'other'), 'other', 3)->status());
        $this->assertSame(404, $controller->store($this->request($payload, 1, 'jabalia', 'parent'), 'jabalia', 1)->status());
        $this->assertSame(404, $controller->index($this->request([], 1, 'jabalia', 'school'), 'jabalia', 1)->status());
        $payload['child_id'] = 11;
        $this->assertSame(404, $controller->store($this->request($payload), 'jabalia', 1)->status());
        $payload['child_id'] = 12;
        $this->assertSame(404, $controller->store($this->request($payload), 'jabalia', 1)->status());
        $this->assertSame(0, DB::table('jabalia_student_success_stories')->count());
    }

    public function test_whitespace_and_future_observation_are_denied_without_a_database_write(): void
    {
        $controller = app(JabaliaSuccessStoryController::class);
        $data = $this->payload();
        $data['observed_on'] = now()->addDay()->toDateString();
        try {
            $controller->store($this->request($data), 'jabalia', 1);
            $this->fail('Future date accepted');
        } catch (ValidationException $e) {
            $this->assertArrayHasKey('observed_on', $e->errors());
        }
        $data = $this->payload();
        $data['narrative'] = '          ';
        try {
            $controller->store($this->request($data), 'jabalia', 1);
            $this->fail('Blank narrative accepted');
        } catch (ValidationException $e) {
            $this->assertArrayHasKey('narrative', $e->errors());
        }
        $this->assertSame(0, DB::table('jabalia_student_success_stories')->count());
    }

    public function test_unauthenticated_http_routes_are_protected(): void
    {
        $url = '/api/institutions/jabalia/schools/1/success-stories';
        foreach (['GET', 'POST'] as $method) {
            $this->assertContains($this->json($method, $url)->status(), [401,403]);
        }
    }
}
