<?php

namespace Tests\Feature;

use App\Http\Controllers\NoorSessionDraftController;
use App\Services\Noor\StudentContextService;
use App\Services\Noor\StudentSessionDraftService;
use Illuminate\Http\Request;
use Symfony\Component\HttpKernel\Exception\HttpException;
use Tests\TestCase;

class NoorSessionDraftControllerTest extends TestCase
{
    private function request(string $role): Request
    {
        $request = Request::create('/api/assistant/students/8/draft-session', 'POST', [
            'goal' => 'تعزيز مهارات القراءة',
            'duration_minutes' => 30,
        ]);
        $request->attributes->set('jwt_user', (object) ['id' => 5, 'role' => $role]);
        return $request;
    }

    public function test_non_specialist_cannot_generate_a_session(): void
    {
        $contexts = \Mockery::mock(StudentContextService::class);
        $contexts->shouldNotReceive('build');
        $sessions = \Mockery::mock(StudentSessionDraftService::class);
        $sessions->shouldNotReceive('generate');
        $response = (new NoorSessionDraftController())->store($this->request('teacher'), 8, $contexts, $sessions);
        $this->assertSame(403, $response->status());
    }

    public function test_unassigned_specialist_cannot_generate_a_session(): void
    {
        $contexts = \Mockery::mock(StudentContextService::class);
        $contexts->shouldReceive('build')->once()->andThrow(new HttpException(403));
        $sessions = \Mockery::mock(StudentSessionDraftService::class);
        $sessions->shouldNotReceive('generate');
        $this->expectException(HttpException::class);
        (new NoorSessionDraftController())->store($this->request('specialist'), 8, $contexts, $sessions);
    }

    public function test_assigned_specialist_gets_a_review_only_draft(): void
    {
        $contexts = \Mockery::mock(StudentContextService::class);
        $contexts->shouldReceive('build')->once()->andReturn(['student' => ['age' => 8]]);
        $sessions = \Mockery::mock(StudentSessionDraftService::class);
        $sessions->shouldReceive('generate')->once()->with(
            ['student' => ['age' => 8]], 'تعزيز مهارات القراءة', 30
        )->andReturn(['title' => 'جلسة القراءة']);
        $response = (new NoorSessionDraftController())->store($this->request('specialist'), 8, $contexts, $sessions);
        $this->assertSame(200, $response->status());
        $this->assertTrue($response->getData(true)['requires_review']);
        $this->assertFalse($response->getData(true)['auto_saved']);
    }
}
