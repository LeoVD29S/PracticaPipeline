<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>@yield('title', 'Arkana Cards')</title>
    <style>
        :root {
            --bg: #0f172a;
            --panel: #1e293b;
            --line: #334155;
            --text: #e2e8f0;
            --muted: #94a3b8;
            --accent: #38bdf8;
            --gold: #fbbf24;
        }
        * { box-sizing: border-box; }
        body {
            margin: 0;
            font-family: Segoe UI, sans-serif;
            background: radial-gradient(circle at top, #1e293b, var(--bg));
            color: var(--text);
        }
        header, footer {
            max-width: 960px;
            margin: 0 auto;
            padding: 1.2rem 1.5rem;
        }
        header {
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        a { color: var(--accent); text-decoration: none; }
        .brand { font-weight: 700; letter-spacing: .04em; color: #fff; }
        main { max-width: 960px; margin: 0 auto; padding: 0 1.5rem 3rem; }
        .hero, .card, .grid-card {
            background: var(--panel);
            border: 1px solid var(--line);
            border-radius: 16px;
            padding: 1.25rem;
        }
        .hero h1 { margin: 0 0 .5rem; }
        .muted { color: var(--muted); }
        .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); gap: 1rem; }
        .badge { display: inline-block; padding: .2rem .55rem; border-radius: 999px; background: #0ea5e9; color: #fff; font-size: .75rem; text-transform: uppercase; }
        .badge.legendary { background: #b45309; }
        .badge.epic { background: #7c3aed; }
        .badge.rare { background: #2563eb; }
        .badge.common { background: #475569; }
        form { display: grid; gap: .7rem; margin-top: 1rem; }
        input, select, textarea, button {
            padding: .7rem .8rem;
            border-radius: 10px;
            border: 1px solid var(--line);
            background: #0b1220;
            color: var(--text);
        }
        button { background: var(--accent); color: #082f49; font-weight: 700; cursor: pointer; }
        .flash { background: #14532d; border: 1px solid #22c55e; padding: .8rem 1rem; border-radius: 10px; }
        .stats { display: flex; gap: 1rem; margin: 1rem 0; }
        .stat { background: #0b1220; padding: .8rem 1rem; border-radius: 12px; }
        .stat strong { color: var(--gold); }
    </style>
</head>
<body>
    <header>
        <a class="brand" href="{{ route('home') }}">ARKANA CARDS</a>
        <nav>
            <a href="{{ route('home') }}">Inicio</a>
            &nbsp;·&nbsp;
            <a href="{{ route('cards.index') }}">Catálogo</a>
        </nav>
    </header>
    <main>
        @if (session('status'))
            <p class="flash">{{ session('status') }}</p>
        @endif
        @yield('content')
    </main>
    <footer class="muted">Módulo Laravel para automatización de pruebas e integración continua.</footer>
</body>
</html>
