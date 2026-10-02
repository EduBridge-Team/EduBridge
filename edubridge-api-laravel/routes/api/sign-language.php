<?php

use Illuminate\Support\Facades\Route;

Route::get('/sign-language', [\App\Http\Controllers\SignLanguageController::class, 'language']);
Route::get('/sign-language/categories', [\App\Http\Controllers\SignLanguageController::class, 'categories']);
Route::get('/sign-language/signs', [\App\Http\Controllers\SignLanguageController::class, 'index']);
Route::get('/sign-language/signs/{id}', [\App\Http\Controllers\SignLanguageController::class, 'show'])
    ->whereNumber('id');
