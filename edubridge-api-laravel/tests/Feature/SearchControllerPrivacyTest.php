<?php

namespace Tests\Feature;

use App\Http\Controllers\SearchController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class SearchControllerPrivacyTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('email')->nullable();
            $table->string('role');
            $table->string('national_id')->nullable();
            $table->string('verification_status')->default('pending');
        });

        Schema::create('children', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('child_national_id')->nullable();
            $table->string('guardian_national_id')->nullable();
            $table->string('doc_verification_status')->default('pending');
        });

        DB::table('users')->insert([
            'id' => 1,
            'name' => 'مستخدم',
            'email' => 'private@example.com',
            'role' => 'parent',
            'national_id' => '123456789',
            'verification_status' => 'verified',
        ]);

        DB::table('children')->insert([
            'id' => 10,
            'name' => 'طفل',
            'child_national_id' => '987654321',
            'guardian_national_id' => '123456789',
            'doc_verification_status' => 'pending',
        ]);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('children');
        Schema::dropIfExists('users');

        parent::tearDown();
    }

    public function test_partial_national_id_search_is_rejected(): void
    {
        $request = Request::create('/api/search/national-id', 'GET', ['q' => '1234']);

        $response = app(SearchController::class)->byNationalId($request);

        $this->assertSame(422, $response->getStatusCode());
    }

    public function test_exact_search_masks_identifiers_and_omits_email(): void
    {
        $request = Request::create('/api/search/national-id', 'GET', ['q' => '123456789']);

        $response = app(SearchController::class)->byNationalId($request);

        $this->assertSame(200, $response->getStatusCode());

        $results = json_decode($response->getContent(), true)['results'];
        $this->assertCount(2, $results);

        $user = collect($results)->firstWhere('kind', 'user');
        $child = collect($results)->firstWhere('kind', 'child');

        $this->assertSame('•••••6789', $user['national_id']);
        $this->assertArrayNotHasKey('email', $user);

        $this->assertSame('•••••6789', $child['guardian_national_id']);
        $this->assertSame('•••••4321', $child['national_id']);
    }

    public function test_non_numeric_query_is_rejected(): void
    {
        $request = Request::create('/api/search/national-id', 'GET', ['q' => '123ABC789']);

        $response = app(SearchController::class)->byNationalId($request);

        $this->assertSame(422, $response->getStatusCode());
    }
}
