<?php

namespace App\Http\Controllers;

use App\Support\Notify;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class LegacyMobileController extends Controller
{
    private function encodeId(int $sourceId, int $type): int
    {
        return $sourceId * 10 + $type;
    }

    private function decodeId(int $id): array
    {
        return [intdiv($id, 10), $id % 10];
    }

    public function adminVerifications()
    {
        $requests = collect();

        DB::table('users')
            ->where('verification_status', 'pending')
            ->orderByDesc('created_at')
            ->get(['id','name','email','national_id','id_document_url','created_at'])
            ->each(function ($u) use ($requests) {
                $requests->push([
                    'id' => $this->encodeId((int) $u->id, 1),
                    'source_id' => $u->id,
                    'type' => 'users',
                    'name' => $u->name,
                    'email' => $u->email,
                    'national_id' => $u->national_id,
                    'document_url' => $u->id_document_url,
                    'created_at' => $u->created_at,
                ]);
            });

        DB::table('children')
            ->where('doc_verification_status', 'pending')
            ->orderByDesc('created_at')
            ->get(['id','name','child_national_id','guardian_national_id','guardian_id_document_url','kinship_document_url','created_at'])
            ->each(function ($c) use ($requests) {
                $requests->push([
                    'id' => $this->encodeId((int) $c->id, 2),
                    'source_id' => $c->id,
                    'type' => 'children',
                    'name' => $c->name,
                    'email' => '',
                    'national_id' => $c->child_national_id,
                    'guardian_national_id' => $c->guardian_national_id,
                    'document_url' => $c->guardian_id_document_url,
                    'kinship_document_url' => $c->kinship_document_url,
                    'created_at' => $c->created_at,
                ]);
            });

        DB::table('certificates as c')
            ->join('users as u', 'u.id', '=', 'c.user_id')
            ->where('c.status', 'pending')
            ->orderByDesc('c.created_at')
            ->get(['c.id','c.title','c.url','c.created_at','u.name','u.email'])
            ->each(function ($c) use ($requests) {
                $requests->push([
                    'id' => $this->encodeId((int) $c->id, 3),
                    'source_id' => $c->id,
                    'type' => 'certificates',
                    'name' => $c->name,
                    'email' => $c->email,
                    'title' => $c->title,
                    'document_url' => $c->url,
                    'created_at' => $c->created_at,
                ]);
            });

        return response()->json([
            'requests' => $requests->sortByDesc('created_at')->values(),
        ]);
    }

    public function approveVerification(Request $request, $id)
    {
        return $this->reviewVerification((int) $id, true);
    }

    public function rejectVerification(Request $request, $id)
    {
        return $this->reviewVerification((int) $id, false);
    }

    private function reviewVerification(int $encodedId, bool $approve)
    {
        [$sourceId, $type] = $this->decodeId($encodedId);

        if ($sourceId <= 0 || !in_array($type, [1,2,3], true)) {
            return response()->json(['error' => 'طلب التوثيق غير صالح'], 404);
        }

        $status = $approve ? 'verified' : 'rejected';

        if ($type === 1) {
            $row = DB::table('users')->where('id', $sourceId)->first();
            if (!$row) return response()->json(['error' => 'المستخدم غير موجود'], 404);
            DB::table('users')->where('id', $sourceId)->update([
                'verification_status' => $status,
                'verified_at' => $approve ? now() : null,
            ]);
            Notify::toUser($sourceId, $approve ? 'تم توثيق حسابك' : 'تم رفض توثيق حسابك',
                $approve ? 'تم توثيق هويتك بنجاح.' : 'يرجى إعادة رفع مستندات صحيحة.', 'verification');
        } elseif ($type === 2) {
            $row = DB::table('children')->where('id', $sourceId)->first();
            if (!$row) return response()->json(['error' => 'الطفل غير موجود'], 404);
            DB::table('children')->where('id', $sourceId)->update([
                'doc_verification_status' => $status,
            ]);
            Notify::toChildParents($sourceId, $approve ? 'تم توثيق بيانات الطفل' : 'تم رفض توثيق بيانات الطفل',
                $approve ? 'تم التحقق من المستندات بنجاح.' : 'يرجى إعادة رفع المستندات.', 'verification');
        } else {
            $row = DB::table('certificates')->where('id', $sourceId)->first();
            if (!$row) return response()->json(['error' => 'الشهادة غير موجودة'], 404);
            DB::table('certificates')->where('id', $sourceId)->update(['status' => $status]);
            Notify::toUser($row->user_id, $approve ? 'تم اعتماد شهادتك' : 'تم رفض شهادتك',
                ($approve ? 'تم اعتماد الشهادة: ' : 'تم رفض الشهادة: ') . $row->title, 'certificate');
        }

        return response()->json(['ok' => true]);
    }


}
