<?php

namespace Tests\Feature;

use App\Http\Controllers\NoorActivityDraftController;
use App\Services\Noor\StudentActivityDraftService;
use App\Services\Noor\StudentContextService;
use Illuminate\Http\Request;
use Symfony\Component\HttpKernel\Exception\HttpException;
use Tests\TestCase;

class NoorActivityDraftControllerTest extends TestCase
{
    private function request(string $role): Request
    {
        $request = Request::create('/api/assistant/students/8/draft-activity', 'POST', [
            'topic' => 'الجمع ضمن مئة',
            'duration_minutes' => 20,
        ]);
        $request->attributes->set('jwt_user', (object) ['id' => 5, 'role' => $role]);
        return $request;
    }

    public function test_non_teacher_cannot_request_activity(): void
    {
        $context = \Mockery::mock(StudentContextService::class);
        $context->shouldNotReceive('build');
        $activities = \Mockery::mock(StudentActivityDraftService::class);
        $activities->shouldNotReceive('generate');
        $response = (new NoorActivityDraftController())->store($this->request('parent'), 8, $context, $activities);
        $this->assertSame(403, $response->status());
    }

    public function test_unassigned_teacher_does_not_trigger_generation(): void
    {
        $context = \Mockery::mock(StudentContextService::class);
        $context->shouldReceive('build')->once()->andThrow(new HttpException(403));
        $activities = \Mockery::mock(StudentActivityDraftService::class);
        $activities->shouldNotReceive('generate');
        $this->expectException(HttpException::class);
        (new NoorActivityDraftController())->store($this->request('teacher'), 8, $context, $activities);
    }

    public function test_assigned_teacher_gets_review_only_draft(): void
    {
        $context = \Mockery::mock(StudentContextService::class);
        $context->shouldReceive('build')->once()->andReturn(['student' => ['age' => 8]]);
        $activities = \Mockery::mock(StudentActivityDraftService::class);
        $activities->shouldReceive('generate')->once()->with(
            ['student' => ['age' => 8]], 'الجمع ضمن مئة', 20
        )->andReturn(['title' => 'نشاط جمع']);
        $response = (new NoorActivityDraftController())->store($this->request('teacher'), 8, $context, $activities);
        $this->assertSame(200, $response->status());
        $this->assertTrue($response->getData(true)['requires_review']);
        $this->assertFalse($response->getData(true)['auto_published']);
    }
}
