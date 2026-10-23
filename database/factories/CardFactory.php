<?php

namespace Database\Factories;

use App\Models\Card;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Card>
 */
class CardFactory extends Factory
{
    protected $model = Card::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'name' => fake()->unique()->words(2, true),
            'rarity' => fake()->randomElement(Card::RARITIES),
            'attack' => fake()->numberBetween(1, 20),
            'defense' => fake()->numberBetween(1, 20),
            'nfc_uid' => strtoupper(bin2hex(random_bytes(4))),
            'description' => fake()->sentence(),
        ];
    }

    public function legendary(): static
    {
        return $this->state(fn (): array => [
            'rarity' => 'legendary',
            'attack' => 18,
            'defense' => 16,
        ]);
    }
}
