<?php

namespace App\Http\Controllers;

use App\Models\Card;
use Illuminate\Contracts\View\View;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;

class CardController extends Controller
{
    public function index(): View
    {
        /** @var \Illuminate\Database\Eloquent\Collection<int, Card> $cards */
        $cards = Card::query()->orderBy('name')->get();

        $totalPower = 0;
        foreach ($cards as $card) {
            $totalPower += $card->powerScore();
        }

        return view('cards.index', [
            'cards' => $cards,
            'totalPower' => $totalPower,
        ]);
    }

    public function show(Card $card): View
    {
        return view('cards.show', compact('card'));
    }

    public function store(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:80'],
            'rarity' => ['required', 'in:'.implode(',', Card::RARITIES)],
            'attack' => ['required', 'integer', 'min:0', 'max:99'],
            'defense' => ['required', 'integer', 'min:0', 'max:99'],
            'nfc_uid' => ['required', 'string', 'regex:/^[A-F0-9]{8,16}$/', 'unique:cards,nfc_uid'],
            'description' => ['nullable', 'string', 'max:255'],
        ]);

        Card::query()->create($data);

        return redirect()
            ->route('cards.index')
            ->with('status', 'Carta registrada en el catálogo digital.');
    }
}
