<?php

namespace Tests\Feature;

use Tests\TestCase;

class JabaliaTeacherDocumentHttpAuthenticationTest extends TestCase
{
    /**
     * Document metadata and binary endpoints must never be publicly accessible.
     * These requests deliberately carry no session or Authorization header.
     */
    public function test_anonymous_requests_cannot_access_teacher_document_endpoints(): void
    {
        $base = '/api/institutions/jabalia/schools/1/teachers/1/documents';

        foreach ([
            ['GET', $base],
            ['POST', $base],
            ['DELETE', $base.'/1'],
            ['POST', $base.'/1/file'],
            ['GET', $base.'/1/file'],
        ] as [$method, $uri]) {
            $response = $this->json($method, $uri);
            $this->assertContains($response->status(), [401, 403], $method.' '.$uri.' should require authentication');
        }
    }
}
