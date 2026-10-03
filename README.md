# JakWypiję 🍺📍

**HackYeah 2026 · Open Task: Smart City**

Aplikacja mobilna (Flutter), która pomaga zaplanować wieczór na mieście tak, żeby
był lepszy **dla Ciebie i dla miasta**: odkrywasz mniej znane bary poza zatłoczonym
centrum, układasz trasę na mapie („Barobranie”) i bezpiecznie wracasz komunikacją nocną.

> Wszystkie nazwy barów i osoby są fikcyjne. Dane o tłoku i rozkładach MPK są
> przykładowe (demo) – patrz „Dane i ograniczenia”.

## Problem

Piątek, 21:30, Kazimierz. Ulice pełne, w ulubionym barze brak miejsc, mieszkańcy
skarżą się na hałas, a o 1:00 nie wiadomo, czym wrócić do domu. Tymczasem kilkaset
metrów dalej – w Podgórzu, na Zabłociu, w Dębnikach – stoją puste, świetne lokale.

**Użytkownicy:** mieszkańcy i studenci planujący wieczór ze znajomymi, turyści,
osoby z niepełnosprawnościami szukające dostępnych lokali.
**Beneficjenci:** mieszkańcy centrum (mniej hałasu), lokalne biznesy poza centrum,
miasto (dane o ruchu nocnym, bezpieczniejsze powroty).

## Rozwiązanie

| Zakładka | Co robi |
|---|---|
| **Start** | Plan wieczoru, szybkie akcje, „Teraz w mieście” (tłok w dzielnicach + podpowiedź spokojniejszej), perełki, liga |
| **Mapa** | Bary na OSM + warstwy: tłok teraz, strefy ciszy nocnej, nocne MPK, bez barier, perełki |
| **Bary** | Lista jak w Bookingu: ceny w przedziałach (piwo, shot, drink, jedzenie), filtry, odległość **od poprzedniego baru w trasie**, sortowanie **najpierw oceną znajomych, potem ogólną** |
| **Barobranie** | Trasa na mapie: kolejność (przeciągnij), godziny, spacer, budżet jako przedział, ostrzeżenia (zamknięte, tłok → zamiennik, strefa ciszy), **bezpieczny powrót** |
| **Znajomi** | Ligi tygodniowe jak w Duolingo (awans/spadek), seria w tygodniach, gablota pucharków brąz/srebro/złoto |

Meldowanie: kod QR `jakwypije:bar:<id>`, GPS (do 150 m) lub tryb demo.
Punkty: 10 za meldunek, +5 pierwsza wizyta, +15 ukryta perełka, **+10 poza tłokiem**, +5 za ocenę.

### Smart City – jak to wpisuje się w zadanie

| Obszar z zadania | Funkcja |
|---|---|
| Transport i planowanie podróży | Trasa piesza między barami, **bezpieczny powrót** – najbliższy przystanek z linią nocną i odjazdy po planowanym końcu wieczoru |
| Dostępność przestrzeni i usług | Filtr i oznaczenia „bez barier” (wejście, toaleta), cicha strefa, puchar „Bez barier” |
| Wykorzystanie danych miejskich | Profil tłoku stref w godzinach 18–02, ostrzeżenia w trasie, rekomendacje dzielnic poza centrum |
| Relacja mieszkańcy – miasto | Strefy ciszy nocnej i komunikat o nocnym zakazie sprzedaży alkoholu w sklepach |
| Rozładowanie przeciążeń | Bonus i puchar za meldunki poza tłokiem, zamiennik baru z zatłoczonej strefy |

## Uruchomienie

```bash
flutter pub get
flutter run
```

Jakość (wymagane po każdej zmianie – `CLAUDE.md`):

```bash
flutter analyze
flutter test
```

## Dane i ograniczenia

- `assets/data/bars.json` – fikcyjne bary z cenami, godzinami, dostępnością, oceną ogólną.
- `assets/data/city_zones.json` – strefy nocne, profil tłoku 18–02 (przykładowy), strefy ciszy.
- `assets/data/transit_stops.json` – przystanki i linie z rozkładem w formie częstotliwości
  (przykładowe). **Docelowo: otwarte dane GTFS ZTP Kraków** i anonimowe zliczenia meldunków.
- Trasy piesze to linie proste (bez silnika nawigacji).
- Godziny nocnego zakazu sprzedaży alkoholu trzeba zweryfikować z aktualną uchwałą Rady Miasta.

## Wykorzystane zasoby i AI (wymóg regulaminu)

- Mapy: © OpenStreetMap contributors (kafelki tile.openstreetmap.org).
- Biblioteki: Flutter, flutter_riverpod, go_router, flutter_map, latlong2, geolocator,
  mobile_scanner, shared_preferences, google_fonts (Nunito), intl.
- AI: kod, dane przykładowe i dokumentacja przygotowane z pomocą **Claude Code (Anthropic)**.
  Zespół rozumie i odpowiada za całe rozwiązanie.
- Logo: _uzupełnij źródło / narzędzie_.

## Struktura

```
lib/
  main.dart, app.dart        # start, router (go_router), motyw jasny/ciemny
  core/                      # theme, utils (haversine, zł, oś czasu wieczoru)
  data/                      # models, repositories (JSON), local_storage, location
  features/                  # splash, home, map, bars, bar_detail, barobranie,
                             # friends (ligi, pucharki), profile, checkin
  widgets/                   # wspólne widgety
assets/data/*.json           # mock danych · assets/images/ – logo
docs/pitch-outline.md        # szkic prezentacji (max 10 slajdów)
```
