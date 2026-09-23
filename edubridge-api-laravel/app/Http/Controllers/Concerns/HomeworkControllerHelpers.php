<?php

namespace App\Http\Controllers\Concerns;

use App\Support\R2Storage;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

trait HomeworkControllerHelpers
{
    private function homeworkQuery()
    {
        return DB::table('homeworks as h')
            ->join('users as t', 't.id', '=', 'h.teacher_id')
            ->select('h.*', 't.name as teacher_name')
            ->orderByDesc('h.created_at');
    }
    
    private function normalize($row, ?array $visibleChildIds = null): array
    {
        $data = (array) $row;
    
        foreach (['assigned_child_ids', 'attachment_urls'] as $field) {
            $value = $data[$field] ?? [];
            if (is_string($value)) {
                $decoded = json_decode($value, true);
                $value = is_array($decoded) ? $decoded : [];
            }
            $data[$field] = array_values(is_array($value) ? $value : []);
        }
    
        $submissions = DB::table('homework_submissions as hs')
            ->join('children as c', 'c.id', '=', 'hs.child_id')
            ->where('hs.homework_id', $data['id'])
            ->when($visibleChildIds !== null, fn ($query) => $query->whereIn('hs.child_id', $visibleChildIds))
            ->orderByDesc('hs.submitted_at')
            ->select('hs.*', 'c.name as child_name')
            ->get()
            ->map(function ($s) {
                $item = (array) $s;
                $urls = $item['file_urls'] ?? [];
                if (is_string($urls)) {
                    $decoded = json_decode($urls, true);
                    $urls = is_array($decoded) ? $decoded : [];
                }
                $item['file_urls'] = array_values(is_array($urls) ? $urls : []);
                $item['file_url'] = $item['file_url'] ?? ($item['file_urls'][0] ?? null);
                $item['is_late'] = (bool) ($item['is_late'] ?? false);
                return $item;
            })
            ->values()
            ->all();
    
        $data['submissions'] = $submissions;
        return $data;
    }
    
    private function canViewChild($user, int $childId): bool
    {
        if (!$user) return false;
        if ($user->role === 'admin') return true;
        if ($user->role === 'specialist') {
            return DB::table('child_specialist')
                ->where('child_id', $childId)
                ->where('specialist_id', $user->id)
                ->exists();
        }
        if ($user->role === 'teacher') {
            return DB::table('children')
                ->where('id', $childId)
                ->where('assigned_teacher_id', $user->id)
                ->exists()
                || DB::table('child_teacher')
                    ->where('child_id', $childId)
                    ->where('teacher_id', $user->id)
                    ->exists();
        }
    
        return $user->role === 'parent'
            && DB::table('child_parent')
                ->where('child_id', $childId)
                ->where('parent_id', $user->id)
                ->exists();
    }
    
    private function storeFiles(Request $request, string $field, string $prefix): array
    {
        $files = $request->file($field, []);
        if (!is_array($files)) {
            $files = [$files];
        }
    
        $urls = [];
        foreach ($files as $file) {
            if (!$file || !$file->isValid()) continue;
    
            $ext = strtolower($file->getClientOriginalExtension());
            if (!in_array($ext, self::ALLOWED_EXTENSIONS, true)) {
                throw new \RuntimeException('صيغة ملف غير مسموحة');
            }
            if ($file->getSize() > self::MAX_BYTES) {
                throw new \RuntimeException('حجم الملف يتجاوز 10 ميغابايت');
            }
    
            $name = $prefix . '_' . date('Ymd_His') . '_' . bin2hex(random_bytes(5)) . '.' . $ext;
            $key = 'homework/' . $name;
    
            R2Storage::putUploadedFile(
                R2Storage::mediaBucket(),
                $key,
                $file,
                (string) $file->getMimeType()
            );
            $urls[] = R2Storage::mediaPublicUrl($key);
        }
    
        return $urls;
    }
    
}
