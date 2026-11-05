<?php

namespace Tests\Feature;

use App\Http\Controllers\JabaliaAdmissionEvidenceController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class JabaliaAdmissionEvidenceIsolationTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('local');
        config()->set('services.jabalia_admissions.upload_enabled', true);
        Schema::create('organizations', function (Blueprint $t) {
            $t->id(); $t->string('slug'); $t->boolean('is_active')->default(true);
        });
        Schema::create('schools', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id'); $t->boolean('is_active')->default(true);
        });
        Schema::create('children', fn (Blueprint $t) => $t->id());
        Schema::create('child_parent', function (Blueprint $t) {
            $t->unsignedBigInteger('child_id'); $t->unsignedBigInteger('parent_id');
        });
        Schema::create('school_management_assignments', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('user_id');
            $t->string('role'); $t->json('permissions')->nullable(); $t->timestamp('ends_at')->nullable();
        });
        Schema::create('school_enrollment_requests', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('child_id'); $t->unsignedBigInteger('school_id');
            $t->string('status'); $t->timestamps();
        });
        Schema::create('jabalia_admission_documents', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('enrollment_request_id');
            $t->unsignedBigInteger('school_id'); $t->unsignedBigInteger('child_id');
            $t->string('type'); $t->string('storage_path'); $t->string('mime_type');
            $t->unsignedBigInteger('file_size'); $t->unsignedBigInteger('uploaded_by');
            $t->timestamps();
        });
        Schema::create('jabalia_admission_evidence_access_events', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('school_id');
            $t->unsignedBigInteger('child_id'); $t->unsignedBigInteger('enrollment_request_id');
            $t->unsignedBigInteger('document_id')->nullable();
            $t->string('action'); $t->unsignedBigInteger('actor_id')->nullable();
            $t->string('actor_role'); $t->timestamp('created_at');
        });
        DB::table('organizations')->insert([
            ['id' => 1, 'slug' => 'jabalia', 'is_active' => true],
            ['id' => 2, 'slug' => 'other', 'is_active' => true],
        ]);
        DB::table('schools')->insert([
            ['id' => 1, 'organization_id' => 1, 'is_active' => true],
            ['id' => 2, 'organization_id' => 2, 'is_active' => true],
        ]);
        DB::table('children')->insert([['id' => 10], ['id' => 20]]);
        DB::table('child_parent')->insert([
            ['child_id' => 10, 'parent_id' => 40],
            ['child_id' => 20, 'parent_id' => 50],
        ]);
        DB::table('school_management_assignments')->insert([
            ['school_id' => 1, 'user_id' => 60, 'role' => 'director', 'permissions' => null],
            ['school_id' => 1, 'user_id' => 61, 'role' => 'deputy_director', 'permissions' => json_encode(['attendance'])],
            ['school_id' => 1, 'user_id' => 62, 'role' => 'deputy_director', 'permissions' => json_encode(['enrollment'])],
            ['school_id' => 2, 'user_id' => 70, 'role' => 'director', 'permissions' => null],
        ]);
        DB::table('school_enrollment_requests')->insert([
            ['id' => 100, 'child_id' => 10, 'school_id' => 1, 'status' => 'pending'],
            ['id' => 200, 'child_id' => 20, 'school_id' => 2, 'status' => 'pending'],
        ]);
    }

    protected function tearDown(): void
    {
        foreach (['jabalia_admission_evidence_access_events', 'jabalia_admission_documents', 'school_enrollment_requests',
            'school_management_assignments', 'child_parent', 'children',
            'schools', 'organizations'] as $table) Schema::dropIfExists($table);
        parent::tearDown();
    }

    private function actor(int $id, string $role, string $method = 'GET', array $payload = []): Request
    {
        $request = Request::create('/api/admission-evidence', $method, $payload);
        $request->attributes->set('jwt_user', (object) ['id' => $id, 'role' => $role]);
        return $request;
    }

    private function uploadRequest(int $id = 40, string $type = 'audiology_report'): Request
    {
        $request = Request::create('/api/admission-evidence', 'POST',
            ['type' => $type], [],
            ['file' => UploadedFile::fake()->create('hearing.pdf', 100, 'application/pdf')]);
        $request->attributes->set('jwt_user', (object) ['id' => $id, 'role' => 'parent']);
        return $request;
    }

    public function test_parent_can_upload_private_evidence_and_only_read_safe_metadata(): void
    {
        $controller = app(JabaliaAdmissionEvidenceController::class);
        $response = $controller->store($this->uploadRequest(), 10, 100);
        $this->assertSame(201, $response->getStatusCode());
        $document = $response->getData(true)['document'];
        $this->assertSame('audiology_report', $document['type']);
        $this->assertArrayNotHasKey('storage_path', $document);
        $this->assertArrayNotHasKey('original_filename', $document);

        $row = DB::table('jabalia_admission_documents')->where('id', $document['id'])->first();
        $this->assertStringStartsWith('jabalia-admission-documents/', $row->storage_path);
        Storage::disk('local')->assertExists($row->storage_path);

        $result = $controller->parentIndex($this->actor(40, 'parent'), 10, 100)->getData(true);
        $this->assertCount(1, $result['documents']);
        $this->assertFalse($result['evidence_complete']);
        $this->assertFalse($result['admissions_approved']);
        $this->assertCount(5, $result['required_types']);
    }

    public function test_foreign_parent_other_tenant_and_closed_request_cannot_upload(): void
    {
        $controller = app(JabaliaAdmissionEvidenceController::class);
        $this->assertSame(404, $controller->store($this->uploadRequest(50), 10, 100)->getStatusCode());
        $this->assertSame(404, $controller->store($this->uploadRequest(50), 20, 200)->getStatusCode());
        DB::table('school_enrollment_requests')->where('id', 100)->update(['status' => 'approved']);
        $this->assertSame(404, $controller->store($this->uploadRequest(), 10, 100)->getStatusCode());
        $this->assertDatabaseCount('jabalia_admission_documents', 0);
    }

    public function test_school_private_documents_require_director_or_explicit_enrollment_deputy(): void
    {
        $controller = app(JabaliaAdmissionEvidenceController::class);
        $this->assertSame(201, $controller->store($this->uploadRequest(), 10, 100)->status());
        $this->assertSame(200, $controller->schoolIndex($this->actor(60, 'teacher'), 100)->status());
        $this->assertSame(200, $controller->schoolIndex($this->actor(62, 'teacher'), 100)->status());
        $this->assertSame(404, $controller->schoolIndex($this->actor(61, 'teacher'), 100)->status());
        $this->assertSame(404, $controller->schoolIndex($this->actor(70, 'teacher'), 100)->status());
        $this->assertSame(404, $controller->schoolIndex($this->actor(40, 'school'), 100)->status());
        $this->assertSame(404, $controller->parentIndex($this->actor(50, 'parent'), 10, 100)->status());
    }

    public function test_known_document_from_other_enrollment_is_not_downloadable(): void
    {
        $controller = app(JabaliaAdmissionEvidenceController::class);
        $document = $controller->store($this->uploadRequest(), 10, 100)->getData(true)['document'];
        $this->assertSame(404, $controller->schoolDownload(
            $this->actor(70, 'teacher'), 200, $document['id']
        )->status());
        $this->assertSame(404, $controller->parentDownload(
            $this->actor(50, 'parent'), 20, 200, $document['id']
        )->status());
    }

    public function test_revoked_deputy_immediately_loses_evidence_access(): void
    {
        $controller = app(JabaliaAdmissionEvidenceController::class);
        $this->assertSame(201, $controller->store($this->uploadRequest(), 10, 100)->status());
        $this->assertSame(200, $controller->schoolIndex($this->actor(62, 'teacher'), 100)->status());
        DB::table('school_management_assignments')->where('user_id', 62)
            ->update(['ends_at' => now()]);
        $this->assertSame(404, $controller->schoolIndex($this->actor(62, 'teacher'), 100)->status());
    }

    public function test_all_required_document_categories_are_not_a_counselor_approval(): void
    {
        $controller = app(JabaliaAdmissionEvidenceController::class);
        foreach ([
            'audiology_report', 'birth_certificate', 'medical_report',
            'child_photo', 'father_identity',
        ] as $type) {
            $this->assertSame(201,
                $controller->store($this->uploadRequest(40, $type), 10, 100)->status());
        }
        $result = $controller->parentIndex($this->actor(40, 'parent'), 10, 100)->getData(true);
        $this->assertTrue($result['evidence_complete']);
        $this->assertFalse($result['admissions_approved']);
        $this->assertSame('pending',
            DB::table('school_enrollment_requests')->where('id', 100)->value('status'));
        $this->assertDatabaseCount('jabalia_admission_documents', 5);
    }

    public function test_evidence_listing_exposes_server_upload_gate_without_approving_admission(): void
    {
        $controller = app(JabaliaAdmissionEvidenceController::class);
        config()->set('services.jabalia_admissions.upload_enabled', false);
        $disabled = $controller->parentIndex($this->actor(40, 'parent'), 10, 100)->getData(true);
        $this->assertFalse($disabled['uploads_enabled']);
        $this->assertFalse($disabled['admissions_approved']);

        config()->set('services.jabalia_admissions.upload_enabled', true);
        $enabled = $controller->parentIndex($this->actor(40, 'parent'), 10, 100)->getData(true);
        $this->assertTrue($enabled['uploads_enabled']);
        $this->assertFalse($enabled['admissions_approved']);
    }

    public function test_upload_disabled_by_default_operational_gate(): void
    {
        config()->set('services.jabalia_admissions.upload_enabled', false);
        $controller = app(JabaliaAdmissionEvidenceController::class);
        $response = $controller->store($this->uploadRequest(), 10, 100);
        $this->assertSame(503, $response->status());
        $this->assertDatabaseCount('jabalia_admission_documents', 0);
    }


    public function test_sensitive_admission_evidence_access_events_are_scoped_and_redacted(): void
    {
        $controller = app(JabaliaAdmissionEvidenceController::class);
        $uploaded = $controller->store($this->uploadRequest(), 10, 100);
        $this->assertSame(201, $uploaded->status());
        $documentId = $uploaded->getData(true)['document']['id'];

        $this->assertSame(200, $controller->parentIndex(
            $this->actor(40, 'parent'), 10, 100
        )->status());
        $this->assertSame(200, $controller->schoolIndex(
            $this->actor(60, 'teacher'), 100
        )->status());
        $this->assertSame(200, $controller->parentDownload(
            $this->actor(40, 'parent'), 10, 100, $documentId
        )->getStatusCode());
        $this->assertSame(200, $controller->schoolDownload(
            $this->actor(62, 'teacher'), 100, $documentId
        )->getStatusCode());

        $result = $controller->schoolAccessEvents(
            $this->actor(60, 'teacher'), 100
        );
        $this->assertSame(200, $result->status());
        $events = $result->getData(true)['events']['data'];
        $this->assertCount(6, $events);
        $this->assertSame('audit_viewed', $events[0]['action']);
        $this->assertSame(2, collect($events)->where('action', 'download_issued')->count());
        $this->assertSame(1, collect($events)->where('action', 'uploaded')->count());
        foreach ($events as $entry) {
            $this->assertArrayNotHasKey('storage_path', $entry);
            $this->assertArrayNotHasKey('original_filename', $entry);
            $this->assertArrayNotHasKey('mime_type', $entry);
            $this->assertArrayNotHasKey('child_id', $entry);
        }
        $this->assertDatabaseHas('jabalia_admission_evidence_access_events', [
            'school_id' => 1, 'child_id' => 10, 'enrollment_request_id' => 100,
            'document_id' => $documentId, 'action' => 'uploaded',
            'actor_id' => 40, 'actor_role' => 'parent',
        ]);
    }

    public function test_unauthorized_attempts_or_missing_file_never_create_success_audit_events(): void
    {
        $controller = app(JabaliaAdmissionEvidenceController::class);
        $this->assertSame(404, $controller->parentIndex(
            $this->actor(50, 'parent'), 10, 100
        )->status());
        $this->assertSame(404, $controller->schoolAccessEvents(
            $this->actor(61, 'teacher'), 100
        )->status());
        $this->assertSame(404, $controller->schoolAccessEvents(
            $this->actor(70, 'teacher'), 100
        )->status());
        $this->assertSame(0, DB::table('jabalia_admission_evidence_access_events')->count());

        $response = $controller->store($this->uploadRequest(), 10, 100);
        $id = $response->getData(true)['document']['id'];
        $row = DB::table('jabalia_admission_documents')->where('id', $id)->first();
        Storage::disk('local')->delete($row->storage_path);
        $this->assertSame(404, $controller->parentDownload(
            $this->actor(40, 'parent'), 10, 100, $id
        )->status());
        $this->assertSame(1, DB::table('jabalia_admission_evidence_access_events')->count());
        $this->assertSame('uploaded', DB::table('jabalia_admission_evidence_access_events')->value('action'));
    }

    public function test_listing_fails_closed_when_access_audit_schema_not_ready(): void
    {
        Schema::dropIfExists('jabalia_admission_evidence_access_events');
        $controller = app(JabaliaAdmissionEvidenceController::class);
        $this->assertSame(503, $controller->parentIndex(
            $this->actor(40, 'parent'), 10, 100
        )->status());
        $this->assertSame(503, $controller->schoolIndex(
            $this->actor(60, 'teacher'), 100
        )->status());
    }

}
