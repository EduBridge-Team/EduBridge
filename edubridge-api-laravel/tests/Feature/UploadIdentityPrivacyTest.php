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

    public function test_assigned_specialist_can_pass_document_authorization_but_unassigned_specialist_cannot(): void
    {
        $controller = app(UploadController::class);

        $assignedRequest = Request::create('/api/private-files/user/1/id.jpg', 'GET');
        $assignedRequest->attributes->set('jwt_user', (object) ['id' => 7, 'role' => 'specialist']);

        $identity = $controller->show($assignedRequest, 1, 'id.jpg');
        $kinship = $controller->show($assignedRequest, 1, 'kinship.pdf');
        $medical = $controller->show($assignedRequest, 1, 'medical.pdf');

        // The test environment does not configure R2, so an authorized request may end in
        // storage-layer 500. What matters here is that assigned specialists are not rejected
        // by the authorization gate before streaming is attempted.
        $this->assertNotSame(403, $identity->getStatusCode());
        $this->assertNotSame(403, $kinship->getStatusCode());
        $this->assertNotSame(403, $medical->getStatusCode());

        $unassignedRequest = Request::create('/api/private-files/user/1/id.jpg', 'GET');
        $unassignedRequest->attributes->set('jwt_user', (object) ['id' => 8, 'role' => 'specialist']);

        $this->assertSame(403, $controller->show($unassignedRequest, 1, 'id.jpg')->getStatusCode());
        $this->assertSame(403, $controller->show($unassignedRequest, 1, 'kinship.pdf')->getStatusCode());
        $this->assertSame(403, $controller->show($unassignedRequest, 1, 'medical.pdf')->getStatusCode());
    }
}
