<?php

namespace Tests\Feature;

use App\Models\Card;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CardApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_api_lists_cards(): void
    {
        Card::factory()->count(2)->create();

        $response = $this->getJson('/api/cards');

        $response->assertOk();
        $response->assertJsonPath('count', 2);
        $response->assertJsonStructure(['data', 'count']);
    }

    public function test_api_creates_a_card(): void
    {
        $response = $this->postJson('/api/cards', [
            'name' => 'Centinela de Niebla',
            'rarity' => 'epic',
            'attack' => 14,
            'defense' => 12,
            'nfc_uid' => 'C3D4E5F6',
            'description' => 'Oculta el mazo aliado.',
        ]);

        $response->assertCreated();
        $this->assertDatabaseHas('cards', ['name' => 'Centinela de Niebla']);
    }

    public function test_api_validates_an_invalid_deck(): void
    {
        $legendaries = Card::factory()->legendary()->count(3)->create();

        $response = $this->postJson('/api/decks/validate', [
            'card_ids' => $legendaries->pluck('id')->all(),
        ]);

        $response->assertStatus(422);
        $response->assertJsonPath('valid', false);
    }

    public function test_api_accepts_a_valid_deck(): void
    {
        $cards = Card::factory()->count(3)->create(['rarity' => 'rare']);

        $response = $this->postJson('/api/decks/validate', [
            'card_ids' => $cards->pluck('id')->all(),
        ]);

        $response->assertOk();
        $response->assertJsonPath('valid', true);
    }
}
