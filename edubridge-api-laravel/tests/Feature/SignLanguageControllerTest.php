<?php

namespace Tests\Feature;

use App\Http\Controllers\SignLanguageController;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class SignLanguageControllerTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        Schema::create('sign_languages', function (Blueprint $table) {
            $table->id();
            $table->string('code')->unique();
            $table->string('name_ar');
            $table->string('name_en');
            $table->string('region')->nullable();
            $table->string('source_name')->nullable();
            $table->text('source_url')->nullable();
            $table->string('license')->nullable();
            $table->json('metadata')->nullable();
            $table->timestamps();
        });

        Schema::create('sign_entries', function (Blueprint $table) {
            $table->id();
            $table->integer('sign_language_id');
            $table->integer('external_label_id')->nullable();
            $table->string('category');
            $table->string('arabic_label');
            $table->string('english_label');
            $table->string('canonical_label');
            $table->string('source_video_name')->nullable();
            $table->text('media_url')->nullable();
            $table->text('thumbnail_url')->nullable();
            $table->integer('frame_count')->nullable();
            $table->integer('duration_ms')->nullable();
            $table->string('review_status');
            $table->text('review_notes')->nullable();
            $table->json('metadata')->nullable();
            $table->timestamps();
        });

        DB::table('sign_languages')->insert([
            'id' => 1,
            'code' => 'psl',
            'name_ar' => 'لغة الإشارة الفلسطينية',
            'name_en' => 'Palestinian Sign Language',
            'region' => 'Palestine',
            'source_name' => 'fidaakh/STEM_data',
            'source_url' => 'https://huggingface.co/datasets/fidaakh/STEM_data',
            'license' => 'Apache-2.0',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::table('sign_entries')->insert([
            [
                'id' => 1, 'sign_language_id' => 1, 'external_label_id' => 29, 'category' => 'math',
                'arabic_label' => 'مثلث', 'english_label' => 'Triangle', 'canonical_label' => 'Triangle@مثلث',
                'duration_ms' => 3440, 'review_status' => 'verified', 'created_at' => now(), 'updated_at' => now(),
            ],
            [
                'id' => 2, 'sign_language_id' => 1, 'external_label_id' => 49, 'category' => 'science',
                'arabic_label' => 'شريان', 'english_label' => 'Veins', 'canonical_label' => 'Veins@شريان',
                'duration_ms' => 3160, 'review_status' => 'needs_review', 'created_at' => now(), 'updated_at' => now(),
            ],
        ]);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('sign_entries');
        Schema::dropIfExists('sign_languages');
        parent::tearDown();
    }

    public function test_public_list_hides_unverified_entries_and_searches_arabic(): void
    {
        $request = Request::create('/api/sign-language/signs', 'GET', ['q' => 'مثلث']);
        $request->attributes->set('jwt_user', (object) ['id' => 10, 'role' => 'parent']);

        $response = app(SignLanguageController::class)->index($request);
        $data = $response->getData(true);

        $this->assertSame(200, $response->getStatusCode());
        $this->assertSame(1, $data['pagination']['total']);
        $this->assertSame('مثلث', $data['signs'][0]['arabic_label']);
    }

    public function test_admin_can_explicitly_include_review_queue(): void
    {
        $request = Request::create('/api/sign-language/signs', 'GET', ['include_review' => 1]);
        $request->attributes->set('jwt_user', (object) ['id' => 1, 'role' => 'admin']);

        $data = app(SignLanguageController::class)->index($request)->getData(true);

        $this->assertSame(2, $data['pagination']['total']);
        $this->assertSame(['verified', 'needs_review'], array_column($data['signs'], 'review_status'));
    }

    public function test_non_admin_cannot_fetch_unverified_sign(): void
    {
        $request = Request::create('/api/sign-language/signs/2', 'GET', ['include_review' => 1]);
        $request->attributes->set('jwt_user', (object) ['id' => 10, 'role' => 'parent']);

        $response = app(SignLanguageController::class)->show($request, 2);

        $this->assertSame(404, $response->getStatusCode());
    }
}
