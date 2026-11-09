<?php

namespace Tests\Feature;

use App\Http\Controllers\JabaliaTeacherDocumentController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class JabaliaTeacherDocumentIsolationTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('schools', function (Blueprint $t) { $t->id(); $t->unsignedBigInteger('organization_id'); });
        Schema::create('organization_user', function (Blueprint $t) {
            $t->unsignedBigInteger('organization_id'); $t->unsignedBigInteger('user_id'); $t->string('role');
        });
        Schema::create('jabalia_teacher_documents', function (Blueprint $t) {
            $t->id(); $t->unsignedBigInteger('organization_id'); $t->unsignedBigInteger('school_id');
            $t->unsignedBigInteger('teacher_id'); $t->string('type'); $t->string('title');
            $t->string('issuer')->nullable(); $t->date('issued_on')->nullable();
            $t->date('expires_on')->nullable(); $t->text('notes')->nullable();
            $t->unsignedBigInteger('recorded_by')->nullable();
            $t->string('storage_path')->nullable(); $t->string('original_filename')->nullable();
            $t->timestamps();
        });
        Schema::create('jabalia_teacher_document_access_events', function (Blueprint $t) {
            $t->id();
            $t->unsignedBigInteger('organization_id');
            $t->unsignedBigInteger('school_id');
            $t->unsignedBigInteger('teacher_id');
            $t->unsignedBigInteger('document_id')->nullable();
            $t->string('action');
            $t->unsignedBigInteger('actor_id')->nullable();
            $t->timestamp('created_at');
        });
        DB::table('schools')->insert([['id' => 1, 'organization_id' => 1], ['id' => 2, 'organization_id' => 2]]);
        DB::table('organization_user')->insert([['organization_id' => 1, 'user_id' => 11, 'role' => 'teacher'],
            ['organization_id' => 2, 'user_id' => 22, 'role' => 'teacher']]);
        DB::table('jabalia_teacher_documents')->insert([
            ['id' => 1, 'organization_id' => 1, 'school_id' => 1, 'teacher_id' => 11, 'type' => 'contract', 'title' => 'Contract A'],
        ]);
    }

    protected function tearDown(): void
    {
        foreach (['jabalia_teacher_document_access_events', 'jabalia_teacher_documents', 'organization_user', 'schools'] as $table) Schema::dropIfExists($table);
        parent::tearDown();
    }

    private function request(int $organizationId, string $slug): Request
    {
        $request = Request::create('/api/institutions/'.$slug.'/schools/1/teachers/11/documents', 'GET');
        $request->attributes->set('organization', (object) ['id' => $organizationId, 'slug' => $slug]);
        $request->attributes->set('jwt_user', (object) ['id' => 99, 'role' => 'institution']);
        return $request;
    }

    public function test_each_approved_teacher_document_category_can_be_stored_with_private_metadata(): void
    {
        $types = [
            'contract', 'university_degree', 'cv', 'experience_certificate',
            'identity_document', 'achievement', 'certificate',
        ];
        $controller = app(JabaliaTeacherDocumentController::class);

        foreach ($types as $type) {
            $request = $this->request(1, 'jabalia');
            $request->replace([
                'type' => $type,
                'title' => 'Jabalia '.$type,
                'notes' => 'Private personnel record',
            ]);
            $response = $controller->store($request, 'jabalia', 1, 11);
            $this->assertSame(201, $response->status(), $type);
            $record = $response->getData(true)['document'];
            $this->assertSame($type, $record['type']);
            $this->assertSame(1, $record['organization_id']);
            $this->assertSame(1, $record['school_id']);
            $this->assertSame(11, $record['teacher_id']);
            $this->assertSame(0, $record['has_file']);
            $this->assertArrayNotHasKey('storage_path', $record);
            $this->assertArrayNotHasKey('original_filename', $record);
        }

        $this->assertSame(count($types) + 1, DB::table('jabalia_teacher_documents')->count());
    }

    public function test_unrecognized_document_category_is_rejected_before_insert(): void
    {
        $request = $this->request(1, 'jabalia');
        $request->replace(['type' => 'medical_record', 'title' => 'Unsupported']);
        try {
            app(JabaliaTeacherDocumentController::class)->store($request, 'jabalia', 1, 11);
            $this->fail('Unexpected document type was accepted');
        } catch (\Illuminate\Validation\ValidationException $exception) {
            $this->assertArrayHasKey('type', $exception->errors());
        }
        $this->assertSame(1, DB::table('jabalia_teacher_documents')->count());
    }

    public function test_new_document_type_is_not_readable_from_another_school_or_tenant(): void
    {
        $request = $this->request(1, 'jabalia');
        $request->replace(['type' => 'identity_document', 'title' => 'Private identity']);
        $document = app(JabaliaTeacherDocumentController::class)
            ->store($request, 'jabalia', 1, 11)->getData(true)['document'];
        $id = $document['id'];

        $controller = app(JabaliaTeacherDocumentController::class);
        $this->assertSame(404, $controller->download($this->request(2, 'other'), 'other', 1, 11, $id)->status());
        $this->assertSame(404, $controller->download($this->request(1, 'jabalia'), 'jabalia', 2, 11, $id)->status());
        $this->assertSame(404, $controller->download($this->request(1, 'jabalia'), 'jabalia', 1, 22, $id)->status());
        $this->assertDatabaseHas('jabalia_teacher_documents', [
            'id' => $id, 'type' => 'identity_document', 'organization_id' => 1,
        ]);
    }

    public function test_jabalia_admin_can_list_only_own_teacher_documents(): void
    {
        $response = app(JabaliaTeacherDocumentController::class)->index($this->request(1, 'jabalia'), 'jabalia', 1, 11);
        $this->assertSame(200, $response->status());
        $this->assertCount(1, $response->getData(true)['documents']['data']);
    }

    public function test_list_returns_only_attachment_flag_without_private_paths_or_original_filename(): void
    {
        $confidentialPath = 'jabalia-teacher-documents/private-personnel-id-file.pdf';
        DB::table('jabalia_teacher_documents')->where('id', 1)->update([
            'storage_path' => $confidentialPath,
            'original_filename' => 'teacher-national-identity.pdf',
        ]);
        $response = app(JabaliaTeacherDocumentController::class)
            ->index($this->request(1, 'jabalia'), 'jabalia', 1, 11);
        $this->assertSame(200, $response->status());
        $entry = $response->getData(true)['documents']['data'][0];
        $this->assertSame(1, $entry['has_file']);
        foreach (['storage_path', 'original_filename', 'mime_type', 'file_size'] as $sensitiveKey) {
            $this->assertArrayNotHasKey($sensitiveKey, $entry);
        }
        $encoded = $response->getContent();
        $this->assertStringNotContainsString($confidentialPath, $encoded);
        $this->assertStringNotContainsString('teacher-national-identity.pdf', $encoded);
        $this->assertDatabaseHas('jabalia_teacher_document_access_events', [
            'action' => 'listed', 'document_id' => null, 'actor_id' => 99,
        ]);
    }

    public function test_other_organization_cannot_list_jabalia_documents(): void
    {
        $response = app(JabaliaTeacherDocumentController::class)->index($this->request(2, 'other'), 'other', 1, 11);
        $this->assertSame(404, $response->status());
    }

    public function test_wrong_school_or_teacher_cannot_download_or_upload(): void
    {
        $controller = app(JabaliaTeacherDocumentController::class);
        $request = $this->request(1, 'jabalia');
        $this->assertSame(404, $controller->download($request, 'jabalia', 2, 11, 1)->status());
        $this->assertSame(404, $controller->upload($request, 'jabalia', 1, 22, 1)->status());
        $this->assertSame(404, $controller->download($request, 'jabalia', 1, 11, 999)->status());
    }

    public function test_signed_contract_file_survives_deletion_attempt(): void
    {
        \Illuminate\Support\Facades\Storage::fake('local');
        $path = 'jabalia-teacher-documents/signed-v1.pdf';
        \Illuminate\Support\Facades\Storage::disk('local')->put($path, "%PDF-1.4\n%%EOF");
        DB::table('jabalia_teacher_documents')->insert([
            'id' => 2, 'organization_id' => 1, 'school_id' => 1,
            'teacher_id' => 11, 'type' => 'contract', 'title' => 'Signed project contract',
            'storage_path' => $path, 'original_filename' => 'signed-v1.pdf',
        ]);

        $response = app(JabaliaTeacherDocumentController::class)
            ->destroy($this->request(1, 'jabalia'), 'jabalia', 1, 11, 2);

        $this->assertSame(409, $response->status());
        $this->assertDatabaseHas('jabalia_teacher_documents', [
            'id' => 2, 'type' => 'contract', 'storage_path' => $path,
        ]);
        \Illuminate\Support\Facades\Storage::disk('local')->assertExists($path);
    }

    public function test_uploaded_contract_cannot_be_overwritten_and_new_contract_entry_is_allowed(): void
    {
        \Illuminate\Support\Facades\Storage::fake('local');
        $path = 'jabalia-teacher-documents/signed-v1.pdf';
        \Illuminate\Support\Facades\Storage::disk('local')->put($path, "%PDF-1.4\n%%EOF");
        DB::table('jabalia_teacher_documents')->insert([
            'id' => 2, 'organization_id' => 1, 'school_id' => 1,
            'teacher_id' => 11, 'type' => 'contract', 'title' => 'Signed project contract',
            'storage_path' => $path, 'original_filename' => 'signed-v1.pdf',
        ]);

        $request = $this->request(1, 'jabalia');
        $request->files->set('file', \Illuminate\Http\UploadedFile::fake()
            ->createWithContent('replacement.pdf', "%PDF-1.4\n1 0 obj\n<< /Type /Catalog >>\nendobj\n%%EOF"));

        $result = app(JabaliaTeacherDocumentController::class)
            ->upload($request, 'jabalia', 1, 11, 2);
        $this->assertSame(409, $result->status());
        $this->assertDatabaseHas('jabalia_teacher_documents', [
            'id' => 2, 'storage_path' => $path, 'original_filename' => 'signed-v1.pdf',
        ]);
        \Illuminate\Support\Facades\Storage::disk('local')->assertExists($path);

        $new = $this->request(1, 'jabalia');
        $new->replace(['type' => 'contract', 'title' => 'Renewed project contract']);
        $response = app(JabaliaTeacherDocumentController::class)
            ->store($new, 'jabalia', 1, 11);
        $this->assertSame(201, $response->status());
        $this->assertNotSame(2, $response->getData(true)['document']['id']);
        $this->assertSame(99, $response->getData(true)['document']['recorded_by']);
        $this->assertSame(3, DB::table('jabalia_teacher_documents')->count());
    }

    public function test_cross_tenant_document_id_cannot_be_deleted(): void
    {
        $response = app(JabaliaTeacherDocumentController::class)->destroy($this->request(1, 'jabalia'), 'jabalia', 1, 11, 999);
        $this->assertSame(404, $response->status());
        $this->assertDatabaseHas('jabalia_teacher_documents', ['id' => 1]);
    }

    public function test_private_download_creates_a_scoped_audit_event_without_file_path(): void
    {
        \Illuminate\Support\Facades\Storage::fake('local');
        $path = 'jabalia-teacher-documents/private-test.pdf';
        \Illuminate\Support\Facades\Storage::disk('local')->put($path, "%PDF-1.4\n%%EOF");
        DB::table('jabalia_teacher_documents')->where('id', 1)->update([
            'storage_path' => $path, 'original_filename' => 'private-test.pdf',
        ]);

        $controller = app(JabaliaTeacherDocumentController::class);
        $result = $controller->download($this->request(1, 'jabalia'), 'jabalia', 1, 11, 1);
        $this->assertSame(200, $result->getStatusCode());
        $this->assertDatabaseHas('jabalia_teacher_document_access_events', [
            'organization_id' => 1, 'school_id' => 1, 'teacher_id' => 11,
            'document_id' => 1, 'action' => 'download_issued', 'actor_id' => 99,
        ]);
        $events = $controller->accessEvents($this->request(1, 'jabalia'), 'jabalia', 1, 11)
            ->getData(true)['events']['data'];
        $this->assertCount(2, $events);
        $this->assertSame('audit_viewed', $events[0]['action']);
        $this->assertArrayNotHasKey('storage_path', $events[1]);
        $this->assertArrayNotHasKey('original_filename', $events[1]);
    }

    public function test_document_listing_is_audited_and_denied_roles_are_not_logged_as_success(): void
    {
        $controller = app(JabaliaTeacherDocumentController::class);
        $this->assertSame(200, $controller->index(
            $this->request(1, 'jabalia'), 'jabalia', 1, 11
        )->status());
        $this->assertDatabaseHas('jabalia_teacher_document_access_events', [
            'action' => 'listed', 'document_id' => null, 'actor_id' => 99,
        ]);

        $wrongRole = $this->request(1, 'jabalia');
        $wrongRole->attributes->set('jwt_user', (object)['id' => 100, 'role' => 'parent']);
        $this->assertSame(404, $controller->index($wrongRole, 'jabalia', 1, 11)->status());
        $this->assertSame(404, $controller->accessEvents($wrongRole, 'jabalia', 1, 11)->status());
        $this->assertSame(404, $controller->accessEvents(
            $this->request(2, 'other'), 'other', 1, 11
        )->status());
        $this->assertSame(1, DB::table('jabalia_teacher_document_access_events')->count());
    }

    public function test_missing_file_is_not_recorded_as_issued_download(): void
    {
        $controller = app(JabaliaTeacherDocumentController::class);
        $this->assertSame(404, $controller->download(
            $this->request(1, 'jabalia'), 'jabalia', 1, 11, 1
        )->status());
        $this->assertSame(0, DB::table('jabalia_teacher_document_access_events')->count());
    }

    public function test_recovered_synthetic_teacher_file_download_is_byte_exact_and_other_roles_denied(): void
    {
        // Simulate recovery only on the testing-local fake disk; never touch
        // real teacher documents, a live volume, or a production database.
        \Illuminate\Support\Facades\Storage::fake('local');
        $path = 'jabalia-teacher-documents/synthetic-recovered-teacher.pdf';
        $payload = "%PDF-1.4\nSynthetic recovered teacher fixture only.\n%%EOF\n";
        \Illuminate\Support\Facades\Storage::disk('local')->put($path, $payload);
        DB::table('jabalia_teacher_documents')->where('id', 1)->update([
            'storage_path' => $path, 'original_filename' => 'synthetic-recovered-teacher.pdf',
        ]);

        $controller = app(JabaliaTeacherDocumentController::class);
        $allowed = $controller->download($this->request(1, 'jabalia'), 'jabalia', 1, 11, 1);
        $this->assertSame(200, $allowed->getStatusCode());
        $this->assertInstanceOf(\Symfony\Component\HttpFoundation\StreamedResponse::class, $allowed);
        $this->assertStringContainsString('no-store', (string) $allowed->headers->get('Cache-Control'));
        ob_start();
        try {
            $allowed->sendContent();
            $downloaded = ob_get_clean();
        } catch (\Throwable $exception) {
            ob_end_clean();
            throw $exception;
        }
        $this->assertSame(hash('sha256', $payload), hash('sha256', $downloaded));
        $this->assertSame($payload, $downloaded);

        $wrongRole = $this->request(1, 'jabalia');
        $wrongRole->attributes->set('jwt_user', (object) ['id' => 100, 'role' => 'parent']);
        $this->assertSame(404, $controller->download($wrongRole, 'jabalia', 1, 11, 1)->status());
        $this->assertSame(404, $controller->download($this->request(2, 'other'), 'other', 1, 11, 1)->status());
        $this->assertSame(404, $controller->download($this->request(1, 'jabalia'), 'jabalia', 2, 11, 1)->status());
        $this->assertSame(1, DB::table('jabalia_teacher_document_access_events')
            ->where('action', 'download_issued')->count());
    }

}
