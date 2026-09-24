<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait ConsultationReadActions
{
    public function index(Request $request)
    {
        $user = $request->attributes->get('jwt_user');

        try {
            $query = DB::table('consultations as k')
                ->leftJoin('children as c', 'c.id', '=', 'k.child_id')
                ->leftJoin('users as r', 'r.id', '=', 'k.requester_id')
                ->leftJoin('users as s', 's.id', '=', 'k.specialist_id')
                ->select(
                    'k.*',
                    'c.name as child_name',
                    'r.name as requester_name',
                    's.name as specialist_name'
                )
                ->orderByDesc('k.created_at');

            if ($user->role === 'admin') {
                // Admin can see all consultations.
            } elseif ($user->role === 'specialist') {
                $query->where(function ($q) use ($user) {
                    $q->where('k.specialist_id', $user->id)
                        ->orWhere(function ($open) {
                            $open->whereNull('k.specialist_id')
                                ->where('k.status', 'open');
                        });
                });
            } else {
                $query->where(function ($q) use ($user) {
                    $q->where('k.requester_id', $user->id)
                        ->orWhereIn('k.child_id', function ($sub) use ($user) {
                            $sub->from('child_parent')
                                ->select('child_id')
                                ->where('parent_id', $user->id);
                        });
                });
            }

            return response()->json(['consultations' => $query->get()]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }

    public function show(Request $request, $id)
    {
        $user = $request->attributes->get('jwt_user');

        try {
            $consultation = DB::table('consultations as k')
                ->leftJoin('children as c', 'c.id', '=', 'k.child_id')
                ->leftJoin('users as r', 'r.id', '=', 'k.requester_id')
                ->leftJoin('users as s', 's.id', '=', 'k.specialist_id')
                ->where('k.id', $id)
                ->select(
                    'k.*',
                    'c.name as child_name',
                    'r.name as requester_name',
                    's.name as specialist_name'
                )
                ->first();

            if (!$consultation) {
                return response()->json(['error' => 'الاستشارة غير موجودة'], 404);
            }
            if (!$this->canAccess($user, $consultation)) {
                return response()->json(['error' => 'غير مصرّح'], 403);
            }

            $notes = DB::table('consultation_notes as n')
                ->leftJoin('users as u', 'u.id', '=', 'n.author_id')
                ->where('n.consultation_id', $id)
                ->select('n.id', 'n.content', 'n.created_at', 'u.name as author_name')
                ->orderBy('n.created_at')
                ->get();

            return response()->json(['consultation' => $consultation, 'notes' => $notes]);
        } catch (\Exception $e) {
            report($e);
            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
