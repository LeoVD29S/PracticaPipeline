<?php

namespace Tests\Unit;

use App\Models\Card;
use App\Services\DeckRules;
use PHPUnit\Framework\TestCase;

class DeckRulesTest extends TestCase
{
    public function test_valid_deck_is_accepted(): void
    {
        $rules = new DeckRules;
        $cards = [
            new Card(['rarity' => 'legendary', 'nfc_uid' => 'AAAAAAAA']),
            new Card(['rarity' => 'rare', 'nfc_uid' => 'BBBBBBBB']),
        ];

        $result = $rules->validate($cards);

        $this->assertTrue($result['valid']);
        $this->assertSame([], $result['errors']);
    }

    public function test_rejects_more_than_two_legendaries(): void
    {
        $rules = new DeckRules;
        $cards = [
            new Card(['rarity' => 'legendary', 'nfc_uid' => 'AAAAAAA1']),
            new Card(['rarity' => 'legendary', 'nfc_uid' => 'AAAAAAA2']),
            new Card(['rarity' => 'legendary', 'nfc_uid' => 'AAAAAAA3']),
        ];

        $result = $rules->validate($cards);

        $this->assertFalse($result['valid']);
        $this->assertNotEmpty($result['errors']);
    }

    public function test_rejects_deck_larger_than_eight_cards(): void
    {
        $rules = new DeckRules;
        $cards = [];

        for ($i = 0; $i < 9; $i++) {
            $cards[] = new Card([
                'rarity' => 'common',
                'nfc_uid' => sprintf('CARD%04d', $i),
            ]);
        }

        $result = $rules->validate($cards);

        $this->assertFalse($result['valid']);
    }

    public function test_rejects_duplicate_nfc_identifiers(): void
    {
        $rules = new DeckRules;
        $cards = [
            new Card(['rarity' => 'rare', 'nfc_uid' => 'SAMEUID1']),
            new Card(['rarity' => 'epic', 'nfc_uid' => 'SAMEUID1']),
        ];

        $result = $rules->validate($cards);

        $this->assertFalse($result['valid']);
    }
}
