<?php

namespace App\Support;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\URL;

final class LessonFiles
{
    public static function validFilename(string $name): bool
    {
        return (bool) preg_match('/^[A-Za-z0-9._-]+$/', $name) && !str_contains($name, '..');
    }

    public static function path(int $lessonId, string $name): string
    {
        return "/api/private-files/lesson/{$lessonId}/{$name}";
    }

    public static function key(string $url): ?string
    {
        if (preg_match('#^/api/private-files/lesson/(\d+)/([A-Za-z0-9._-]+)$#', $url, $m)
            && self::validFilename($m[2])) {
            return "lessons/{$m[1]}/{$m[2]}";
        }
        return null;
    }

    public static function delete(string $url): void
    {
        if (\Illuminate\Support\Facades\DB::table('media')->where('url', $url)->exists()) return;
        if ($key = self::key($url)) {
            R2Storage::delete(R2Storage::privateBucket(), $key);
        } elseif ($key = PrivateFileMigration::publicKey($url)) {
            if (str_starts_with($key, 'lessons/')) R2Storage::delete(R2Storage::mediaBucket(), $key);
        }
    }

    public static function forViewer(Request $request, ?string $url): ?string
    {
        if (!$url) return null;
        if ($key = self::key($url)) {
            [, $id, $name] = explode('/', $key);
            $account = $request->attributes->get('jwt_user');
            if (!$account) return null;
            $signed = URL::temporarySignedRoute('lesson.file', now()->addMinutes(15), [
                'lessonId' => $id, 'filename' => $name, 'viewer' => $account->id,
                'role' => $account->role,
                'credential' => AuthCredentials::stamp($account, (string) config('services.jwt.secret')),
            ], absolute: false);
            $origin = $request->getSchemeAndHttpHost();
            $configured = rtrim((string) config('app.url'), '/');
            if (parse_url($configured, PHP_URL_HOST) === $request->getHost()
                && parse_url($configured, PHP_URL_SCHEME) === 'https') $origin = $configured;
            return rtrim($origin, '/') . $signed;
        }
        return preg_match('/^https?:\/\//i', $url) ? $url
            : rtrim($request->getSchemeAndHttpHost(), '/') . '/' . ltrim($url, '/');
    }
}
