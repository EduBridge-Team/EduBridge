<?php

namespace App\Http\Controllers;

use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class InstitutionInternalTeacherController extends Controller
{
    public function index(Request $request, string $organizationSlug): JsonResponse
    {
        $org = $request->attributes->get('organization');
        if (!$org || !$this->ready()) return response()->json(['error' => 'Institution account schema unavailable'], 503);
        $query = Validator::make($request->query(), [
            'after_id' => ['sometimes', 'integer', 'min:0'],
            'limit' => ['sometimes', 'integer', 'min:1', 'max:100'],
        ])->validate();
        $limit = (int) ($query['limit'] ?? 100);
        $rows = DB::table('institution_internal_identities as i')
            ->join('users as u', 'u.id', '=', 'i.user_id')
            ->join('organization_user as ou', function ($join) {
                $join->on('ou.organization_id', '=', 'i.organization_id')
                    ->on('ou.user_id', '=', 'i.user_id');
            })
            ->where('i.organization_id', $org->id)
            ->where('ou.role', 'teacher')
            ->when(isset($query['after_id']), fn ($q) => $q->where('i.id', '>', $query['after_id']))
            ->select('i.id', 'i.user_id', 'i.username', 'i.is_active',
                'i.must_change_password', 'u.name', 'ou.is_active as membership_active')
            ->orderBy('i.id')->limit($limit + 1)->get();

        $page = $rows->take($limit)->values();
        return response()->json([
            'internal_domain' => $this->domain($org),
            'confirmed' => $org->internal_domain !== null,
            'identities' => $page,
            'has_more' => $rows->count() > $limit,
            'next_after_id' => $rows->count() > $limit ? (int) $page->last()->id : null,
        ]);
    }

    public function store(Request $request, string $organizationSlug): JsonResponse
    {
        $data = Validator::make($request->all(), [
            'name' => ['required', 'string', 'max:190'],
            'username' => ['required', 'string', 'regex:/^[a-z0-9][a-z0-9._-]{1,63}$/D'],
            'password' => ['nullable', 'string', 'min:12', 'max:128'],
        ])->validate();

        return $this->provision($request, [[
            'name' => $data['name'],
            'username' => $data['username'],
            'password' => $data['password'] ?? null,
        ]], false);
    }

    public function bulk(Request $request, string $organizationSlug): JsonResponse
    {
        // CSV is parsed client-side. Only names and usernames reach the API;
        // passwords are generated on the server and returned once.
        $data = Validator::make($request->all(), [
            'accounts' => ['required', 'array', 'min:1', 'max:100'],
            'accounts.*.name' => ['required', 'string', 'max:190'],
            'accounts.*.username' => ['required', 'string', 'regex:/^[a-z0-9][a-z0-9._-]{1,63}$/D'],
        ])->validate();

        return $this->provision($request, $data['accounts'], true);
    }

    private function provision(Request $request, array $accounts, bool $bulk): JsonResponse
    {
        $org = $request->attributes->get('organization');
        $actor = $request->attributes->get('jwt_user');
        if (!$org || !$actor) return response()->json(['error' => 'Forbidden'], 403);
        if (!$this->ready()) return response()->json(['error' => 'Institution account schema unavailable'], 503);

        $names = array_map(fn ($account) => trim($account['name']), $accounts);
        $usernames = array_map(fn ($account) => strtolower(trim($account['username'])), $accounts);
        if (count(array_unique($usernames)) !== count($usernames) ||
            in_array('', $names, true)) {
            return response()->json(['error' => 'Duplicated usernames or empty names'], 422);
        }

        try {
            $results = DB::transaction(function () use ($org, $actor, $accounts, $usernames, $names) {
                // Serialize provisioning on the organization row. Once reserved, a
                // namespace is immutable even if the public URL slug changes.
                $current = DB::table('organizations')->where('id', $org->id)
                    ->where('is_active', true)->lockForUpdate()->first();
                if (!$current) throw new \DomainException('Institution unavailable');
                $domain = $this->domain($current);
                if (!$domain || !preg_match('/^[a-z][a-z0-9-]{2,39}\.edubridge$/D', $domain)) {
                    throw new \DomainException('Invalid institution namespace');
                }
                if (DB::table('schools')->where('internal_domain', $domain)
                    ->exists()) {
                    throw new \DomainException('Namespace already assigned to a school');
                }
                if ($current->internal_domain === null) {
                    DB::table('organizations')->where('id', $org->id)
                        ->update(['internal_domain' => $domain]);
                }
                $existing = DB::table('institution_internal_identities')
                    ->where('organization_id', $org->id)->whereIn('username', $usernames)->exists();
                if ($existing) throw new \DomainException('Internal username is already taken');

                $created = [];
                foreach ($accounts as $index => $account) {
                    $identifier = $usernames[$index].'@'.$domain;
                    if (DB::table('users')->where('email', $identifier)->exists()) {
                        throw new \DomainException('Internal username is already taken');
                    }
                    $temporaryPassword = $account['password'] ?? null;
                    $generated = $temporaryPassword === null || $temporaryPassword === '';
                    if ($generated) $temporaryPassword = Str::random(24);
                    $hash = password_hash($temporaryPassword, PASSWORD_BCRYPT);

                    $user = [
                        'name' => $names[$index], 'email' => $identifier,
                        'role' => 'teacher', 'email_verified_at' => now(),
                        'created_at' => now(), 'updated_at' => now(),
                    ];
                    if (Schema::hasColumn('users', 'password_hash')) $user['password_hash'] = $hash;
                    if (Schema::hasColumn('users', 'password')) $user['password'] = $hash;
                    if (Schema::hasColumn('users', 'verification_status')) $user['verification_status'] = 'verified';
                    $userId = DB::table('users')->insertGetId($user);
                    DB::table('organization_user')->insert([
                        'organization_id' => $org->id, 'user_id' => $userId,
                        'role' => 'teacher', 'is_active' => true,
                        'created_at' => now(), 'updated_at' => now(),
                    ]);
                    $identityId = DB::table('institution_internal_identities')->insertGetId([
                        'organization_id' => $org->id, 'user_id' => $userId,
                        'username' => $usernames[$index],
                        'is_active' => true, 'must_change_password' => true,
                        'created_at' => now(), 'updated_at' => now(),
                    ]);
                    $this->audit((int) $org->id, (int) $actor->id, (int) $userId, 'teacher_created');
                    $row = [
                        'identity_id' => (int) $identityId,
                        'user_id' => (int) $userId, 'name' => $names[$index],
                        'login_identifier' => $identifier,
                        'must_change_password' => true,
                    ];
                    if ($generated) $row['temporary_password'] = $temporaryPassword;
                    $created[] = $row;
                }
                return $created;
            }, 3);
            return response()->json([
                'internal_domain' => explode('@', $results[0]['login_identifier'])[1],
                'created' => count($results),
                'accounts' => $results,
            ], 201);
        } catch (\DomainException $e) {
            return response()->json(['error' => $e->getMessage()], 409);
        } catch (QueryException $e) {
            if (in_array((string) $e->getCode(), ['23505', '23000'], true)) {
                return response()->json(['error' => 'Internal username is already taken'], 409);
            }
            throw $e;
        }
    }

    public function update(Request $request, string $organizationSlug, int $identity): JsonResponse
    {
        $data = Validator::make($request->all(), [
            'is_active' => ['required', 'boolean'],
        ])->validate();
        $org = $request->attributes->get('organization');
        $actor = $request->attributes->get('jwt_user');
        if (!$org || !$actor) return response()->json(['error' => 'Forbidden'], 403);
        if (!$this->ready()) return response()->json(['error' => 'Institution account schema unavailable'], 503);

        return DB::transaction(function () use ($org, $actor, $identity, $data) {
            $row = DB::table('institution_internal_identities as i')
                ->join('organization_user as ou', function ($join) {
                    $join->on('ou.organization_id', '=', 'i.organization_id')
                        ->on('ou.user_id', '=', 'i.user_id');
                })
                ->where('i.organization_id', $org->id)->where('i.id', $identity)
                ->where('ou.role', 'teacher')
                ->select('i.id', 'i.user_id', 'i.is_active')
                ->lockForUpdate()->first();
            if (!$row) return response()->json(['error' => 'Account not found'], 404);

            DB::table('institution_internal_identities')->where('id', $identity)
                ->update(['is_active' => (bool) $data['is_active'], 'updated_at' => now()]);
            $update = ['updated_at' => now()];
            if (Schema::hasColumn('users', 'session_version')) {
                $update['session_version'] = DB::raw('session_version + 1');
            }
            DB::table('users')->where('id', $row->user_id)->update($update);
            $this->audit((int) $org->id, (int) $actor->id,
                (int) $row->user_id, $data['is_active'] ? 'teacher_activated' : 'teacher_deactivated');

            return response()->json(['identity_id' => $identity, 'is_active' => (bool) $data['is_active']]);
        }, 3);
    }

    public function resetPassword(Request $request, string $organizationSlug, int $identity): JsonResponse
    {
        $data = Validator::make($request->all(), [
            'password' => ['nullable', 'string', 'min:12', 'max:128'],
        ])->validate();
        $org = $request->attributes->get('organization');
        $actor = $request->attributes->get('jwt_user');
        if (!$org || !$actor) return response()->json(['error' => 'Forbidden'], 403);
        if (!$this->ready()) return response()->json(['error' => 'Institution account schema unavailable'], 503);

        $password = $data['password'] ?? Str::random(24);
        $generated = !isset($data['password']) || $data['password'] === '';
        return DB::transaction(function () use ($org, $actor, $identity, $password, $generated) {
            $row = DB::table('institution_internal_identities')
                ->where('organization_id', $org->id)->where('id', $identity)
                ->lockForUpdate()->first();
            if (!$row) return response()->json(['error' => 'Account not found'], 404);
            $hash = password_hash($password, PASSWORD_BCRYPT);
            $update = ['updated_at' => now()];
            if (Schema::hasColumn('users', 'password_hash')) $update['password_hash'] = $hash;
            if (Schema::hasColumn('users', 'password')) $update['password'] = $hash;
            if (Schema::hasColumn('users', 'session_version')) {
                $update['session_version'] = DB::raw('session_version + 1');
            }
            DB::table('users')->where('id', $row->user_id)->update($update);
            DB::table('institution_internal_identities')->where('id', $identity)
                ->update(['must_change_password' => true, 'updated_at' => now()]);
            $this->audit((int) $org->id, (int) $actor->id, (int) $row->user_id, 'password_reset');

            $response = ['identity_id' => $identity, 'must_change_password' => true];
            if ($generated) $response['temporary_password'] = $password;
            return response()->json($response);
        }, 3);
    }

    private function domain(object $org): ?string
    {
        if (!empty($org->internal_domain)) return $org->internal_domain;
        $slug = (string) ($org->slug ?? '');
        return preg_match('/^[a-z][a-z0-9-]{2,39}$/D', $slug) ? $slug.'.edubridge' : null;
    }

    private function ready(): bool
    {
        return Schema::hasTable('institution_internal_identities')
            && Schema::hasTable('institution_internal_account_events')
            && Schema::hasColumn('organizations', 'internal_domain')
            && (Schema::hasColumn('users', 'password_hash') || Schema::hasColumn('users', 'password'));
    }

    private function audit(int $organization, int $actor, int $subject, string $action): void
    {
        DB::table('institution_internal_account_events')->insert([
            'organization_id' => $organization, 'actor_id' => $actor,
            'subject_id' => $subject, 'action' => $action, 'created_at' => now(),
        ]);
    }
}
