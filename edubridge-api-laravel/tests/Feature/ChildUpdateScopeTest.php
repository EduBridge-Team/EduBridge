<?php

namespace Tests\Feature;

use App\Http\Controllers\ChildController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class ChildUpdateScopeTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Schema::create('children', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->integer('age')->nullable();
        });
        Schema::create('child_parent', function (Blueprint $table) {
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('parent_id');
        });
        Schema::create('child_specialist', function (Blueprint $table) {
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('specialist_id');
        });

        DB::table('children')->insert(['id' => 10, 'name' => 'طفل', 'age' => 9]);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('child_specialist');
        Schema::dropIfExists('child_parent');
        Schema::dropIfExists('children');
        parent::tearDown();
    }

    public function test_teacher_cannot_change_child_demographic_fields(): void
    {
        $request = Request::create('/api/children/10', 'PUT', ['age' => 12]);
        $request->headers->set('Accept', 'application/json');
        $request->attributes->set('jwt_user', (object) ['id' => 2, 'role' => 'teacher']);

        $response = app(ChildController::class)->update($request, 10);

        $this->assertSame(403, $response->getStatusCode());
        $this->assertDatabaseHas('children', ['id' => 10, 'age' => 9]);
    }
}
