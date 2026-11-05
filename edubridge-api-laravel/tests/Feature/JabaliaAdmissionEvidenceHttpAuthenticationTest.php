<?php

namespace Tests\Feature;

use Tests\TestCase;

class JabaliaAdmissionEvidenceHttpAuthenticationTest extends TestCase
{
    /**
     * Anonymous reads and writes of medical, audiology and identity records
     * must be denied before reaching protected controller methods.
     */
    public function test_anonymous_admission_document_endpoints_are_not_public(): void
    {
        foreach ([
            ['GET', '/api/parent/children/10/enrollment-requests/100/jabalia-documents'],
            ['POST', '/api/parent/children/10/enrollment-requests/100/jabalia-documents'],
            ['GET', '/api/parent/children/10/enrollment-requests/100/jabalia-documents/1/file'],
            ['GET', '/api/school/enrollment-requests/100/jabalia-documents'],
            ['GET', '/api/school/enrollment-requests/100/jabalia-documents/1/file'],
        ] as [$method, $uri]) {
            $response = $this->json($method, $uri);
            $this->assertContains($response->status(), [401, 403],
                $method.' '.$uri.' must require authentication');
        }
    }
}
