<?php

namespace Tests\Unit;

use App\Services\Noor\MemoryContextFormatter;
use PHPUnit\Framework\TestCase;

class MemoryContextFormatterTest extends TestCase
{
    public function test_only_allowlisted_kinds_are_included_and_content_is_bounded(): void
    {
        $formatter = new MemoryContextFormatter();
        $result = $formatter->format([
            (object) ['kind' => 'learning_goal', 'content' => "تعلم الجمع\nبدون حمل"],
            (object) ['kind' => 'diagnosis', 'content' => 'hidden medical information'],
            (object) ['kind' => 'learning_preference', 'content' => str_repeat('أ', 400)],
        ]);
        $this->assertStringContainsString('learning_goal: تعلم الجمع بدون حمل', $result);
        $this->assertStringNotContainsString('hidden medical information', $result);
        $this->assertLessThan(800, mb_strlen($result));
        $this->assertStringContainsString('بيانات غير موثوقة', $result);
    }

    public function test_empty_memories_do_not_add_prompt_content(): void
    {
        $this->assertSame('', (new MemoryContextFormatter())->format([]));
    }
}
