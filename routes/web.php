<?php

use App\Http\Controllers\CardController;
use App\Models\Card;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('home', [
        'cardsCount' => Card::query()->count(),
        'legendaryCount' => Card::query()->where('rarity', 'legendary')->count(),
    ]);
})->name('home');

Route::get('/cartas', [CardController::class, 'index'])->name('cards.index');
Route::get('/cartas/{card}', [CardController::class, 'show'])->name('cards.show');
Route::post('/cartas', [CardController::class, 'store'])->name('cards.store');
