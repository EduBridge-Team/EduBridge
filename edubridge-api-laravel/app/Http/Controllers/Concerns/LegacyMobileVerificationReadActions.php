<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Support\Facades\DB;

trait LegacyMobileVerificationReadActions
{
    public function adminVerifications()
    {
        $requests = collect();

        DB::table('users')
            ->where('verification_status', 'pending')
            ->orderByDesc('created_at')
            ->get(['id','name','email','national_id','id_document_url','created_at'])
            ->each(function ($user) use ($requests) {
                $requests->push([
                    'id' => $this->encodeId((int) $user->id, 1),
                    'source_id' => $user->id,
                    'type' => 'users',
                    'name' => $user->name,
                    'email' => $user->email,
                    'national_id' => $user->national_id,
                    'document_url' => $user->id_document_url,
                    'created_at' => $user->created_at,
                ]);
            });

        DB::table('children')
            ->where('doc_verification_status', 'pending')
            ->orderByDesc('created_at')
            ->get([
                'id','name','child_national_id','guardian_national_id',
                'guardian_id_document_url','kinship_document_url','created_at',
            ])
            ->each(function ($child) use ($requests) {
                $requests->push([
                    'id' => $this->encodeId((int) $child->id, 2),
                    'source_id' => $child->id,
                    'type' => 'children',
                    'name' => $child->name,
                    'email' => '',
                    'national_id' => $child->child_national_id,
                    'guardian_national_id' => $child->guardian_national_id,
                    'document_url' => $child->guardian_id_document_url,
                    'kinship_document_url' => $child->kinship_document_url,
                    'created_at' => $child->created_at,
                ]);
            });

        DB::table('certificates as c')
            ->join('users as u', 'u.id', '=', 'c.user_id')
            ->where('c.status', 'pending')
            ->orderByDesc('c.created_at')
            ->get(['c.id','c.title','c.url','c.created_at','u.name','u.email'])
            ->each(function ($certificate) use ($requests) {
                $requests->push([
                    'id' => $this->encodeId((int) $certificate->id, 3),
                    'source_id' => $certificate->id,
                    'type' => 'certificates',
                    'name' => $certificate->name,
                    'email' => $certificate->email,
                    'title' => $certificate->title,
                    'document_url' => $certificate->url,
                    'created_at' => $certificate->created_at,
                ]);
            });

        return response()->json([
            'requests' => $requests->sortByDesc('created_at')->values(),
        ]);
    }
}
