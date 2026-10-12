<?php

namespace Tests\Feature;

use App\Http\Controllers\NoorMemoryController;
use App\Services\Noor\MemoryStore;
use App\Services\Noor\StudentContextService;
use Illuminate\Http\Request;
use Symfony\Component\HttpKernel\Exception\HttpException;
use Tests\TestCase;

class NoorMemoryControllerTest extends TestCase
{
    private function request(int $id, string $role): Request
    {
        $request = Request::create('/api/assistant/students/10/memory', 'GET');
        $request->attributes->set('jwt_user', (object) ['id' => $id, 'role' => $role]);
        return $request;
    }

    public function test_teacher_cannot_manage_memory_even_if_assigned(): void
    {
        $context = \Mockery::mock(StudentContextService::class);
        $context->shouldNotReceive('build');
        $store = \Mockery::mock(MemoryStore::class);
        $store->shouldNotReceive('list');
        $store->shouldNotReceive('enabled');

        $this->expectException(HttpException::class);
        (new NoorMemoryController())->index($this->request(2, 'teacher'), 10, $context, $store);
    }

    public function test_unassigned_parent_does_not_reach_memory_store(): void
    {
        $context = \Mockery::mock(StudentContextService::class);
        $context->shouldReceive('build')->once()->andThrow(new HttpException(403));
        $store = \Mockery::mock(MemoryStore::class);
        $store->shouldNotReceive('list');
        $store->shouldNotReceive('enabled');

        $this->expectException(HttpException::class);
        (new NoorMemoryController())->index($this->request(99, 'parent'), 10, $context, $store);
    }

    public function test_assigned_parent_receives_only_scoped_memories(): void
    {
        $context = \Mockery::mock(StudentContextService::class);
        $context->shouldReceive('build')->once()->with(10, \Mockery::type('object'))->andReturn(['child_id' => 10]);
        $store = \Mockery::mock(MemoryStore::class);
        $store->shouldReceive('enabled')->once()->with(1, 10)->andReturn(true);
        $store->shouldReceive('list')->once()->with(1, 10)->andReturn([]);
        $response = (new NoorMemoryController())->index($this->request(1, 'parent'), 10, $context, $store);
        $this->assertSame(200, $response->status());
        $this->assertSame(['enabled' => true, 'memories' => []], $response->getData(true));
    }
}
