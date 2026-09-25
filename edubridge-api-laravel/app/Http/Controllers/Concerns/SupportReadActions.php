<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait SupportReadActions
{
    public function index(Request $request)
    {
        $user = $request->attributes->get('jwt_user');

        try {
            $query = DB::table('support_tickets as t')
                ->leftJoin('users as u', 'u.id', '=', 't.user_id')
                ->select(
                    't.*',
                    'u.name as user_name',
                    'u.email as user_email',
                    'u.role as user_role'
                )
                ->orderByDesc('t.created_at');

            if ($user->role === 'admin') {
                if ($request->query('status')) {
                    $query->where('t.status', $request->query('status'));
                }
                if ($request->query('category')) {
                    $query->where('t.category', $request->query('category'));
                }
            } else {
                $query->where('t.user_id', $user->id);
            }

            return response()->json(['tickets' => $query->get()]);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
