@extends('layouts.app')

@section('title', 'Catálogo de cartas')

@section('content')
    <section class="hero">
        <h1>Catálogo de cartas</h1>
        <p class="muted">Poder acumulado del inventario: {{ $totalPower }}</p>
    </section>

    <div class="grid" style="margin-top: 1.2rem;">
        @forelse ($cards as $card)
            <article class="grid-card">
                <span class="badge {{ $card->rarity }}">{{ $card->rarity }}</span>
                <h3><a href="{{ route('cards.show', $card) }}">{{ $card->name }}</a></h3>
                <p>ATK {{ $card->attack }} · DEF {{ $card->defense }} · Poder {{ $card->powerScore() }}</p>
                <p class="muted">NFC {{ $card->nfc_uid }}</p>
            </article>
        @empty
            <p class="muted">Aún no hay cartas registradas.</p>
        @endforelse
    </div>

    <section class="card" style="margin-top: 2rem;">
        <h2>Registrar carta</h2>
        <form method="POST" action="{{ route('cards.store') }}">
            @csrf
            <input name="name" placeholder="Nombre" value="{{ old('name') }}" required>
            <select name="rarity" required>
                @foreach (['common', 'rare', 'epic', 'legendary'] as $rarity)
                    <option value="{{ $rarity }}" @selected(old('rarity') === $rarity)>{{ $rarity }}</option>
                @endforeach
            </select>
            <input name="attack" type="number" min="0" max="99" placeholder="Ataque" value="{{ old('attack') }}" required>
            <input name="defense" type="number" min="0" max="99" placeholder="Defensa" value="{{ old('defense') }}" required>
            <input name="nfc_uid" placeholder="UID NFC (hex 8-16)" value="{{ old('nfc_uid') }}" required>
            <textarea name="description" placeholder="Descripción">{{ old('description') }}</textarea>
            <button type="submit">Guardar carta</button>
        </form>
        @if ($errors->any())
            <ul>
                @foreach ($errors->all() as $error)
                    <li class="muted">{{ $error }}</li>
                @endforeach
            </ul>
        @endif
    </section>
@endsection
