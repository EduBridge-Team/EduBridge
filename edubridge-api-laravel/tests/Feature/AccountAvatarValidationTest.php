<?php

namespace Tests\Feature;

use App\Http\Controllers\AccountController;
use Illuminate\Http\Request;
use Illuminate\Http\UploadedFile;
use Tests\TestCase;

class AccountAvatarValidationTest extends TestCase
{
    public function test_non_image_file_is_rejected_even_with_jpg_name(): void
    {
        $file = UploadedFile::fake()->createWithContent(
            'avatar.jpg',
            '<?php echo "not an image";'
        );

        $request = Request::create('/api/me/avatar', 'POST');
        $request->files->set('avatar', $file);
        $request->attributes->set('jwt_user', (object) ['id' => 1, 'role' => 'parent']);

        $response = app(AccountController::class)->uploadAvatar($request);

        $this->assertSame(422, $response->getStatusCode());
    }
}
