<?php

namespace Tests\Feature;

use App\Http\Controllers\VerificationController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class VerificationReviewScopeTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            foreach (['name', 'email', 'role', 'phone', 'national_id', 'id_document_url', 'verification_status', 'verification_note'] as $field) {
                $table->string($field)->nullable();
            }
            $table->timestamp('verified_at')->nullable();
            $table->timestamps();
        });
        foreach ([['parent', '/identity/parent'], ['teacher', null], ['specialist', ''], ['teacher', '/identity/teacher'], ['specialist', '/identity/specialist']] as $index => [$role, $document]) {
            DB::table('users')->insert(['id' => $index + 1, 'role' => $role, 'id_document_url' => $document, 'verification_status' => 'pending']);
        }
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('users');
        parent::tearDown();
    }

    public function test_review_queue_excludes_parents_and_missing_documents(): void
    {
        $response = app(VerificationController::class)->users(Request::create('/api/verifications/users', 'GET', ['status' => 'pending']));
        $this->assertSame(200, $response->getStatusCode());
        $ids = array_column(json_decode($response->getContent(), true)['users'], 'id');
        sort($ids);
        $this->assertSame([4, 5], $ids);
    }

    public function test_direct_review_cannot_approve_parent_or_undocumented_account(): void
    {
        foreach ([1, 2, 3] as $id) {
            $response = app(VerificationController::class)->reviewUser(Request::create('/review', 'PATCH', ['status' => 'verified']), $id);
            $this->assertSame(422, $response->getStatusCode());
            $this->assertDatabaseHas('users', ['id' => $id, 'verification_status' => 'pending']);
        }
    }
}
