<?php

namespace App\Support;

use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

/**
 * Official school mailbox is a separate login (role=school).
 * The director's personal account is appointed independently.
 *
 * No provisioning password or activation token is ever returned to the operator.
 */
final class SchoolOfficialAccountProvisioning
{
    public function create(Request $request, ?int $organizationId): JsonResponse
    {
        $validation = Validator::make($request->all(), [
            'name' => ['required', 'string', 'max:150'],
            'email' => ['required', 'email', 'max:190'],
            'director_email' => ['nullable', 'email', 'max:190'],
            'invite_director' => ['sometimes', 'boolean'],
            'phone' => ['nullable', 'string', 'max:30'],
            'address' => ['nullable', 'string', 'max:255'],
        ]);
        if ($validation->fails()) {
            return response()->json(['errors' => $validation->errors()], 422);
        }
        $data = $validation->validated();
        $name = trim($data['name']);
        $email = mb_strtolower(trim($data['email']));
        $directorEmail = isset($data['director_email']) && trim($data['director_email']) !== ''
            ? mb_strtolower(trim($data['director_email'])) : null;
        $inviteDirector = (bool) ($data['invite_director'] ?? false);
        if ($name === '') {
            return response()->json(['errors' => ['name' => ['Required']]], 422);
        }
        if (str_ends_with($email, '.edubridge')) {
            return response()->json(['errors' => ['email' => ['A real school mailbox is required']]], 422);
        }
        if ($directorEmail !== null && ($directorEmail === $email || str_ends_with($directorEmail, '.edubridge'))) {
            return response()->json(['errors' => ['director_email' => ['A different personal mailbox is required']]], 422);
        }
        if ($inviteDirector && !$directorEmail) {
            return response()->json(['errors' => ['director_email' => ['Required to send director invitation']]], 422);
        }

        if (!Schema::hasTable('school_accounts') || !Schema::hasTable('password_reset_tokens')
            || !Schema::hasColumn('users', 'email_verified_at')) {
            return response()->json(['error' => 'School activation storage is unavailable'], 503);
        }
        $passwordColumn = Schema::hasColumn('users', 'password_hash')
            ? 'password_hash' : (Schema::hasColumn('users', 'password') ? 'password' : null);
        if ($passwordColumn === null) {
            return response()->json(['error' => 'Password storage is unavailable'], 503);
        }

        try {
            return DB::transaction(function () use ($request, $organizationId, $name, $email, $directorEmail, $inviteDirector, $data, $passwordColumn) {
                if (DB::table('users')->whereRaw('LOWER(email) = ?', [$email])->exists()
                    || DB::table('schools')->whereRaw('LOWER(email) = ?', [$email])->exists()) {
                    return response()->json(['errors' => ['email' => ['Already in use']]], 409);
                }

                $director = null;
                if ($directorEmail !== null && !$inviteDirector) {
                    $director = DB::table('users')->whereRaw('LOWER(email) = ?', [$directorEmail])->lockForUpdate()->first();
                    if (!$director || ($director->role ?? null) === 'school' || empty($director->email_verified_at)
                        || (property_exists($director, 'verification_status')
                            && !in_array($director->verification_status, ['verified', 'approved'], true))) {
                        return response()->json(['error' => 'Existing verified director account required'], 422);
                    }
                    if (DB::table('school_management_assignments')->where('user_id', $director->id)
                        ->where('role', 'director')->whereNull('ends_at')->exists()) {
                        return response()->json(['error' => 'Director already has an active school assignment'], 409);
                    }
                }

                $schoolId = DB::table('schools')->insertGetId([
                    'organization_id' => $organizationId,
                    'name' => $name,
                    'slug' => 'school-' . Str::lower(Str::random(24)),
                    'email' => $email,
                    'phone' => $data['phone'] ?? null,
                    'address' => $data['address'] ?? null,
                    'settings' => '{}',
                    'is_active' => true,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);

                // Random undisclosed credential: only the school's mailbox owner
                // can choose a real password through the one-time setup link.
                $hash = password_hash(bin2hex(random_bytes(32)), PASSWORD_BCRYPT);
                $user = [
                    'name' => $name,
                    'email' => $email,
                    'role' => 'school',
                    $passwordColumn => $hash,
                    'email_verified_at' => null,
                    'created_at' => now(),
                    'updated_at' => now(),
                ];
                if (Schema::hasColumn('users', 'password') && Schema::hasColumn('users', 'password_hash')) {
                    $user['password'] = $hash;
                    $user['password_hash'] = $hash;
                }
                if (Schema::hasColumn('users', 'verification_status')) {
                    $user['verification_status'] = 'pending';
                }
                $schoolUserId = DB::table('users')->insertGetId($user);
                DB::table('school_accounts')->insert([
                    'school_id' => $schoolId,
                    'user_id' => $schoolUserId,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);

                $token = Str::random(64);
                DB::table('password_reset_tokens')->updateOrInsert(
                    ['email' => $email],
                    ['token' => hash('sha256', $token), 'created_at' => now()]
                );
                $url = rtrim((string) config('app.frontend_url', config('app.url')), '/')
                    . '/reset-password?email=' . urlencode($email) . '&token=' . urlencode($token);
                try {
                    Mail::send('emails.auth-action', [
                        'subjectLine' => 'تفعيل حساب المدرسة — EduBridge',
                        'heading' => 'تفعيل حساب المدرسة',
                        'userName' => $name,
                        'intro' => 'تم إنشاء الحساب الرسمي لمدرستكم. استخدم هذا الرابط لتعيين كلمة المرور وتأكيد ملكية بريد المدرسة. حساب المدير الشخصي مستقل.',
                        'actionUrl' => $url,
                        'actionText' => 'تفعيل الحساب وتعيين كلمة المرور',
                        'expiryText' => 'صلاحية الرابط 60 دقيقة. بعد انتهائه استخدم استعادة كلمة المرور.',
                        'ignoreText' => 'إن لم تكن هذه مدرستك، تجاهل هذه الرسالة.',
                    ], fn ($message) => $message->to($email)->subject('تفعيل حساب المدرسة — EduBridge'));
                } catch (\Throwable $error) {
                    report($error);
                    throw new \RuntimeException('SCHOOL_ACTIVATION_DELIVERY_FAILED', 0, $error);
                }

                $receipt = [
                    'school' => ['id' => (int) $schoolId, 'name' => $name, 'organization_id' => $organizationId],
                    'account' => ['id' => (int) $schoolUserId, 'email' => $email, 'role' => 'school', 'activation_pending' => true],
                ];
                if ($director !== null) {
                    DB::table('school_management_assignments')->insert([
                        'school_id' => $schoolId, 'user_id' => $director->id, 'role' => 'director',
                        'appointed_by' => $request->attributes->get('jwt_user')->id,
                        'starts_at' => now(), 'ends_at' => null, 'created_at' => now(), 'updated_at' => now(),
                    ]);
                    $receipt['director'] = ['id' => (int) $director->id, 'email' => $directorEmail];
                } elseif ($inviteDirector) {
                    $receipt['invitation'] = SchoolDirectorInvitations::issue(
                        DB::table('schools')->find($schoolId), $directorEmail,
                        (int) $request->attributes->get('jwt_user')->id
                    );
                }

                return response()->json($receipt, 201);
            }, 3);
        } catch (QueryException $error) {
            if (in_array((string) $error->getCode(), ['23505', '23000'], true)) {
                return response()->json(['error' => 'Duplicate school email'], 409);
            }
            report($error);
        } catch (\RuntimeException $error) {
            if ($error->getMessage() === 'SCHOOL_ACTIVATION_DELIVERY_FAILED') {
                return response()->json(['error' => 'School activation email delivery failed'], 503);
            }
            report($error);
        } catch (\Throwable $error) {
            report($error);
        }
        return response()->json(['error' => 'Could not provision school'], 500);
    }
}
