<?php

namespace Tests\Feature;

use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class InstitutionContextTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        Schema::create('organizations', function (Blueprint $table) {
            $table->id();
            $table->string('name', 150);
            $table->string('contact', 150)->nullable();
            $table->string('address', 255)->nullable();
            $table->string('slug', 80)->nullable()->unique();
            $table->string('domain', 190)->nullable()->unique();
            $table->string('logo_url', 2048)->nullable();
            $table->string('primary_color', 20)->nullable();
            $table->string('secondary_color', 20)->nullable();
            $table->json('settings')->default('{}');
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('organizations');
        parent::tearDown();
    }

    public function test_public_context_returns_safe_branding_only(): void
    {
        DB::table('organizations')->insert([
            'name' => 'جمعية جباليا للتأهيل',
            'slug' => 'jabalia',
            'domain' => 'jabalia.edubridge.win',
            'settings' => json_encode([
                'display_name' => 'جمعية جباليا للتأهيل',
                'locale' => 'ar',
                'features' => ['attendance' => true, 'noor' => true],
                'private_note' => 'must-not-leak',
            ]),
            'is_active' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $this->getJson('/api/institutions/jabalia/context')
            ->assertOk()
            ->assertJsonPath('organization.slug', 'jabalia')
            ->assertJsonMissing(['private_note' => 'must-not-leak']);
    }

    public function test_inactive_tenant_is_hidden(): void
    {
        DB::table('organizations')->insert([
            'name' => 'Inactive',
            'slug' => 'inactive',
            'is_active' => false,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $this->getJson('/api/institutions/inactive/context')->assertNotFound();
    }
}
