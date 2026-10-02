<?php

namespace Tests\Concerns;

use GuzzleHttp\Client;
use GuzzleHttp\Handler\MockHandler;
use GuzzleHttp\HandlerStack;
use GuzzleHttp\Middleware;

trait MocksPrivateR2
{
    private array $r2History = [];
    private array $r2Env = [];

    private function configureR2(): void
    {
        foreach (['AWS_ENDPOINT' => 'https://r2.example.test', 'AWS_ACCESS_KEY_ID' => 'key', 'AWS_SECRET_ACCESS_KEY' => 'secret',
            'R2_PRIVATE_BUCKET' => 'private', 'R2_MEDIA_BUCKET' => 'public', 'R2_MEDIA_PUBLIC_URL' => 'https://media.example.test'] as $key => $value) {
            $this->r2Env[$key] = [$_ENV[$key] ?? null, $_SERVER[$key] ?? null];
            $_ENV[$key] = $_SERVER[$key] = $value;
        }
    }

    private function restoreR2(): void
    {
        foreach ($this->r2Env as $key => [$env, $server]) {
            if ($env === null) unset($_ENV[$key]); else $_ENV[$key] = $env;
            if ($server === null) unset($_SERVER[$key]); else $_SERVER[$key] = $server;
        }
    }

    private function mockR2(array $responses): void
    {
        $stack = HandlerStack::create(new MockHandler($responses));
        $stack->push(Middleware::history($this->r2History));
        $this->app->instance(Client::class, new Client(['handler' => $stack]));
    }
}
