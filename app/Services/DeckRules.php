<?php

namespace App\Services;

use App\Models\Card;
use Illuminate\Support\Collection;

class DeckRules
{
    public const MAX_CARDS = 8;

    public const MAX_LEGENDARY = 2;

    /**
     * @param  Collection<int, Card>|array<int, Card>  $cards
     * @return array{valid: bool, errors: list<string>}
     */
    public function validate(Collection|array $cards): array
    {
        $cards = Collection::make($cards);
        $errors = [];

        if ($cards->count() > self::MAX_CARDS) {
            $errors[] = 'El mazo no puede superar '.self::MAX_CARDS.' cartas.';
        }

        $legendaryCount = $cards->filter(fn (Card $card) => $card->isLegendary())->count();

        if ($legendaryCount > self::MAX_LEGENDARY) {
            $errors[] = 'El mazo admite como máximo '.self::MAX_LEGENDARY.' cartas legendarias.';
        }

        $duplicateNfc = $cards
            ->pluck('nfc_uid')
            ->filter()
            ->duplicates()
            ->isNotEmpty();

        if ($duplicateNfc) {
            $errors[] = 'Cada carta física NFC debe ser única dentro del mazo.';
        }

        return [
            'valid' => $errors === [],
            'errors' => $errors,
        ];
    }
}
