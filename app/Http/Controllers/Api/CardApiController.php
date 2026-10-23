<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Card;
use App\Services\DeckRules;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CardApiController extends Controller
{
    public function index(): JsonResponse
    {
        /** @var \Illuminate\Database\Eloquent\Collection<int, Card> $cards */
        $cards = Card::query()->orderBy('name')->get();

        $payload = [];
        foreach ($cards as $card) {
            $payload[] = [
                'id' => $card->id,
                'name' => $card->name,
                'rarity' => $card->rarity,
                'attack' => $card->attack,
                'defense' => $card->defense,
                'power' => $card->powerScore(),
                'nfc_uid' => $card->nfc_uid,
            ];
        }

        return response()->json([
            'data' => $payload,
            'count' => count($payload),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:80'],
            'rarity' => ['required', 'in:'.implode(',', Card::RARITIES)],
            'attack' => ['required', 'integer', 'min:0', 'max:99'],
            'defense' => ['required', 'integer', 'min:0', 'max:99'],
            'nfc_uid' => ['required', 'string', 'regex:/^[A-F0-9]{8,16}$/', 'unique:cards,nfc_uid'],
            'description' => ['nullable', 'string', 'max:255'],
        ]);

        $card = Card::query()->create($data);

        return response()->json([
            'message' => 'Carta creada',
            'data' => $card,
        ], 201);
    }

    public function validateDeck(Request $request, DeckRules $rules): JsonResponse
    {
        $payload = $request->validate([
            'card_ids' => ['required', 'array', 'min:1'],
            'card_ids.*' => ['integer', 'exists:cards,id'],
        ]);

        /** @var \Illuminate\Database\Eloquent\Collection<int, Card> $cards */
        $cards = Card::query()->whereIn('id', $payload['card_ids'])->get();
        $result = $rules->validate($cards);

        return response()->json($result, $result['valid'] ? 200 : 422);
    }
}
