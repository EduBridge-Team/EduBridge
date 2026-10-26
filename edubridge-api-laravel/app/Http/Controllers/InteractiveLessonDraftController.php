<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class InteractiveLessonDraftController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $actor = $request->attributes->get('jwt_user');
        if (!$actor || !in_array($actor->role, ['teacher', 'specialist'], true)) {
            return response()->json(['error' => 'Forbidden'], 403);
        }
        $rows = DB::table('interactive_lesson_drafts')
            ->where('author_id', $actor->id)
            ->orderByDesc('updated_at')->limit(100)->get();
        return response()->json(['drafts' => $rows]);
    }

    public function store(Request $request): JsonResponse
    {
        $actor = $request->attributes->get('jwt_user');
        if (!$actor || !in_array($actor->role, ['teacher', 'specialist'], true)) {
            return response()->json(['error' => 'Forbidden'], 403);
        }
        $data = Validator::make($request->all(), [
            'template_id' => ['required', 'string', 'max:100', 'regex:/^[a-zA-Z0-9_-]+$/'],
            'title' => ['required', 'string', 'max:120'],
            'objective' => ['required', 'string', 'max:500'],
        ]);
        if ($data->fails()) return response()->json(['errors' => $data->errors()], 422);
        $values = $data->validated();
        $values['title'] = trim($values['title']);
        $values['objective'] = trim($values['objective']);
        if ($values['title'] === '' || $values['objective'] === '') {
            return response()->json(['error' => 'Title and objective required'], 422);
        }
        $id = DB::table('interactive_lesson_drafts')->insertGetId([
            'author_id' => $actor->id,
            'template_id' => $values['template_id'],
            'title' => $values['title'], 'objective' => $values['objective'],
            'version' => 1, 'created_at' => now(), 'updated_at' => now(),
        ]);
        return response()->json(['draft' => DB::table('interactive_lesson_drafts')
            ->where('id', $id)->where('author_id', $actor->id)->first()], 201);
    }

    public function update(Request $request, int $draft): JsonResponse
    {
        $actor = $request->attributes->get('jwt_user');
        if (!$actor || !in_array($actor->role, ['teacher', 'specialist'], true)) {
            return response()->json(['error' => 'Forbidden'], 403);
        }
        $validator = Validator::make($request->all(), [
            'expected_version' => ['required', 'integer', 'min:1'],
            'title' => ['required', 'string', 'max:120'],
            'objective' => ['required', 'string', 'max:500'],
        ]);
        if ($validator->fails()) return response()->json(['errors' => $validator->errors()], 422);
        $data = $validator->validated();
        $title = trim($data['title']); $objective = trim($data['objective']);
        if ($title === '' || $objective === '') return response()->json(['error' => 'Empty fields'], 422);

        return DB::transaction(function () use ($actor, $draft, $data, $title, $objective) {
            $row = DB::table('interactive_lesson_drafts')
                ->where('id', $draft)->where('author_id', $actor->id)
                ->lockForUpdate()->first();
            if (!$row) return response()->json(['error' => 'Draft unavailable'], 404);
            if ((int) $row->version !== (int) $data['expected_version']) {
                return response()->json(['error' => 'Draft state changed'], 409);
            }
            DB::table('interactive_lesson_drafts')->where('id', $draft)
                ->where('author_id', $actor->id)->update([
                    'title' => $title, 'objective' => $objective,
                    'version' => $row->version + 1, 'updated_at' => now(),
                ]);
            return response()->json(['draft' => DB::table('interactive_lesson_drafts')
                ->where('id', $draft)->where('author_id', $actor->id)->first()]);
        });
    }
}
