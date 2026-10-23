<?php

namespace Database\Seeders;

use App\Models\Card;
use App\Models\User;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        User::factory()->create([
            'name' => 'Leonardo Villaseñor',
            'email' => 'leonardo@arkana.test',
        ]);

        $catalog = [
            ['name' => 'Guardián de Obsidiana', 'rarity' => 'legendary', 'attack' => 18, 'defense' => 16, 'nfc_uid' => 'A1B2C3D4', 'description' => 'Protege el núcleo del duelo.'],
            ['name' => 'Halcón de Cobre', 'rarity' => 'rare', 'attack' => 11, 'defense' => 8, 'nfc_uid' => 'B2C3D4E5', 'description' => 'Ataque rápido de flanco.'],
            ['name' => 'Centinela de Niebla', 'rarity' => 'epic', 'attack' => 14, 'defense' => 12, 'nfc_uid' => 'C3D4E5F6', 'description' => 'Oculta el mazo aliado.'],
            ['name' => 'Runa Menor', 'rarity' => 'common', 'attack' => 4, 'defense' => 6, 'nfc_uid' => 'D4E5F607', 'description' => 'Carta base de invocación.'],
        ];

        foreach ($catalog as $card) {
            Card::query()->create($card);
        }
    }
}
