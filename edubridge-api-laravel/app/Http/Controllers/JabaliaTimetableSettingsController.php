<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class JabaliaTimetableSettingsController extends Controller
{
    public static function defaults(): array
    {
        return ['weekdays' => [7, 1, 2, 3, 4], 'periods' => [
            ['starts_at' => '08:30', 'ends_at' => '09:10'],
            ['starts_at' => '09:10', 'ends_at' => '09:50'],
            ['starts_at' => '09:50', 'ends_at' => '10:30'],
            ['starts_at' => '10:40', 'ends_at' => '11:20'],
            ['starts_at' => '11:20', 'ends_at' => '12:00'],
        ]];
    }

    public static function forSchool(int $school): array
    {
        $record = DB::table('jabalia_school_timetable_settings')->where('school_id', $school)->first();
        return $record ? [
            'weekdays' => json_decode($record->weekdays, true),
            'periods' => json_decode($record->periods, true),
        ] : self::defaults();
    }

    private function authorized(Request $request, string $organizationSlug, int $school): bool
    {
        $org = $request->attributes->get('organization');
        return $organizationSlug === 'jabalia' && ($org->slug ?? null) === 'jabalia'
            && DB::table('schools')->where('id', $school)->where('organization_id', $org->id)->exists();
    }

    public function show(Request $request, string $organizationSlug, int $school): JsonResponse
    {
        if (!$this->authorized($request, $organizationSlug, $school))
            return response()->json(['error' => 'المدرسة غير موجودة'], 404);
        return response()->json(self::forSchool($school));
    }

    public function update(Request $request, string $organizationSlug, int $school): JsonResponse
    {
        if (!$this->authorized($request, $organizationSlug, $school))
            return response()->json(['error' => 'المدرسة غير موجودة'], 404);

        $data = $request->validate([
            'weekdays' => ['required', 'array', 'min:1', 'max:7'],
            'weekdays.*' => ['required', 'integer', 'between:1,7', 'distinct'],
            'periods' => ['required', 'array', 'min:1', 'max:10'],
            'periods.*.starts_at' => ['required', 'date_format:H:i'],
            'periods.*.ends_at' => ['required', 'date_format:H:i'],
        ]);

        $previous = null;
        foreach ($data['periods'] as $period) {
            if ($period['ends_at'] <= $period['starts_at']
                || ($previous !== null && $period['starts_at'] < $previous)) {
                return response()->json(['error' => 'أوقات الحصص غير مرتبة أو متداخلة'], 422);
            }
            $previous = $period['ends_at'];
        }

        return DB::transaction(function () use ($school, $data) {
            DB::table('schools')->where('id', $school)->lockForUpdate()->first();
            $existing = DB::table('timetable_entries')->where('school_id', $school)
                ->select('weekday', 'period_number', 'starts_at', 'ends_at')->get();
            foreach ($existing as $entry) {
                $period = $data['periods'][(int) $entry->period_number - 1] ?? null;
                if (!in_array((int) $entry->weekday, $data['weekdays'], true) || !$period
                    || $entry->starts_at !== $period['starts_at']
                    || $entry->ends_at !== $period['ends_at']) {
                    return response()->json(['error' => 'توجد حصص حالية تتعارض مع المواعيد الجديدة؛ عدّل الجدول أولًا'], 409);
                }
            }

            DB::table('jabalia_school_timetable_settings')->updateOrInsert(
                ['school_id' => $school],
                ['weekdays' => json_encode($data['weekdays']),
                 'periods' => json_encode($data['periods']),
                 'updated_at' => now()]
            );
            return response()->json(['settings' => $data]);
        });
    }
}
