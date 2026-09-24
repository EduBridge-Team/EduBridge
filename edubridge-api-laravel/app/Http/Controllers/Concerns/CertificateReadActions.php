<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait CertificateReadActions
{
    public function index(Request $request)
    {
        $me = $request->attributes->get('jwt_user');

        try {
            if ($me->role === 'admin') {
                $query = DB::table('certificates as c')
                    ->leftJoin('users as u', 'u.id', '=', 'c.user_id')
                    ->select(
                        'c.*',
                        'u.name as user_name',
                        'u.email as user_email',
                        'u.role as user_role'
                    )
                    ->orderByDesc('c.created_at');

                if ($request->query('user_id')) {
                    $query->where('c.user_id', $request->query('user_id'));
                }
                if ($request->query('status')) {
                    $query->where('c.status', $request->query('status'));
                }
            } else {
                $query = DB::table('certificates')
                    ->where('user_id', $me->id)
                    ->orderByDesc('created_at');
            }

            return response()->json(['certificates' => $query->get()]);
        } catch (\Exception $e) {
            report($e);

            return response()->json(['error' => 'خطأ في السيرفر'], 500);
        }
    }
}
