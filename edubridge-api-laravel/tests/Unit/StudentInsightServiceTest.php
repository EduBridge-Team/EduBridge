<?php

namespace Tests\Unit;

use App\Services\Noor\StudentInsightService;
use PHPUnit\Framework\TestCase;

class StudentInsightServiceTest extends TestCase
{
    public function test_prioritizes_homework_and_low_progress_with_reasons(): void
    {
        $actions = (new StudentInsightService())->actions([
            'signals' => [
                ['type' => 'homework_follow_up', 'message' => 'يوجد واجبان يحتاجان متابعة.'],
                ['type' => 'low_progress', 'message' => 'آخر نسبة تقدم أقل من 50%.'],
            ],
        ], 'teacher');

        $this->assertSame('follow_up_homework', $actions[0]['type']);
        $this->assertSame('high', $actions[0]['priority']);
        $this->assertNotEmpty($actions[0]['reason']);
        $this->assertSame('reinforce_recent_learning', $actions[1]['type']);
    }

    public function test_parent_gets_safe_progress_follow_up_wording(): void
    {
        $actions = (new StudentInsightService())->actions([
            'signals' => [['type' => 'missing_progress', 'message' => 'لا يوجد تقرير تقدم أسبوعي حديث.']],
        ], 'parent');

        $this->assertSame('refresh_progress', $actions[0]['type']);
        $this->assertSame('طلب تحديث عن التقدم', $actions[0]['title']);
        $this->assertStringNotContainsString('تشخيص', $actions[0]['suggested_prompt']);
    }

    public function test_returns_safe_default_when_there_are_no_signals(): void
    {
        $actions = (new StudentInsightService())->actions([], 'specialist');

        $this->assertSame('continue_plan', $actions[0]['type']);
        $this->assertSame('low', $actions[0]['priority']);
    }
}
