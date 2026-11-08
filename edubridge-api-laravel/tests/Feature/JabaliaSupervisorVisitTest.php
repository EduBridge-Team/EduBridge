<?php

namespace Tests\Feature;

use App\Http\Controllers\JabaliaSupervisorVisitController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\ValidationException;
use Tests\TestCase;

class JabaliaSupervisorVisitTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('organizations', function (Blueprint $table) {
            $table->id();
            $table->string('slug');
        });
        Schema::create('schools', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('organization_id');
        });
        Schema::create('jabalia_supervisor_visits', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('organization_id');
            $table->unsignedBigInteger('school_id');
            $table->date('visited_on');
            $table->string('supervisor_name');
            $table->text('findings');
            $table->text('corrective_action');
            $table->date('due_on')->nullable();
            $table->string('status');
            $table->unsignedBigInteger('recorded_by')->nullable();
            $table->timestamps();
        });
        Schema::create('jabalia_supervisor_visit_events', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('visit_id');
            $table->unsignedBigInteger('organization_id');
            $table->unsignedBigInteger('school_id');
            $table->string('action');
            $table->string('from_status')->nullable();
            $table->string('to_status');
            $table->text('note')->nullable();
            $table->unsignedBigInteger('actor_id')->nullable();
            $table->timestamp('created_at');
        });

        DB::table('organizations')->insert([
            ['id' => 1, 'slug' => 'jabalia'],
            ['id' => 2, 'slug' => 'other'],
        ]);
        DB::table('schools')->insert([
            ['id' => 1, 'organization_id' => 1],
            ['id' => 2, 'organization_id' => 1],
            ['id' => 3, 'organization_id' => 2],
        ]);
    }

    protected function tearDown(): void
    {
        foreach (['jabalia_supervisor_visit_events', 'jabalia_supervisor_visits', 'schools', 'organizations'] as $table) {
            Schema::dropIfExists($table);
        }
        parent::tearDown();
    }

    private function request(
        array $data = [], int $organization = 1, string $slug = 'jabalia', bool $institution = true
    ): Request {
        $request = Request::create(
            '/api/institutions/'.$slug.'/schools/1/supervisor-visits',
            'POST', $data
        );
        $request->attributes->set('organization', (object) [
            'id' => $organization, 'slug' => $slug,
        ]);
        if ($institution) {
            $request->attributes->set('jwt_user', (object) [
                'id' => 30, 'role' => 'institution',
            ]);
        }
        return $request;
    }

    private function payload(): array
    {
        return [
            'visited_on' => now()->subDay()->toDateString(),
            'supervisor_name' => 'Supervision officer',
            'findings' => 'Classroom accessibility reviewed',
            'corrective_action' => 'Improve visual supports',
            'due_on' => now()->addWeek()->toDateString(),
        ];
    }

    public function test_visit_open_complete_reopen_appends_audited_events_without_losing_history(): void
    {
        $controller = app(JabaliaSupervisorVisitController::class);
        $response = $controller->store($this->request($this->payload()), 'jabalia', 1);
        $this->assertSame(201, $response->status());
        $visit = $response->getData(true)['visit'];
        $id = $visit['id'];
        $this->assertSame('open', $visit['status']);
        $this->assertSame(30, $visit['recorded_by']);

        $close = $controller->updateStatus($this->request([
            'expected_status' => 'open', 'status' => 'completed',
            'note' => 'Visual supports supplied and checked',
        ]), 'jabalia', 1, $id);
        $this->assertSame(200, $close->status());
        $this->assertSame('completed', $close->getData(true)['visit']['status']);

        $stale = $controller->updateStatus($this->request([
            'expected_status' => 'open', 'status' => 'completed',
            'note' => 'Stale attempt',
        ]), 'jabalia', 1, $id);
        $this->assertSame(409, $stale->status());
        $this->assertSame(2, DB::table('jabalia_supervisor_visit_events')->count());

        $reopen = $controller->updateStatus($this->request([
            'expected_status' => 'completed', 'status' => 'open',
            'note' => 'Follow-up evidence needs revision',
        ]), 'jabalia', 1, $id);
        $this->assertSame(200, $reopen->status());
        $events = DB::table('jabalia_supervisor_visit_events')->orderBy('id')->get();
        $this->assertSame(['created', 'status_changed', 'status_changed'], $events->pluck('action')->all());
        $this->assertSame([null, 'open', 'completed'], $events->pluck('from_status')->all());
        $this->assertSame(['open', 'completed', 'open'], $events->pluck('to_status')->all());
        $this->assertSame('Visual supports supplied and checked', $events[1]->note);

        $listed = $controller->index($this->request(), 'jabalia', 1)->getData(true);
        $this->assertCount(1, $listed['visits']['data']);
        $this->assertCount(3, $listed['recent_events']);
        $this->assertSame('open', $listed['visits']['data'][0]['status']);
    }

    public function test_other_school_organization_and_untrusted_actor_cannot_read_or_change_visits(): void
    {
        $controller = app(JabaliaSupervisorVisitController::class);
        $id = $controller->store($this->request($this->payload()), 'jabalia', 1)
            ->getData(true)['visit']['id'];

        $this->assertSame(404, $controller->index(
            $this->request([], 2, 'other'), 'other', 1
        )->status());
        $this->assertSame(404, $controller->index(
            $this->request([], 1, 'jabalia', false), 'jabalia', 1
        )->status());

        $otherSchool = $controller->index($this->request(), 'jabalia', 2)->getData(true);
        $this->assertCount(0, $otherSchool['visits']['data']);
        $this->assertCount(0, $otherSchool['recent_events']);

        $body = [
            'expected_status' => 'open', 'status' => 'completed',
            'note' => 'Should be denied',
        ];
        $this->assertSame(404, $controller->updateStatus(
            $this->request($body), 'jabalia', 2, $id
        )->status());
        $this->assertSame(404, $controller->updateStatus(
            $this->request($body, 2, 'other'), 'other', 1, $id
        )->status());
        $this->assertSame(404, $controller->store(
            $this->request($this->payload()), 'jabalia', 3
        )->status());
        $this->assertSame(1, DB::table('jabalia_supervisor_visits')->count());
        $this->assertSame(1, DB::table('jabalia_supervisor_visit_events')->count());
    }

    public function test_empty_notes_and_future_visit_are_rejected_without_persistence(): void
    {
        $controller = app(JabaliaSupervisorVisitController::class);
        $payload = $this->payload();
        $payload['visited_on'] = now()->addMonth()->toDateString();
        try {
            $controller->store($this->request($payload), 'jabalia', 1);
            $this->fail('Future completed visit should not be accepted');
        } catch (ValidationException $exception) {
            $this->assertArrayHasKey('visited_on', $exception->errors());
        }

        $payload = $this->payload();
        $payload['findings'] = '   ';
        try {
            $controller->store($this->request($payload), 'jabalia', 1);
            $this->fail('Whitespace-only findings must be rejected by validation');
        } catch (ValidationException $exception) {
            $this->assertArrayHasKey('findings', $exception->errors());
        }
        $this->assertSame(0, DB::table('jabalia_supervisor_visits')->count());
        $this->assertSame(0, DB::table('jabalia_supervisor_visit_events')->count());
    }

    public function test_unauthenticated_http_supervisor_visit_routes_require_membership(): void
    {
        $url = '/api/institutions/jabalia/schools/1/supervisor-visits';
        foreach ([['GET', $url], ['POST', $url],
            ['PATCH', $url.'/1']] as [$method, $path]) {
            $response = $this->json($method, $path);
            $this->assertContains($response->status(), [401, 403]);
        }
    }
}
