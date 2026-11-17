<?php

namespace App\Console\Commands;

use App\Http\Controllers\JabaliaTimetableSettingsController;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class AuditJabaliaTimetable extends Command
{
    protected $signature = 'jabalia:audit-timetable
        {--school-id= : Restrict to one Jabalia school ID}
        {--json : Emit a machine-readable, aggregate-only report}';

    protected $description = 'Read-only Jabalia timetable settings audit; never changes existing lessons';

    public function handle(): int
    {
        foreach (['organizations', 'schools', 'timetable_entries'] as $table) {
            if (!Schema::hasTable($table)) {
                $this->error("Missing required table: {$table}");
                return self::FAILURE;
            }
        }

        $schoolOption = $this->option('school-id');
        if ($schoolOption !== null && (!ctype_digit((string) $schoolOption) || (int) $schoolOption < 1)) {
            $this->error('--school-id must be a positive integer');
            return self::FAILURE;
        }

        $organizationId = DB::table('organizations')->where('slug', 'jabalia')->value('id');
        if ($organizationId === null) {
            $this->error('Jabalia institution was not found; no data was scanned');
            return self::FAILURE;
        }

        $schoolIds = DB::table('schools')
            ->where('organization_id', $organizationId)
            ->when($schoolOption !== null, fn ($query) => $query->where('id', (int) $schoolOption))
            ->orderBy('id')
            ->pluck('id')
            ->map(fn ($id) => (int) $id)
            ->all();

        if ($schoolOption !== null && !$schoolIds) {
            $this->error('School does not belong to Jabalia; no data was scanned');
            return self::FAILURE;
        }

        $summary = [];
        foreach ($schoolIds as $schoolId) {
            $settings = JabaliaTimetableSettingsController::forSchool($schoolId);
            if (!is_array($settings['weekdays'] ?? null) || !is_array($settings['periods'] ?? null)) {
                $this->error("Invalid timetable settings for school {$schoolId}");
                return self::FAILURE;
            }

            $summary[$schoolId] = [
                'school_id' => $schoolId,
                'configured_weekdays' => array_values(array_map('intval', $settings['weekdays'])),
                'configured_periods' => count($settings['periods']),
                'scheduled_entries' => 0,
                'weekday_counts' => array_fill_keys([1, 2, 3, 4, 5, 6, 7], 0),
                'outside_configured_days' => 0,
                'outside_configured_periods' => 0,
                'missing_clock_times' => 0,
                'mismatched_clock_times' => 0,
            ];
            $summary[$schoolId]['periods'] = $settings['periods'];
        }

        if ($schoolIds) {
            // Cursor and aggregated counts avoid loading teachers, students or lesson names.
            foreach (DB::table('timetable_entries')
                ->whereIn('school_id', $schoolIds)
                ->select('school_id', 'weekday', 'period_number', 'starts_at', 'ends_at')
                ->orderBy('school_id')
                ->cursor() as $entry) {
                $schoolId = (int) $entry->school_id;
                $day = (int) $entry->weekday;
                $periodNumber = (int) $entry->period_number;
                $result = &$summary[$schoolId];
                $result['scheduled_entries']++;

                if (array_key_exists($day, $result['weekday_counts'])) {
                    $result['weekday_counts'][$day]++;
                }
                if (!in_array($day, $result['configured_weekdays'], true)) {
                    $result['outside_configured_days']++;
                }
                $configuredSlot = $result['periods'][$periodNumber - 1] ?? null;
                if ($periodNumber < 1 || $configuredSlot === null) {
                    $result['outside_configured_periods']++;
                }

                if ($entry->starts_at === null || $entry->ends_at === null) {
                    $result['missing_clock_times']++;
                } elseif ($configuredSlot !== null && (
                    substr((string) $entry->starts_at, 0, 5) !== ($configuredSlot['starts_at'] ?? null)
                    || substr((string) $entry->ends_at, 0, 5) !== ($configuredSlot['ends_at'] ?? null)
                )) {
                    $result['mismatched_clock_times']++;
                }
                unset($result);
            }
        }

        foreach ($summary as &$result) {
            unset($result['periods']); // Do not include raw settings or identifying timetable rows.
        }
        unset($result);

        $schools = array_values($summary);
        $payload = [
            'tenant' => 'jabalia',
            'read_only' => true,
            'school_count' => count($schoolIds),
            'scheduled_entries' => array_sum(array_column($schools, 'scheduled_entries')),
            'schools' => $schools,
            'note' => 'Counts do not prove historic author intent; never shift weekday values automatically.',
        ];

        if ($this->option('json')) {
            $this->line(json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT));
        } else {
            $this->info('Jabalia timetable audit (read-only). No rows changed.');
            $this->table(
                ['School ID', 'Lessons', 'Unconfigured days', 'Unconfigured periods', 'Missing times', 'Time mismatch'],
                array_map(fn ($school) => [
                    $school['school_id'], $school['scheduled_entries'],
                    $school['outside_configured_days'], $school['outside_configured_periods'],
                    $school['missing_clock_times'], $school['mismatched_clock_times'],
                ], $schools)
            );
            $this->warn($payload['note']);
        }

        return self::SUCCESS;
    }
}
