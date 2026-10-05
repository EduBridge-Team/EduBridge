<?php

namespace App\Providers;

use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Str;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        RateLimiter::for('lesson-ratings', function (Request $request) {
            $user = $request->attributes->get('jwt_user');

            return Limit::perMinute(10)
                ->by($user ? 'user:' . $user->id : 'ip:' . $request->ip());
        });

        RateLimiter::for('auth-login', function (Request $request) {
            $email = Str::lower(trim((string) $request->input('email', 'unknown')));
            $ip = $request->ip();

            return [
                Limit::perMinute(10)->by('login-ip:' . $ip),
                Limit::perMinute(5)->by('login-identity:' . hash('sha256', $email . '|' . $ip)),
                Limit::perHour(30)->by('login-account:' . hash('sha256', $email)),
            ];
        });

        RateLimiter::for('auth-register', function (Request $request) {
            return [
                Limit::perMinute(5)->by('register-ip:' . $request->ip()),
                Limit::perHour(20)->by('register-hourly-ip:' . $request->ip()),
            ];
        });

        RateLimiter::for('auth-recovery', function (Request $request) {
            $email = Str::lower(trim((string) $request->input('email', 'unknown')));

            return [
                Limit::perMinute(3)->by('recovery-ip:' . $request->ip()),
                Limit::perHour(10)->by('recovery-account:' . hash('sha256', $email)),
            ];
        });
    }
}
