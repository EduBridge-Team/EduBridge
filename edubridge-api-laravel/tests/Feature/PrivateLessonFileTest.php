<?php

namespace Tests\Feature;

use App\Support\LessonFiles;
use GuzzleHttp\Psr7\Response;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\Concerns\MocksPrivateR2;

class PrivateLessonFileTest extends \Tests\TestCase
{
    use MocksPrivateR2;

    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('children', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('assigned_teacher_id')->nullable();
            $table->unsignedBigInteger('disability_type_id')->nullable();
        });

        Schema::create('child_teacher', function (Blueprint $table) {
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('teacher_id');
        });

        Schema::create('child_specialist', function (Blueprint $table) {
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('specialist_id');
        });

        Schema::create('child_parent', function (Blueprint $table) {
            $table->unsignedBigInteger('child_id');
            $table->unsignedBigInteger('parent_id');
        });

        Schema::create('lessons', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->text('content')->nullable();
            $table->unsignedBigInteger('disability_type_id')->nullable();
            $table->string('education_level')->nullable();
            $table->unsignedBigInteger('teacher_id');
            $table->string('target_type')->nullable();
            $table->text('target_child_ids')->nullable();
            $table->text('audio_description')->nullable();
            $table->string('curriculum_status')->default('pending');
            $table->timestamps();
        });

        Schema::create('media', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('lesson_id');
            $table->string('type');
            $table->text('url');
        });

        DB::table('children')->insert([
            ['id' => 10, 'assigned_teacher_id' => 1],
            ['id' => 20, 'assigned_teacher_id' => null],
        ]);

        DB::table('child_specialist')->insert([
            'child_id' => 20,
            'specialist_id' => 2,
        ]);

        DB::table('lessons')->insert([
            'id' => 100,
            'title' => 'درس قائم',
            'teacher_id' => 1,
            'target_type' => 'specificChildren',
            'target_child_ids' => json_encode([10]),
            'curriculum_status' => 'pending',
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        $this->configureR2();
        config(['services.jwt.secret' => 'test-secret']);
        Schema::create('users', function (Blueprint $table) {
            $table->id(); $table->string('role'); $table->string('password_hash'); $table->string('verification_status');
        });
        DB::table('users')->insert(['id' => 3, 'role' => 'parent', 'password_hash' => 'hash', 'verification_status' => 'verified']);
        DB::table('child_parent')->insert(['child_id' => 10, 'parent_id' => 3]);
        DB::table('media')->insert(['lesson_id' => 100, 'type' => 'video', 'url' => LessonFiles::path(100, 'video.mp4')]);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('users');
        $this->restoreR2();
        Schema::dropIfExists('media');
        Schema::dropIfExists('lessons');
        Schema::dropIfExists('child_parent');
        Schema::dropIfExists('child_specialist');
        Schema::dropIfExists('child_teacher');
        Schema::dropIfExists('children');

        parent::tearDown();
    }

    private function link(): string
    {
        $request = Request::create('https://api.example.test/api/lessons/100');
        $request->attributes->set('jwt_user', DB::table('users')->find(3));
        return LessonFiles::forViewer($request, LessonFiles::path(100, 'video.mp4'));
    }

    public function test_signed_playback_streams_ranges_from_private_bucket(): void
    {
        $this->mockR2([new Response(206, ['Content-Type' => 'video/mp4', 'Content-Length' => '3', 'Content-Range' => 'bytes 0-2/10', 'Accept-Ranges' => 'bytes'], 'abc')]);
        $response = $this->withHeaders(['Range' => 'bytes=0-2'])->get($this->link());
        $response->assertStatus(206)->assertHeader('Content-Range', 'bytes 0-2/10')->assertHeader('Content-Security-Policy', "sandbox; default-src 'none'")->assertHeader('Cache-Control');
        $this->assertStringContainsString('no-store', $response->headers->get('Cache-Control'));
        $this->assertSame('abc', $response->streamedContent());
        $this->assertSame('bytes=0-2', $this->r2History[0]['request']->getHeaderLine('Range'));
        $this->assertStringContainsString('/private/lessons/100/video.mp4', (string) $this->r2History[0]['request']->getUri());
    }

    public function test_unsigned_tampered_and_expired_links_never_reach_storage(): void
    {
        $url = $this->link();
        $this->getJson(LessonFiles::path(100, 'video.mp4'))->assertForbidden();
        $this->getJson(str_replace('viewer=3', 'viewer=4', $url))->assertForbidden();
        $this->travel(16)->minutes();
        $this->getJson($url)->assertForbidden();
        $this->travelBack();
        $this->assertCount(0, $this->r2History);
    }

    public function test_revoked_relationship_identity_role_and_password_invalidate_playback(): void
    {
        $url = $this->link();
        DB::table('child_parent')->delete();
        $this->getJson($url)->assertForbidden();
        DB::table('child_parent')->insert(['child_id' => 10, 'parent_id' => 3]);
        foreach (['verification_status' => 'rejected', 'role' => 'teacher', 'password_hash' => 'new'] as $field => $value) {
            $old = DB::table('users')->value($field);
            DB::table('users')->update([$field => $value]);
            $this->getJson($url)->assertForbidden();
            DB::table('users')->update([$field => $old]);
        }
        $this->assertCount(0, $this->r2History);
    }

    public function test_invalid_range_or_removed_media_reference_is_rejected_before_storage(): void
    {
        $url = $this->link();
        $this->withHeaders(['Range' => 'bytes=0-1,3-4'])->getJson($url)->assertStatus(416);
        DB::table('media')->delete();
        $this->getJson($url)->assertNotFound();
    }
}
