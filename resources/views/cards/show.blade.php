@extends('layouts.app')

@section('title', $card->name)

@section('content')
    <article class="card">
        <span class="badge {{ $card->rarity }}">{{ $card->rarity }}</span>
        <h1>{{ $card->name }}</h1>
        <p>{{ $card->description }}</p>
        <p>Ataque: {{ $card->attack }} · Defensa: {{ $card->defense }} · Poder: {{ $card->powerScore() }}</p>
        <p class="muted">Identidad NFC: {{ $card->nfc_uid }}</p>
        <p><a href="{{ route('cards.index') }}">Volver al catálogo</a></p>
    </article>
@endsection
