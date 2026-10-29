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
            $t->string('storage_path')->nullable(); $t->string('original_filename')->nullable();
            $t->timestamps();
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
        foreach (['jabalia_teacher_documents', 'organization_user', 'schools'] as $table) Schema::dropIfExists($table);
        parent::tearDown();
    }

    private function request(int $organizationId, string $slug): Request
    {
        $request = Request::create('/api/institutions/'.$slug.'/schools/1/teachers/11/documents', 'GET');
        $request->attributes->set('organization', (object) ['id' => $organizationId, 'slug' => $slug]);
        return $request;
    }

    public function test_jabalia_admin_can_list_only_own_teacher_documents(): void
    {
        $response = app(JabaliaTeacherDocumentController::class)->index($this->request(1, 'jabalia'), 'jabalia', 1, 11);
        $this->assertSame(200, $response->status());
        $this->assertCount(1, $response->getData(true)['documents']['data']);
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

    public function test_cross_tenant_document_id_cannot_be_deleted(): void
    {
        $response = app(JabaliaTeacherDocumentController::class)->destroy($this->request(1, 'jabalia'), 'jabalia', 1, 11, 999);
        $this->assertSame(404, $response->status());
        $this->assertDatabaseHas('jabalia_teacher_documents', ['id' => 1]);
    }
}
