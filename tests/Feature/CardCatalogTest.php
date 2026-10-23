<?php

namespace Tests\Feature;

use App\Models\Card;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CardCatalogTest extends TestCase
{
    use RefreshDatabase;

    public function test_catalog_lists_existing_cards(): void
    {
        Card::factory()->create([
            'name' => 'Guardián de Obsidiana',
            'rarity' => 'legendary',
        ]);

        $response = $this->get(route('cards.index'));

        $response->assertOk();
        $response->assertSee('Guardián de Obsidiana');
        $response->assertSee('legendary');
    }

    public function test_card_detail_page_shows_power_score(): void
    {
        $card = Card::factory()->create([
            'name' => 'Halcón de Cobre',
            'attack' => 10,
            'defense' => 5,
        ]);

        $response = $this->get(route('cards.show', $card));

        $response->assertOk();
        $response->assertSee('Halcón de Cobre');
        $response->assertSee('Poder: 15');
    }

    public function test_a_card_can_be_registered_from_the_catalog(): void
    {
        $response = $this->post(route('cards.store'), [
            'name' => 'Runa Menor',
            'rarity' => 'common',
            'attack' => 4,
            'defense' => 6,
            'nfc_uid' => 'D4E5F607',
            'description' => 'Carta base',
        ]);

        $response->assertRedirect(route('cards.index'));
        $this->assertDatabaseHas('cards', [
            'name' => 'Runa Menor',
            'nfc_uid' => 'D4E5F607',
        ]);
    }

    public function test_invalid_nfc_uid_is_rejected(): void
    {
        $response = $this->from(route('cards.index'))->post(route('cards.store'), [
            'name' => 'Carta inválida',
            'rarity' => 'common',
            'attack' => 1,
            'defense' => 1,
            'nfc_uid' => 'uid malo',
        ]);

        $response->assertRedirect(route('cards.index'));
        $response->assertSessionHasErrors('nfc_uid');
        $this->assertDatabaseCount('cards', 0);
    }
}
