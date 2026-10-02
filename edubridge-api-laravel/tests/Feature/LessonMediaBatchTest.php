<?php

namespace Tests\Feature;

use App\Http\Controllers\Concerns\ChildLessonHelpers;
use App\Http\Controllers\Concerns\LessonSerializationHelpers;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class LessonMediaBatchTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('media', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('lesson_id');
            $table->string('type');
            $table->string('url');
        });
        DB::table('media')->insert([
            ['id' => 1, 'lesson_id' => 1, 'type' => 'video', 'url' => 'https://example.com/video.mp4'],
            ['id' => 2, 'lesson_id' => 1, 'type' => 'image', 'url' => 'https://example.com/image.png'],
            ['id' => 3, 'lesson_id' => 3, 'type' => 'audio', 'url' => 'https://example.com/audio.mp3'],
        ]);
    }

    protected function tearDown(): void
    {
        DB::disableQueryLog();
        Schema::dropIfExists('media');
        parent::tearDown();
    }

    public function test_lesson_lists_use_one_media_query_and_preserve_empty_and_ordered_media(): void
    {
        $serializers = [
            new class {
                use LessonSerializationHelpers;
                public function batch(Request $request, Collection $lessons): Collection
                {
                    return $this->serializeLessons($request, $lessons);
                }
            },
            new class {
                use ChildLessonHelpers;
                public function batch(Request $request, Collection $lessons): Collection
                {
                    $media = $this->loadLessonMedia($lessons);
                    return $lessons->map(fn ($lesson) => $this->serializeChildLesson($request, $lesson, $media->get($lesson->id, collect())));
                }
            },
        ];
        $request = Request::create('/api/lessons');
        DB::enableQueryLog();
        foreach ($serializers as $serializer) {
            foreach ([1, 30] as $size) {
                $lessons = collect(range(1, $size))->map(fn ($id) => (object) ['id' => $id, 'target_child_ids' => '[10]']);
                DB::flushQueryLog();
                $result = $serializer->batch($request, $lessons)->all();
                $this->assertCount(1, DB::getQueryLog());
                $this->assertCount($size, $result);
                $this->assertSame([1, 2], array_column($result[0]['media'], 'id'));
                $this->assertSame([10], $result[0]['target_child_ids']);
                $this->assertSame('https://example.com/video.mp4', $result[0]['video_url']);
                if ($size > 1) {
                    $this->assertSame([], $result[1]['media']);
                    $this->assertNull($result[1]['video_url']);
                    $this->assertSame('https://example.com/audio.mp3', $result[2]['audio_url']);
                }
            }
            DB::flushQueryLog();
            $this->assertSame([], $serializer->batch($request, collect())->all());
            $this->assertCount(0, DB::getQueryLog());
        }
    }
}
