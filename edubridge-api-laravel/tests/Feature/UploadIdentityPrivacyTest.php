<?php

namespace Tests\Feature;

use App\Http\Controllers\UploadController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class UploadIdentityPrivacyTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Schema::create('children', function (Blueprint $table) {
            $table->id();
            $table->text('guardian_id_document_url')->nullable();
            $table->text('kinship_document_url')->nullable();
            $table->text('medical_report_url')->nullable();
        });
        Schema::create('child_specialist', function (Blueprint $table) {
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('specialist_id');
        });
        Schema::create('conversations', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('participant_one_id');
            $table->unsignedBigInteger('participant_two_id');
        });
        Schema::create('conversation_messages', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('conversation_id');
            $table->unsignedBigInteger('sender_id');
            $table->text('file_url')->nullable();
        });

        DB::table('children')->insert([
            'id' => 10,
            'guardian_id_document_url' => '/api/private-files/user/1/id.jpg',
            'kinship_document_url' => '/api/private-files/user/1/kinship.pdf',
            'medical_report_url' => '/api/private-files/user/1/medical.pdf',
        ]);
        DB::table('child_specialist')->insert(['child_id' => 10, 'specialist_id' => 7]);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('conversation_messages');
        Schema::dropIfExists('conversations');
        Schema::dropIfExists('child_specialist');
        Schema::dropIfExists('children');
        parent::tearDown();
    }

    public function test_assigned_specialist_cannot_open_guardian_identity_or_kinship_documents(): void
    {
        $controller = app(UploadController::class);
        $request = Request::create('/api/private-files/user/1/id.jpg', 'GET');
        $request->attributes->set('jwt_user', (object) ['id' => 7, 'role' => 'specialist']);

        $identity = $controller->show($request, 1, 'id.jpg');
        $kinship = $controller->show($request, 1, 'kinship.pdf');

        $this->assertSame(403, $identity->getStatusCode());
        $this->assertSame(403, $kinship->getStatusCode());
    }
}
