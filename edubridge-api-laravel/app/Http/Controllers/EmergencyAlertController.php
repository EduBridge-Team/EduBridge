<?php

namespace App\Http\Controllers;

use App\Support\ChildAccess;
use App\Support\Notify;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class EmergencyAlertController extends Controller
{
    public function index(Request $request, $childId)
    {
        $me = $request->attributes->get('jwt_user');
        $childId = (int) $childId;

        if (!ChildAccess::allowed($me, $childId)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        return response()->json([
            'alerts' => DB::table('emergency_alerts')
                ->where('child_id', $childId)
                ->orderByDesc('created_at')
                ->limit(100)
                ->get(),
        ]);
    }

    public function store(Request $request, $childId)
    {
        $me = $request->attributes->get('jwt_user');
        $childId = (int) $childId;

        if (!ChildAccess::allowed($me, $childId)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        $child = DB::table('children')->where('id', $childId)->first(['id', 'name']);
        if (!$child) {
            return response()->json(['error' => 'الطفل غير موجود'], 404);
        }

        $message = trim((string) $request->input('message', ''));
        if ($message === '') {
            $message = 'تم تفعيل زر الطوارئ للطفل ' . $child->name . '. يُرجى التواصل فوراً.';
        }

        $source = trim((string) $request->input('source', 'app'));
        if (!in_array($source, ['app', 'web'], true)) {
            $source = 'app';
        }

        $id = DB::table('emergency_alerts')->insertGetId([
            'child_id' => $childId,
            'triggered_by' => $me->id,
            'status' => 'active',
            'message' => $message,
            'source' => $source,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $recipientIds = collect()
            ->merge(DB::table('child_parent')->where('child_id', $childId)->pluck('parent_id'))
            ->merge(DB::table('child_specialist')->where('child_id', $childId)->pluck('specialist_id'))
            ->filter(fn ($id) => (int) $id !== (int) $me->id)
            ->unique()
            ->values();

        foreach ($recipientIds as $userId) {
            Notify::toUser(
                $userId,
                '🚨 تنبيه طوارئ: ' . $child->name,
                $message,
                'emergency'
            );
        }

        return response()->json([
            'alert' => DB::table('emergency_alerts')->find($id),
            'notified_recipients' => $recipientIds->count(),
        ], 201);
    }

    public function resolve(Request $request, $id)
    {
        $me = $request->attributes->get('jwt_user');
        $alert = DB::table('emergency_alerts')->where('id', (int) $id)->first();

        if (!$alert) {
            return response()->json(['error' => 'التنبيه غير موجود'], 404);
        }

        if (!ChildAccess::allowed($me, (int) $alert->child_id)) {
            return response()->json(['error' => 'غير مصرّح'], 403);
        }

        DB::table('emergency_alerts')->where('id', (int) $id)->update([
            'status' => 'resolved',
            'resolved_at' => now(),
            'updated_at' => now(),
        ]);

        return response()->json([
            'alert' => DB::table('emergency_alerts')->find((int) $id),
        ]);
    }
}
