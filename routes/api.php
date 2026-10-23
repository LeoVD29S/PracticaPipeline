<?php

use App\Http\Controllers\Api\CardApiController;
use Illuminate\Support\Facades\Route;

Route::get('/cards', [CardApiController::class, 'index']);
Route::post('/cards', [CardApiController::class, 'store']);
Route::post('/decks/validate', [CardApiController::class, 'validateDeck']);
