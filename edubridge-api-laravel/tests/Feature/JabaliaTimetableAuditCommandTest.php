<?php

namespace Tests\Feature;

use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class JabaliaTimetableAuditCommandTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Schema::create('organizations', function (Blueprint $table) {
            $table->id();
            $table->string('slug');
        });
        Schema::create('schools', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('organization_id');
        });
        Schema::create('timetable_entries', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('school_id');
            $table->unsignedTinyInteger('weekday');
            $table->unsignedTinyInteger('period_number');
            $table->time('starts_at')->nullable();
            $table->time('ends_at')->nullable();
        });
        Schema::create('jabalia_school_timetable_settings', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('school_id');
            $table->json('weekdays');
            $table->json('periods');
            $table->timestamps();
        });

        DB::table('organizations')->insert([
            ['id' => 1, 'slug' => 'jabalia'],
            ['id' => 2, 'slug' => 'other'],
        ]);
        DB::table('schools')->insert([
            ['id' => 10, 'organization_id' => 1],
            ['id' => 11, 'organization_id' => 1],
            ['id' => 99, 'organization_id' => 2],
        ]);
        DB::table('jabalia_school_timetable_settings')->insert([
            'school_id' => 11,
            'weekdays' => json_encode([1]),
            'periods' => json_encode([['starts_at' => '10:00', 'ends_at' => '10:40']]),
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        DB::table('timetable_entries')->insert([
            ['school_id' => 10, 'weekday' => 7, 'period_number' => 1, 'starts_at' => '08:30:00', 'ends_at' => '09:10:00'],
            ['school_id' => 10, 'weekday' => 6, 'period_number' => 2, 'starts_at' => '09:10:00', 'ends_at' => '09:50:00'],
            ['school_id' => 10, 'weekday' => 1, 'period_number' => 9, 'starts_at' => null, 'ends_at' => null],
            ['school_id' => 11, 'weekday' => 1, 'period_number' => 1, 'starts_at' => '09:00:00', 'ends_at' => '09:40:00'],
            ['school_id' => 99, 'weekday' => 6, 'period_number' => 1, 'starts_at' => '08:30:00', 'ends_at' => '09:10:00'],
        ]);
    }

    protected function tearDown(): void
    {
        foreach (['jabalia_school_timetable_settings', 'timetable_entries', 'schools', 'organizations'] as $table) {
            Schema::dropIfExists($table);
        }
        parent::tearDown();
    }

    public function test_audit_counts_only_jabalia_entries_and_does_not_modify_any_rows(): void
    {
        $beforeEntries = DB::table('timetable_entries')->orderBy('id')->get()->toArray();
        $beforeSettings = DB::table('jabalia_school_timetable_settings')->first();

        $this->assertSame(0, Artisan::call('jabalia:audit-timetable', ['--json' => true]));
        $report = json_decode(Artisan::output(), true, 512, JSON_THROW_ON_ERROR);

        $this->assertSame('jabalia', $report['tenant']);
        $this->assertTrue($report['read_only']);
        $this->assertSame(2, $report['school_count']);
        $this->assertSame(4, $report['scheduled_entries']);
        $this->assertCount(2, $report['schools']);
        $this->assertSame(10, $report['schools'][0]['school_id']);
        $this->assertSame(3, $report['schools'][0]['scheduled_entries']);
        $this->assertSame(1, $report['schools'][0]['outside_configured_days']);
        $this->assertSame(1, $report['schools'][0]['outside_configured_periods']);
        $this->assertSame(1, $report['schools'][0]['missing_clock_times']);
        $this->assertSame(0, $report['schools'][0]['mismatched_clock_times']);
        $this->assertSame(1, $report['schools'][0]['weekday_counts'][7]);
        $this->assertSame(11, $report['schools'][1]['school_id']);
        $this->assertSame(1, $report['schools'][1]['mismatched_clock_times']);
        $this->assertSame($beforeEntries, DB::table('timetable_entries')->orderBy('id')->get()->toArray());
        $this->assertEquals($beforeSettings, DB::table('jabalia_school_timetable_settings')->first());
        $this->assertStringNotContainsString('Teacher', Artisan::output());
    }

    public function test_school_filter_rejects_cross_tenant_and_invalid_school_ids(): void
    {
        $this->assertSame(0, Artisan::call('jabalia:audit-timetable', [
            '--school-id' => '11', '--json' => true,
        ]));
        $report = json_decode(Artisan::output(), true, 512, JSON_THROW_ON_ERROR);
        $this->assertSame(1, $report['school_count']);
        $this->assertSame(11, $report['schools'][0]['school_id']);
        $this->assertSame(1, Artisan::call('jabalia:audit-timetable', ['--school-id' => '99']));
        $this->assertSame(1, Artisan::call('jabalia:audit-timetable', ['--school-id' => '../10']));
        $this->assertSame(5, DB::table('timetable_entries')->count());
    }

    public function test_missing_institution_fails_closed_without_modifying_data(): void
    {
        DB::table('organizations')->where('slug', 'jabalia')->delete();
        $this->assertSame(1, Artisan::call('jabalia:audit-timetable', ['--json' => true]));
        $this->assertSame(5, DB::table('timetable_entries')->count());
    }
}
