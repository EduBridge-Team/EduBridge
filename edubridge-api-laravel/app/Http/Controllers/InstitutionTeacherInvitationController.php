<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;

class InstitutionTeacherInvitationController extends Controller
{
    public function index(Request $request, string $organizationSlug)
    {
        $org = $request->attributes->get('organization');
        return response()->json(['invitations' => DB::table('institution_teacher_invitations')
            ->where('organization_id', $org->id)
            ->select('id', 'email', 'expires_at', 'accepted_at', 'revoked_at', 'created_at')
            ->orderByDesc('id')->limit(100)->get()]);
    }

    public function store(Request $request, string $organizationSlug)
    {
        $org = $request->attributes->get('organization');
        $actor = $request->attributes->get('jwt_user');
        if (!$actor) return response()->json(['error' => 'غير مصرح'], 403);
        $data = $request->validate(['email' => ['required', 'email', 'max:190']]);
        $email = mb_strtolower(trim($data['email']));
        $token = Str::random(64);
        $id = DB::table('institution_teacher_invitations')->insertGetId([
            'organization_id' => $org->id, 'email' => $email,
            'token_hash' => hash('sha256', $token), 'invited_by' => $actor->id,
            'expires_at' => now()->addDays(7),
            'created_at' => now(), 'updated_at' => now(),
        ]);
        try {
            $url = rtrim((string) config('app.frontend_url', config('app.url')), '/') . '/teacher/invitation?token=' . urlencode($token);
            Mail::send('emails.auth-action', [
                'subjectLine' => 'دعوة معلم — EduBridge',
                'heading' => 'دعوة للانضمام إلى المؤسسة',
                'userName' => $email,
                'intro' => 'تلقّيت دعوة للانضمام كمعلم. سجّل الدخول بحساب معلم مؤكد البريد بنفس البريد، أو أنشئ حساب معلم ثم افتح الرابط.',
                'actionUrl' => $url, 'actionText' => 'قبول الدعوة',
                'expiryText' => 'صلاحية الرابط 7 أيام.',
                'ignoreText' => 'إذا لم تطلب هذه الدعوة فتجاهلها.',
            ], fn ($message) => $message->to($email)->subject('دعوة معلم — EduBridge'));
        } catch (\Throwable $e) {
            DB::table('institution_teacher_invitations')->where('id', $id)->delete();
            report($e);
            return response()->json(['error' => 'تعذّر إرسال الدعوة'], 503);
        }
        return response()->json(['message' => 'تم إرسال الدعوة'], 201);
    }
    public function revoke(Request $request, string $organizationSlug, int $invitation)
    {
        $org = $request->attributes->get('organization');
        $updated = DB::table('institution_teacher_invitations')
            ->where('organization_id', $org->id)->where('id', $invitation)
            ->whereNull('accepted_at')->whereNull('revoked_at')
            ->update(['revoked_at' => now(), 'updated_at' => now()]);
        return $updated ? response()->json(['revoked' => true])
            : response()->json(['error' => 'الدعوة غير نشطة أو غير موجودة'], 404);
    }

    public function accept(Request $request)
    {
        $actor = $request->attributes->get('jwt_user');
        $data = $request->validate(['token' => ['required', 'string', 'size:64']]);
        if (!$actor) return response()->json(['error' => 'غير مصرح'], 403);
        return DB::transaction(function () use ($actor, $data) {
            $user = DB::table('users')->where('id', $actor->id)->first();
            $invite = DB::table('institution_teacher_invitations')
                ->where('token_hash', hash('sha256', $data['token']))->lockForUpdate()->first();
            if (!$user || $user->role !== 'teacher' || !$user->email_verified_at)
                return response()->json(['error' => 'يجب استخدام حساب معلم مؤكد البريد'], 403);
            if (!$invite || $invite->accepted_at || $invite->revoked_at
                || now()->gte($invite->expires_at)
                || mb_strtolower(trim($user->email)) !== $invite->email)
                return response()->json(['error' => 'الدعوة غير صالحة أو منتهية'], 422);
            $member = DB::table('organization_user')
                ->where('organization_id', $invite->organization_id)->where('user_id', $user->id)->first();
            if ($member && $member->role !== 'teacher')
                return response()->json(['error' => 'لديك صلاحية مختلفة في المؤسسة'], 409);
            if ($member) {
                DB::table('organization_user')->where('id', $member->id)->update([
                    'is_active' => true, 'updated_at' => now(),
                ]);
            } else {
                DB::table('organization_user')->insert([
                    'organization_id' => $invite->organization_id,
                    'user_id' => $user->id, 'role' => 'teacher', 'is_active' => true,
                    'created_at' => now(), 'updated_at' => now(),
                ]);
            }
            DB::table('institution_teacher_invitations')->where('id', $invite->id)
                ->update(['accepted_at' => now(), 'updated_at' => now()]);
            return response()->json(['message' => 'تم تفعيل عضوية المعلم']);
        });
    }
}
