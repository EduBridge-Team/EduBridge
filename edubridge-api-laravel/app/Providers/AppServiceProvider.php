<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;

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
        \Illuminate\Support\Facades\RateLimiter::for('lesson-ratings', function (\Illuminate\Http\Request $request) {
            $user = $request->attributes->get('jwt_user');
            return \Illuminate\Cache\RateLimiting\Limit::perMinute(10)
                ->by($user ? 'user:' . $user->id : 'ip:' . $request->ip());
        });
    }
}
