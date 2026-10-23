<?php

namespace Tests\Unit;

use App\Models\Card;
use PHPUnit\Framework\TestCase;

class CardTest extends TestCase
{
    public function test_power_score_sums_attack_and_defense(): void
    {
        $card = new Card([
            'attack' => 12,
            'defense' => 7,
        ]);

        $this->assertSame(19, $card->powerScore());
    }

    public function test_legendary_rarity_is_detected(): void
    {
        $card = new Card(['rarity' => 'legendary']);

        $this->assertTrue($card->isLegendary());
    }

    public function test_common_card_is_not_legendary(): void
    {
        $card = new Card(['rarity' => 'common']);

        $this->assertFalse($card->isLegendary());
    }

    public function test_nfc_uid_must_be_hexadecimal(): void
    {
        $valid = new Card(['nfc_uid' => 'A1B2C3D4']);
        $invalid = new Card(['nfc_uid' => 'nfc-invalido']);

        $this->assertTrue($valid->isValidNfcUid());
        $this->assertFalse($invalid->isValidNfcUid());
    }
}
