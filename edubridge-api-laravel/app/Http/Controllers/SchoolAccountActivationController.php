<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Database\QueryException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class SchoolAccountActivationController extends Controller
{
    public function requestSetup(Request $request): JsonResponse
    {
        $data = Validator::make($request->all(), [
            'email' => ['required', 'email', 'max:190'],
        ])->validate();
        $email = mb_strtolower(trim($data['email']));
        $generic = ['message' => 'If this school is eligible, setup instructions will be sent.'];

        if (!Schema::hasTable('school_account_setup_tokens')
            || !Schema::hasColumn('schools', 'official_email')) {
            return response()->json(['error' => 'School setup unavailable'], 503);
        }
        // The public endpoint must not reveal whether an email belongs to a school.
        $school = DB::table('schools')->whereRaw('LOWER(official_email) = ?', [$email])->first();
        if ($school) {
            $this->dispatchForSchoolId((int) $school->id);
        }
        return response()->json($generic);
    }

    /**
     * Internal provisioning hook, called only after school creation commits.
     * "sent" means the configured mail transport accepted the message;
     * it does not certify delivery to the recipient's inbox.
     */
    public function dispatchForSchoolId(int $schoolId): string
    {
        if (!Schema::hasTable('school_account_setup_tokens')
            || !Schema::hasColumn('schools', 'official_email')) {
            return 'unavailable';
        }

        try {
            // Serialise requests by school row: concurrent resends cannot replace
            // each other's one-time token or bypass the per-school cooldown.
            $delivery = DB::transaction(function () use ($schoolId) {
                $school = DB::table('schools')->where('id', $schoolId)->lockForUpdate()->first();
                if (!$school || !$school->is_active || !$school->official_email
                    || $school->official_email_verified_at
                    || DB::table('school_accounts')->where('school_id', $school->id)->exists()
                    || ($school->organization_id !== null && !DB::table('organizations')
                        ->where('id', $school->organization_id)->where('is_active', true)->exists())) {
                    return null;
                }

                $existing = DB::table('school_account_setup_tokens')
                    ->where('school_id', $school->id)->first();
                if ($existing && \Illuminate\Support\Carbon::parse($existing->updated_at)
                    ->gt(now()->subMinutes(10))) {
                    return null;
                }

                $token = Str::random(64);
                $hash = hash('sha256', $token);
                DB::table('school_account_setup_tokens')->updateOrInsert(
                    ['school_id' => $school->id],
                    ['token_hash' => $hash, 'expires_at' => now()->addHours(24),
                        'created_at' => now(), 'updated_at' => now()]
                );
                return [
                    'school_id' => (int) $school->id,
                    'email' => mb_strtolower(trim($school->official_email)),
                    'name' => $school->name,
                    'token' => $token,
                    'hash' => $hash,
                ];
            }, 3);
        } catch (\Throwable $e) {
            report($e);
            return 'failed';
        }

        if (!$delivery) {
            return 'not_eligible';
        }

        $frontend = rtrim((string) config('app.frontend_url', config('app.url')), '/');
        $url = $frontend . '/school-account/setup?email=' . urlencode($delivery['email'])
            . '&token=' . urlencode($delivery['token']);
        try {
            Mail::send('emails.auth-action', [
                'subjectLine' => 'تفعيل الحساب الرسمي للمدرسة — EduBridge',
                'heading' => 'تفعيل حساب المدرسة',
                'userName' => $delivery['name'],
                'intro' => 'لتأكيد البريد الرسمي للمدرسة وإنشاء كلمة المرور، افتح الرابط التالي.',
                'actionUrl' => $url,
                'actionText' => 'تفعيل حساب المدرسة',
                'expiryText' => 'صلاحية الرابط 24 ساعة فقط.',
                'ignoreText' => 'إذا لم تطلب هذه الرسالة، يمكنك تجاهلها.',
            ], fn ($message) => $message->to($delivery['email'])
                ->subject('تفعيل الحساب الرسمي للمدرسة — EduBridge'));
        } catch (\Throwable $e) {
            DB::table('school_account_setup_tokens')
                ->where('school_id', $delivery['school_id'])
                ->where('token_hash', $delivery['hash'])->delete();
            report($e);
            return 'failed';
        }
        return 'sent';
    }

    public function complete(Request $request): JsonResponse
    {
        $validation = Validator::make($request->all(), [
            'email' => ['required', 'email', 'max:190'],
            'token' => ['required', 'string', 'min:32', 'max:256'],
            'password' => ['required', 'string', 'min:12', 'max:128', 'confirmed'],
        ]);
        if ($validation->fails()) return response()->json(['errors' => $validation->errors()], 422);
        $data = $validation->validated();
        $email = mb_strtolower(trim($data['email']));
        if (!Schema::hasTable('school_account_setup_tokens')
            || !Schema::hasColumn('schools', 'official_email')) {
            return response()->json(['error' => 'School setup unavailable'], 503);
        }
        $passwordColumn = Schema::hasColumn('users', 'password_hash') ? 'password_hash'
            : (Schema::hasColumn('users', 'password') ? 'password' : null);
        if (!$passwordColumn) return response()->json(['error' => 'Account setup unavailable'], 503);

        try {
            return DB::transaction(function () use ($email, $data, $passwordColumn) {
            $school = DB::table('schools')->whereRaw('LOWER(official_email) = ?', [$email])
                ->lockForUpdate()->first();
            if (!$school || !$school->is_active || $school->official_email_verified_at
                || DB::table('school_accounts')->where('school_id', $school->id)->exists()
                || ($school->organization_id !== null && !DB::table('organizations')
                    ->where('id', $school->organization_id)->where('is_active', true)->exists())) {
                return response()->json(['error' => 'Invalid or expired setup link'], 422);
            }
            $record = DB::table('school_account_setup_tokens')->where('school_id', $school->id)
                ->lockForUpdate()->first();
            if (!$record || !hash_equals($record->token_hash, hash('sha256', $data['token']))
                || \Illuminate\Support\Carbon::parse($record->expires_at)->lte(now())) {
                return response()->json(['error' => 'Invalid or expired setup link'], 422);
            }
            if (DB::table('users')->whereRaw('LOWER(email) = ?', [$email])->exists()) {
                return response()->json(['error' => 'Account email unavailable'], 409);
            }
            $hash = password_hash($data['password'], PASSWORD_BCRYPT);
            $user = ['name' => $school->name, 'email' => $email, 'role' => 'school',
                $passwordColumn => $hash, 'email_verified_at' => now(),
                'created_at' => now(), 'updated_at' => now()];
            if (Schema::hasColumn('users', 'password') && Schema::hasColumn('users', 'password_hash')) {
                $user['password'] = $hash;
                $user['password_hash'] = $hash;
            }
            if (Schema::hasColumn('users', 'verification_status')) $user['verification_status'] = 'verified';
            $userId = DB::table('users')->insertGetId($user);
            DB::table('school_accounts')->insert([
                'school_id' => $school->id, 'user_id' => $userId,
                'created_at' => now(), 'updated_at' => now(),
            ]);
            DB::table('schools')->where('id', $school->id)
                ->update(['official_email_verified_at' => now(), 'updated_at' => now()]);
            DB::table('school_account_setup_tokens')->where('school_id', $school->id)->delete();
            return response()->json(['message' => 'School account activated. You can sign in.']);
        }, 3);
        } catch (QueryException $e) {
            // A simultaneous user creation may win the unique-email constraint.
            if (in_array((string) $e->getCode(), ['23505', '23000'], true)) {
                return response()->json(['error' => 'Account email unavailable'], 409);
            }
            report($e);
            return response()->json(['error' => 'Account setup temporarily unavailable'], 503);
        }
    }
}
