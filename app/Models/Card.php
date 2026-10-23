<?php

namespace App\Models;

use Database\Factories\CardFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

/**
 * @property int $id
 * @property string $name
 * @property string $rarity
 * @property int $attack
 * @property int $defense
 * @property string $nfc_uid
 * @property string|null $description
 */
class Card extends Model
{
    /** @use HasFactory<CardFactory> */
    use HasFactory;

    /**
     * @var list<string>
     */
    public const RARITIES = ['common', 'rare', 'epic', 'legendary'];

    /**
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'rarity',
        'attack',
        'defense',
        'nfc_uid',
        'description',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'attack' => 'integer',
            'defense' => 'integer',
        ];
    }

    public function powerScore(): int
    {
        return $this->attack + $this->defense;
    }

    public function isLegendary(): bool
    {
        return $this->rarity === 'legendary';
    }

    public function isValidNfcUid(): bool
    {
        return (bool) preg_match('/^[A-F0-9]{8,16}$/', (string) $this->nfc_uid);
    }
}
