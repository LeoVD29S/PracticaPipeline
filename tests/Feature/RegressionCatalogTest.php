<?php

namespace Tests\Feature;

use App\Models\Card;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class RegressionCatalogTest extends TestCase
{
    use RefreshDatabase;

    public function test_existing_catalog_and_health_endpoints_keep_working(): void
    {
        Card::factory()->create(['name' => 'Carta de regresión']);

        $this->get('/')->assertOk()->assertSee('Arkana');
        $this->get('/up')->assertOk();
        $this->get(route('cards.index'))->assertOk()->assertSee('Carta de regresión');
        $this->getJson('/api/cards')->assertOk()->assertJsonPath('count', 1);
    }
}
