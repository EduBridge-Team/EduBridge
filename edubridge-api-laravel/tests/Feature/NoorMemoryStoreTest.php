<?php

namespace Tests\Feature;

use App\Services\Noor\MemoryStore;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\ValidationException;
use Tests\TestCase;

class NoorMemoryStoreTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('noor_memory_preferences', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->unsignedBigInteger('child_id');
            $table->boolean('enabled')->default(false);
            $table->timestamp('consented_at')->nullable();
            $table->timestamps();
            $table->unique(['user_id', 'child_id']);
        });
        Schema::create('noor_memories', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->unsignedBigInteger('child_id');
            $table->string('kind');
            $table->text('content');
            $table->timestamp('expires_at')->nullable();
            $table->timestamps();
        });
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('noor_memories');
        Schema::dropIfExists('noor_memory_preferences');
        parent::tearDown();
    }

    public function test_memory_is_opt_in_and_scoped_to_user_and_student(): void
    {
        $store = app(MemoryStore::class);
        $this->assertSame([], $store->list(1, 10));
        try {
            $store->remember(1, 10, 'learning_goal', 'قراءة الكلمات');
            $this->fail('Expected validation error');
        } catch (ValidationException $expected) {
            $this->assertNotEmpty($expected->errors());
        }
        $store->setEnabled(1, 10, true);
        $id = $store->remember(1, 10, 'learning_goal', 'قراءة الكلمات');
        $this->assertCount(1, $store->list(1, 10));
        $this->assertSame([], $store->list(2, 10));
        $this->assertSame([], $store->list(1, 11));
        $this->assertFalse($store->delete(2, 10, $id));
        $this->assertFalse($store->delete(1, 11, $id));
        $store->setEnabled(1, 10, false);
        $this->assertSame([], $store->list(1, 10));
        $this->assertSame(0, \Illuminate\Support\Facades\DB::table('noor_memories')->count());
    }

    public function test_rejects_unsupported_kinds_and_retention(): void
    {
        $store = app(MemoryStore::class);
        $store->setEnabled(1, 10, true);
        $this->expectException(ValidationException::class);
        $store->remember(1, 10, 'diagnosis', 'معلومات طبية');
    }
}
