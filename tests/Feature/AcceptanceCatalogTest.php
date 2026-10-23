<?php

namespace Tests\Feature;

use App\Models\Card;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AcceptanceCatalogTest extends TestCase
{
    use RefreshDatabase;

    public function test_acceptance_user_can_register_and_consult_a_physical_card(): void
    {
        $this->post(route('cards.store'), [
            'name' => 'Guardián de Obsidiana',
            'rarity' => 'legendary',
            'attack' => 18,
            'defense' => 16,
            'nfc_uid' => 'A1B2C3D4',
            'description' => 'Protege el núcleo del duelo.',
        ])->assertRedirect(route('cards.index'));

        $this->get(route('cards.index'))
            ->assertOk()
            ->assertSee('Guardián de Obsidiana')
            ->assertSee('A1B2C3D4');

        $card = Card::query()->firstOrFail();

        $this->get(route('cards.show', $card))
            ->assertOk()
            ->assertSee('Poder: 34')
            ->assertSee('Identidad NFC: A1B2C3D4');
    }
}
