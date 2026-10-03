# JakWypiję 🍺

MVP na HackYeah (kategoria Smart City): planowanie wieczoru na mapie Krakowa,
grywalizacja odwiedzania mniej znanych barów, oceny znajomych i **Barobranie** –
społeczność ratuje bary zagrożone zamknięciem.

> Wszystkie nazwy barów, zbiórki i osoby w danych są fikcyjne.
> Wpłaty w Barobraniu są symulowane – żadne pieniądze nie są pobierane.

## Funkcje

| Zakładka | Co robi |
|---|---|
| **Mapa** | Bary na OSM, kolory statusu (perełka / ratowany / uratowany), filtry, trasa planu, „Melduj się” |
| **Plan** | Kolejność przystanków (przeciągnij), godziny, spacer (haversine), budżet, optymalizacja trasy, propozycje perełek |
| **Barobranie** | Zbiórki z postępem, nagrody, symulowane wpłaty, „uratowane” = zielone, „ratowane” = koralowe |
| **Znajomi** | Ranking punktów i ostatnie oceny znajomych |
| **Profil** | Poziom, statystyki, odznaki, historia meldunków |

Meldowanie: kod QR `jakwypije:bar:<id>` (mobile_scanner), GPS (do 150 m od baru)
lub **tryb demo** na ekranie meldowania – przydatny podczas prezentacji.

Punkty: 10 za meldunek, +5 pierwsza wizyta, +15 ukryta perełka, +10 ratowany bar,
+5 za ocenę, +1 pkt za każde 2 zł wsparcia.

## Uruchomienie

```bash
flutter pub get
flutter run
```

Sprawdzanie jakości (wymagane po każdej zmianie – patrz `CLAUDE.md`):

```bash
flutter analyze
flutter test
```

## Struktura

```
lib/
  main.dart, app.dart        # start, router (go_router), motyw
  core/                      # theme, utils (haversine, formatowanie zł)
  data/                      # models, repositories (JSON), local_storage, location
  features/                  # map, bar_detail, planner, barobranie, profile, checkin, friends
  widgets/                   # wspólne widgety
assets/data/*.json           # mock danych
```
