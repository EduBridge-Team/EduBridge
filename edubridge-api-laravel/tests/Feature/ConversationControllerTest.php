<?php

namespace Tests\Feature;

use App\Http\Controllers\ConversationController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class ConversationControllerTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('email');
            $table->string('role');
        });
        Schema::create('notifications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id');
            $table->string('title')->nullable();
            $table->string('message');
            $table->string('type')->nullable();
            $table->boolean('is_read')->default(false);
            $table->timestamp('created_at')->useCurrent();
        });
        Schema::create('conversations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('participant_one_id');
            $table->foreignId('participant_two_id');
            $table->foreignId('created_by_id')->nullable();
            $table->string('subject')->nullable();
            $table->timestamps();
            $table->unique(['participant_one_id', 'participant_two_id']);
        });
        Schema::create('conversation_messages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('conversation_id');
            $table->foreignId('sender_id');
            $table->text('content')->nullable();
            $table->string('file_url', 2048)->nullable();
            $table->timestamp('created_at');
        });

        DB::table('users')->insert([
            ['id' => 1, 'name' => 'ولي الأمر', 'email' => 'parent@example.com', 'role' => 'parent'],
            ['id' => 2, 'name' => 'المعلّم', 'email' => 'teacher@example.com', 'role' => 'teacher'],
            ['id' => 3, 'name' => 'ولي آخر', 'email' => 'other@example.com', 'role' => 'parent'],
        ]);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('conversation_messages');
        Schema::dropIfExists('conversations');
        Schema::dropIfExists('notifications');
        Schema::dropIfExists('users');
        parent::tearDown();
    }

    public function test_participants_can_exchange_messages_but_other_users_cannot_read_them(): void
    {
        $controller = app(ConversationController::class);
        $create = $this->request('POST', ['other_user_id' => 2, 'subject' => 'متابعة الطفل'], 1, 'parent');
        $created = $controller->store($create);

        $this->assertSame(201, $created->getStatusCode());
        $conversationId = json_decode($created->getContent(), true)['conversation']['id'];

        $send = $this->request('POST', ['content' => 'مرحباً، أريد متابعة الخطة.'], 1, 'parent');
        $sent = $controller->send($send, $conversationId);
        $this->assertSame(201, $sent->getStatusCode());

        $teacherMessages = $controller->messages($this->request('GET', [], 2, 'teacher'), $conversationId);
        $payload = json_decode($teacherMessages->getContent(), true);
        $this->assertSame(200, $teacherMessages->getStatusCode());
        $this->assertFalse($payload['messages'][0]['is_mine']);
        $this->assertSame('مرحباً، أريد متابعة الخطة.', $payload['messages'][0]['content']);

        $outsider = $controller->messages($this->request('GET', [], 3, 'parent'), $conversationId);
        $this->assertSame(404, $outsider->getStatusCode());

        $list = $controller->index($this->request('GET', [], 2, 'teacher'));
        $conversation = json_decode($list->getContent(), true)['conversations'][0];
        $this->assertSame('ولي الأمر', $conversation['other_user_name']);
        $this->assertSame('مرحباً، أريد متابعة الخطة.', $conversation['last_message']);
    }

    public function test_parent_cannot_start_a_conversation_with_another_parent(): void
    {
        $response = app(ConversationController::class)->store(
            $this->request('POST', ['other_user_id' => 3], 1, 'parent')
        );

        $this->assertSame(403, $response->getStatusCode());
    }

    private function request(string $method, array $payload, int $id, string $role): Request
    {
        $request = Request::create('/api/conversations', $method, $payload);
        $request->headers->set('Accept', 'application/json');
        $request->attributes->set('jwt_user', (object) ['id' => $id, 'role' => $role]);
        return $request;
    }
}
