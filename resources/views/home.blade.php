@extends('layouts.app')

@section('title', 'Arkana Cards')

@section('content')
    <section class="hero">
        <h1>Catálogo digital de Arkana</h1>
        <p class="muted">
            Módulo web en Laravel para registrar cartas coleccionables, validar mazos y
            vincular cada carta física NFC con su identidad digital.
        </p>
        <div class="stats">
            <div class="stat">Cartas: <strong>{{ $cardsCount }}</strong></div>
            <div class="stat">Legendarias: <strong>{{ $legendaryCount }}</strong></div>
        </div>
        <p><a href="{{ route('cards.index') }}">Ver catálogo de cartas</a></p>
    </section>
@endsection
