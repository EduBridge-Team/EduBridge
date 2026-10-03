<?php

namespace Tests\Feature;

use App\Http\Controllers\ChildController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class ChildCreationLinkingTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Schema::create('children', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->unsignedInteger('age')->nullable();
            foreach (['disability_type', 'disability_description', 'special_needs'] as $field) {
                $table->text($field)->nullable();
            }
            foreach (['strengths', 'challenges'] as $field) {
                $table->text($field)->nullable();
            }
            foreach (['child_national_id', 'guardian_national_id', 'guardian_id_document_url', 'kinship_document_url', 'medical_report_url'] as $field) {
                $table->string($field)->nullable();
            }
        });

        Schema::create('child_parent', function (Blueprint $table) {
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('parent_id');
        });
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('child_parent');
        Schema::dropIfExists('children');

        parent::tearDown();
    }

    public function test_parent_can_create_child_and_is_linked_automatically(): void
    {
        $response = app(ChildController::class)->store(
            $this->request(1, 'parent', $this->validPayload())
        );

        $this->assertSame(201, $response->getStatusCode());

        $childId = DB::table('children')->where('name', 'طفل ولي الأمر')->value('id');
        $this->assertNotNull($childId);
        $this->assertDatabaseHas('child_parent', [
            'child_id' => $childId,
            'parent_id' => 1,
        ]);
    }

    public function test_parent_must_supply_required_learning_fields(): void
    {
        foreach (['disability_type', 'disability_description', 'special_needs', 'strengths', 'challenges'] as $field) {
            $payload = $this->validPayload();
            $payload[$field] = in_array($field, ['strengths', 'challenges'], true) ? [] : '';

            $response = app(ChildController::class)->store($this->request(1, 'parent', $payload));

            $this->assertSame(422, $response->getStatusCode(), "{$field} should be required");
            $this->assertSame(0, DB::table('children')->count());
        }
    }

    public function test_admin_cannot_create_child(): void
    {
        $response = app(ChildController::class)->store($this->request(5, 'admin', ['name' => 'طفل الأدمن']));
        $this->assertSame(403, $response->getStatusCode());
        $this->assertDatabaseMissing('children', ['name' => 'طفل الأدمن']);
    }

    public function test_parent_must_supply_owned_identity_relationship_and_medical_documents(): void
    {
        foreach (['', '/api/private-files/user/99/id.jpg'] as $document) {
            $payload = $this->validPayload();
            $payload['name'] = 'طفل غير موثق';
            $payload['guardian_id_document_url'] = $document;
            $response = app(ChildController::class)->store($this->request(1, 'parent', $payload));
            $this->assertSame(422, $response->getStatusCode());
            $this->assertSame(0, DB::table('children')->count());
        }

        $payload = $this->validPayload();
        $payload['name'] = 'طفل دون تقرير';
        $payload['medical_report_url'] = '';
        $response = app(ChildController::class)->store($this->request(1, 'parent', $payload));
        $this->assertSame(422, $response->getStatusCode());
    }

    public function test_teacher_cannot_create_child(): void
    {
        $response = app(ChildController::class)->store(
            $this->request(2, 'teacher', ['name' => 'طفل المعلم'])
        );

        $this->assertSame(403, $response->getStatusCode());
        $this->assertDatabaseMissing('children', ['name' => 'طفل المعلم']);
    }

    public function test_specialist_cannot_create_child(): void
    {
        $response = app(ChildController::class)->store(
            $this->request(3, 'specialist', ['name' => 'طفل المختص'])
        );

        $this->assertSame(403, $response->getStatusCode());
        $this->assertDatabaseMissing('children', ['name' => 'طفل المختص']);
    }

    private function validPayload(): array
    {
        return [
            'name' => 'طفل ولي الأمر',
            'age' => 8,
            'disability_type' => 'إعاقة سمعية',
            'disability_description' => 'وصف مختصر للحالة',
            'special_needs' => 'دعم إضافي في القراءة',
            'strengths' => ['الرسم'],
            'challenges' => ['الكتابة'],
            'child_national_id' => '123456789',
            'guardian_national_id' => '987654321',
            'guardian_id_document_url' => '/api/private-files/user/1/id.jpg',
            'kinship_document_url' => '/api/private-files/user/1/kinship.pdf',
            'medical_report_url' => '/api/private-files/user/1/medical.pdf',
        ];
    }

    private function request(int $id, string $role, array $payload): Request
    {
        $request = Request::create('/api/children', 'POST', $payload);
        $request->headers->set('Accept', 'application/json');
        $request->attributes->set('jwt_user', (object) ['id' => $id, 'role' => $role]);

        return $request;
    }
}
