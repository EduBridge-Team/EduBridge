<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class SchoolOfficialSetupController extends Controller
{
    public function send(Request $request, int $school): JsonResponse
    {
        $actor = $request->attributes->get('jwt_user');
        if (!$actor || !in_array($actor->role ?? null, ['admin', 'institution'], true)) {
            return response()->json(['error' => 'Forbidden'], 403);
        }

        $record = DB::table('schools')->where('id', $school)->first();
        if (!$record || !($record->is_active ?? false) || empty($record->official_email)
            || !empty($record->official_email_verified_at)) {
            return response()->json(['error' => 'School account is not eligible for setup'], 409);
        }
        if ($actor->role === 'institution') {
            $authorized = $record->organization_id !== null
                && DB::table('organization_user')->where('organization_id', $record->organization_id)
                    ->where('user_id', $actor->id)->where('is_active', true)
                    ->whereIn('role', ['owner', 'admin'])->exists();
            if (!$authorized) {
                return response()->json(['error' => 'Forbidden'], 403);
            }
        }
        if (DB::table('school_accounts')->where('school_id', $school)->exists()) {
            return response()->json(['error' => 'School already has an account'], 409);
        }

        $previous = DB::table('school_official_setup_tokens')->where('school_id', $school)->first();
        if ($previous && $previous->created_at
            && \Illuminate\Support\Carbon::parse($previous->created_at)->gt(now()->subMinutes(2))) {
            return response()->json(['error' => 'Setup link sent recently'], 429);
        }

        $token = Str::random(64);
        $email = mb_strtolower(trim((string) $record->official_email));
        $url = rtrim((string) config('app.frontend_url', config('app.url')), '/')
            . '/school-account-setup?email=' . urlencode($email) . '&token=' . urlencode($token);

        try {
            DB::table('school_official_setup_tokens')->updateOrInsert(
                ['school_id' => $school],
                ['token_hash' => hash('sha256', $token), 'created_at' => now()]
            );
            Mail::send('emails.auth-action', [
                'subjectLine' => 'تفعيل البريد الرسمي للمدرسة — EduBridge',
                'heading' => 'تفعيل حساب المدرسة',
                'userName' => $record->name,
                'intro' => 'لتأكيد البريد الرسمي للمدرسة وتعيين كلمة مرور خاصة بها، افتح الرابط التالي.',
                'actionUrl' => $url,
                'actionText' => 'تفعيل حساب المدرسة',
                'expiryText' => 'صلاحية الرابط 60 دقيقة.',
                'ignoreText' => 'إذا لم تتوقع هذه الرسالة فتجاهلها.',
            ], function ($message) use ($email) {
                $message->to($email)->subject('تفعيل البريد الرسمي للمدرسة — EduBridge');
            });
        } catch (\Throwable $e) {
            report($e);
            DB::table('school_official_setup_tokens')->where('school_id', $school)
                ->where('token_hash', hash('sha256', $token))->delete();
            return response()->json(['error' => 'Could not deliver setup email'], 503);
        }

        return response()->json(['message' => 'Setup link sent to official school mailbox'], 202);
    }

    public function activate(Request $request): JsonResponse
    {
        $validation = Validator::make($request->all(), [
            'email' => ['required', 'email', 'max:190'],
            'token' => ['required', 'string', 'min:32', 'max:256'],
            'password' => ['required', 'string', 'min:12', 'max:128'],
            'password_confirmation' => ['required', 'same:password'],
        ]);
        if ($validation->fails()) {
            return response()->json(['errors' => $validation->errors()], 422);
        }
        $input = $validation->validated();
        $email = mb_strtolower(trim($input['email']));
        $tokenHash = hash('sha256', $input['token']);

        try {
            return DB::transaction(function () use ($email, $tokenHash, $input) {
                $school = DB::table('schools')->whereRaw('LOWER(official_email) = ?', [$email])
                    ->lockForUpdate()->first();
                if (!$school || !$school->is_active || $school->official_email_verified_at
                    || DB::table('school_accounts')->where('school_id', $school->id)->exists()
                    || DB::table('users')->whereRaw('LOWER(email) = ?', [$email])->exists()) {
                    return response()->json(['error' => 'Invalid or expired setup link'], 422);
                }
                if ($school->organization_id !== null
                    && !DB::table('organizations')->where('id', $school->organization_id)
                        ->where('is_active', true)->exists()) {
                    return response()->json(['error' => 'School is inactive'], 403);
                }
                $setup = DB::table('school_official_setup_tokens')
                    ->where('school_id', $school->id)->lockForUpdate()->first();
                if (!$setup || !hash_equals((string) $setup->token_hash, $tokenHash)
                    || !$setup->created_at
                    || \Illuminate\Support\Carbon::parse($setup->created_at)->lte(now()->subMinutes(60))) {
                    return response()->json(['error' => 'Invalid or expired setup link'], 422);
                }
                $passwordColumn = Schema::hasColumn('users', 'password_hash') ? 'password_hash' : 'password';
                $user = [
                    'name' => $school->name,
                    'email' => $email,
                    'role' => 'school_official',
                    $passwordColumn => password_hash($input['password'], PASSWORD_BCRYPT),
                    'email_verified_at' => now(),
                    'created_at' => now(), 'updated_at' => now(),
                ];
                if (Schema::hasColumn('users', 'verification_status')) {
                    $user['verification_status'] = 'verified';
                }
                $userId = DB::table('users')->insertGetId($user);
                DB::table('school_accounts')->insert([
                    'school_id' => $school->id, 'user_id' => $userId,
                    'created_at' => now(), 'updated_at' => now(),
                ]);
                DB::table('schools')->where('id', $school->id)
                    ->update(['official_email_verified_at' => now(), 'updated_at' => now()]);
                DB::table('school_official_setup_tokens')->where('school_id', $school->id)->delete();

                return response()->json(['message' => 'Official school account activated'], 200);
            }, 3);
        } catch (\Throwable $e) {
            report($e);
            return response()->json(['error' => 'Unable to activate school account'], 500);
        }
    }

    public function me(Request $request): JsonResponse
    {
        $actor = $request->attributes->get('jwt_user');
        if (($actor->role ?? null) !== 'school_official') {
            return response()->json(['error' => 'Forbidden'], 403);
        }
        $school = DB::table('school_accounts as account')
            ->join('schools as school', 'school.id', '=', 'account.school_id')
            ->where('account.user_id', $actor->id)
            ->select('school.id', 'school.name', 'school.official_email', 'school.official_email_verified_at')
            ->first();
        return $school ? response()->json(['school' => $school]) : response()->json(['error' => 'Unavailable'], 403);
    }
}
