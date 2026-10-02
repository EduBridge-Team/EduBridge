<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('sign_languages')) {
            Schema::create('sign_languages', function (Blueprint $table) {
                $table->id();
                $table->string('code', 16)->unique();
                $table->string('name_ar', 120);
                $table->string('name_en', 120);
                $table->string('region', 120)->nullable();
                $table->string('source_name', 255)->nullable();
                $table->text('source_url')->nullable();
                $table->string('license', 64)->nullable();
                $table->json('metadata')->nullable();
                $table->timestamps();
            });
        }

        if (!Schema::hasTable('sign_entries')) {
            Schema::create('sign_entries', function (Blueprint $table) {
                $table->id();
                $table->foreignId('sign_language_id')->constrained('sign_languages')->cascadeOnDelete();
                $table->unsignedInteger('external_label_id')->nullable();
                $table->string('category', 80)->index();
                $table->string('arabic_label', 255)->index();
                $table->string('english_label', 255)->index();
                $table->string('canonical_label', 520);
                $table->string('source_video_name', 520)->nullable();
                $table->text('media_url')->nullable();
                $table->text('thumbnail_url')->nullable();
                $table->unsignedInteger('frame_count')->nullable();
                $table->unsignedInteger('duration_ms')->nullable();
                $table->string('review_status', 32)->default('verified')->index();
                $table->text('review_notes')->nullable();
                $table->json('metadata')->nullable();
                $table->timestamps();

                $table->unique(['sign_language_id', 'external_label_id'], 'sign_entries_language_external_unique');
            });
        }

        $languageId = DB::table('sign_languages')
            ->where('code', 'psl')
            ->value('id');

        if (!$languageId) {
            $languageId = DB::table('sign_languages')->insertGetId([
                'code' => 'psl',
                'name_ar' => 'لغة الإشارة الفلسطينية',
                'name_en' => 'Palestinian Sign Language',
                'region' => 'Palestine',
                'source_name' => 'fidaakh/STEM_data',
                'source_url' => 'https://huggingface.co/datasets/fidaakh/STEM_data',
                'license' => 'Apache-2.0',
                'metadata' => json_encode([
                    'scope' => 'STEM',
                    'media_included' => false,
                    'note' => 'Public repository currently contains metadata only; media URLs remain nullable until original videos are obtained.',
                ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        $path = database_path('data/psl_stem_labels.json');
        if (!is_file($path)) {
            throw new RuntimeException('Missing PSL seed data: '.$path);
        }

        $payload = json_decode(file_get_contents($path), true, flags: JSON_THROW_ON_ERROR);
        $now = now();

        foreach ($payload['labels'] ?? [] as $entry) {
            DB::table('sign_entries')->updateOrInsert(
                [
                    'sign_language_id' => $languageId,
                    'external_label_id' => $entry['external_label_id'],
                ],
                [
                    'category' => $entry['category'],
                    'arabic_label' => $entry['arabic_label'],
                    'english_label' => $entry['english_label'],
                    'canonical_label' => $entry['canonical_label'],
                    'source_video_name' => $entry['source_video_name'] ?? null,
                    'frame_count' => $entry['frame_count'] ?? null,
                    'duration_ms' => $entry['duration_ms'] ?? null,
                    'review_status' => $entry['review_status'] ?? 'verified',
                    'review_notes' => $entry['review_notes'] ?? null,
                    'metadata' => json_encode([
                        'dataset' => $payload['dataset'] ?? null,
                        'license' => $payload['license'] ?? null,
                    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
                    'updated_at' => $now,
                    'created_at' => $now,
                ]
            );
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('sign_entries');
        Schema::dropIfExists('sign_languages');
    }
};
