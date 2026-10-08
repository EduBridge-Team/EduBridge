<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('organizations', function (Blueprint $table) {
            $table->string('slug', 80)->nullable()->unique();
            $table->string('domain', 190)->nullable()->unique();
            $table->string('logo_url', 2048)->nullable();
            $table->string('primary_color', 20)->nullable();
            $table->string('secondary_color', 20)->nullable();
            $table->json('settings')->default('{}');
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('organization_user', function (Blueprint $table) {
            $table->id();
            $table->foreignId('organization_id')->constrained('organizations')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('role', 40)->default('member');
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->unique(['organization_id', 'user_id']);
            $table->index(['organization_id', 'role']);
        });

        Schema::create('schools', function (Blueprint $table) {
            $table->id();
            $table->foreignId('organization_id')->constrained('organizations')->cascadeOnDelete();
            $table->string('name', 150);
            $table->string('slug', 80);
            $table->string('address', 255)->nullable();
            $table->string('phone', 30)->nullable();
            $table->string('email', 190)->nullable();
            $table->json('settings')->default('{}');
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->unique(['organization_id', 'slug']);
            $table->index(['organization_id', 'is_active']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('schools');
        Schema::dropIfExists('organization_user');

        Schema::table('organizations', function (Blueprint $table) {
            $table->dropColumn([
                'slug', 'domain', 'logo_url', 'primary_color', 'secondary_color',
                'settings', 'is_active', 'created_at', 'updated_at',
            ]);
        });
    }
};
