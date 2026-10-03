# JakWypiję 🍺📍

**HackYeah 2026 · Open Task: Smart City**

Aplikacja mobilna (Flutter) do **odkrywania Krakowa pieszo**: łączysz atrakcje miasta
(zabytki, punkty widokowe, street art) z mniej znanymi barami w jedną trasę
(„Barobranie”), eksportujesz ją do Google Maps i bezpiecznie wracasz komunikacją nocną.
Grywalizacja nagradza **chodzenie i odkrywanie dzielnic**, a nie liczbę barów.

> Nazwy barów i osoby są fikcyjne. Atrakcje są prawdziwe, ale ich godziny i ceny są
> przybliżone. Dane o tłoku, rozkładach MPK i wydarzeniach są przykładowe (demo).

## Problem

Piątek, 21:30, Kazimierz. Ulice są pełne, w ulubionym barze nie ma miejsc, a mieszkańcy skarżą się
na hałas. Turysta zna tylko Rynek. Mieszkaniec chodzi od lat w te same 2–3 miejsca. O 1:00
nie wiadomo, czym wrócić. Tymczasem kilkaset metrów dalej, w Podgórzu, na Zabłociu
czy w Nowej Hucie, są świetne miejsca i puste lokale.

**Użytkownicy:**
- turyści, którzy chcą zobaczyć miasto po swojemu;
- mieszkańcy i studenci planujący wieczór ze znajomymi;
- osoby z niepełnosprawnościami szukające dostępnych lokali.

**Kto zyskuje poza nimi:**
- mieszkańcy centrum, bo jest mniej hałasu;
- lokalne biznesy poza centrum;
- miasto: dane o ruchu nocnym i bezpieczniejsze powroty.

## Rozwiązanie

| Zakładka | Co robi |
|---|---|
| **Start** | Dopasowany do trybu (turysta/mieszkaniec): gotowe trasy, must-see, wyzwania tygodnia, wydarzenia, „Teraz taniej”, nowe miejsca, „Dzielnice do odkrycia”, tłok w mieście |
| **Mapa** | Bary i atrakcje na OSM; warstwy: tłok teraz, strefy ciszy, nocne MPK, bez barier |
| **Bary / Atrakcje** | Bary w stylu Bookinga: ceny w przedziałach, filtry (odległość od poprzedniego przystanku, opcje 0%, happy hour, karta, bez barier, poza tłokiem), sortowanie najpierw oceną znajomych, potem ogólną. Atrakcje z filtrem kategorii |
| **Barobranie** | Trasa mieszana na mapie: kolejność, godziny, spacer, budżet, ostrzeżenia (zamknięte, tłok z zamiennikiem, cisza nocna), **eksport do Google Maps**, „Kopiuj plan”, **bezpieczny powrót** |
| **Znajomi** | Ligi tygodniowe (awans/spadek), wyzwania tygodnia, seria liczona w tygodniach, gablota pucharków |

Do tego:
- **Gotowe tripy** jak listy w Google Maps, np. „Kazimierz: historia i kraft” albo „Nowa Huta po zmroku”.
- **Paszport Krakowa** z pieczątkami 18 dzielnic.
- **Meldowanie:** QR w barach, GPS do 150 m przy atrakcjach i barach, tryb demo.

## Odpowiedzialna grywalizacja

Uwaga mentora: punkty za meldunki w barach mogą wyglądać jak nagradzanie picia.
Dlatego (`lib/features/gamification/scoring.dart`):

| Za co | Punkty |
|---|---|
| Atrakcja | 15, pierwsza wizyta +5 |
| Nowa dzielnica (pieczątka w Paszporcie) | +20 |
| Spacer między przystankami | 10 XP / km (limit 6 km na wieczór) |
| Ukończona trasa z min. 1 atrakcją | +30 |
| Bar | 10 (+5 perełka, +10 poza tłokiem), **tylko 2 pierwsze bary wieczoru** |

Nie ma premii za liczbę barów ani napojów. Seria w lidze liczy **tygodnie**, nie dni,
a pucharki dotyczą dzielnic, atrakcji, kilometrów, tras, dostępności i bezpiecznych
powrotów. Filtr „Opcje 0%” pokazuje lokale z dobrą ofertą bezalkoholową.

## Retencja: turyści i mieszkańcy

Turysta przyjeżdża na kilka dni, mieszkaniec zostaje na lata. Aplikacja daje obu powód, żeby wracać:

- **Tryb turysta / mieszkaniec** (onboarding, zmiana w Profilu): inny układ ekranu Start.
- **Wyzwania tygodnia:** co tydzień 3 nowe, np. „Tydzień Podgórza”, „Spacerowicz 5 km”, „Coś nowego”.
- **Wydarzenia w tym tygodniu:** cykliczne wydarzenia w barach i przy atrakcjach.
- **Paszport 18 dzielnic:** długoterminowy cel. Większość mieszkańców zna 2–3 dzielnice.
- **Happy hours i nowe miejsca:** realna wartość dla mieszkańców co tydzień.
- **Ligi tygodniowe ze znajomymi:** awans i spadek co poniedziałek.

## Model biznesowy

Lokale partnerskie płacą za promowanie ofert (happy hours, wydarzenia, znacznik „Nowe”),
a **nie za pozycję w rankingu**. Ranking zawsze opiera się na ocenach znajomych i ocenie
ogólnej. Miasto może wykorzystać zanonimizowane dane o ruchu nocnym, a operator
transportu dane o zapotrzebowaniu na linie nocne.

## Smart City – jak to wpisuje się w zadanie

| Obszar z zadania | Funkcja |
|---|---|
| Transport i planowanie podróży | Trasy piesze, **eksport do Google Maps**, bezpieczny powrót: przystanek z linią nocną i odjazdy po końcu trasy |
| Dostępność przestrzeni i usług | Filtr i oznaczenia „bez barier”, cicha strefa, puchar i wyzwanie „Bez barier” |
| Wykorzystanie danych miejskich | Profil tłoku stref 18–02, ostrzeżenia w trasie, rekomendacje dzielnic poza centrum |
| Lepsze wykorzystanie zasobów miasta | Atrakcje i dzielnice spoza centrum, Paszport, wyzwania typu „Tydzień Podgórza” |
| Relacja mieszkańcy – miasto | Strefy ciszy nocnej, komunikat o nocnym zakazie sprzedaży alkoholu w sklepach |

## Uruchomienie

```bash
flutter pub get
flutter run --release
```

Jakość (wymagane po każdej zmianie, patrz `CLAUDE.md`):

```bash
flutter analyze
flutter test
```

## Konto, ustawienia i baza danych (Supabase)

Aplikacja działa **offline-first**. Bez kluczy Supabase uruchamia się w trybie demo
i wszystko zostaje na telefonie. Z kluczami dochodzą konta (e-mail + hasło,
potwierdzenie 6-cyfrowym kodem) i synchronizacja profilu: imię, awatar, tryb, motyw
i zgody. Meldunki, plan i oceny na razie zostają na urządzeniu.

**Ustawienia** (⚙️ w Profilu):
- konto: logowanie, zmiana hasła, wylogowanie, usunięcie konta;
- profil i motyw;
- prywatność: zgoda marketingowa, eksport danych (JSON), wyczyszczenie danych;
- 18+ i pomoc;
- Regulamin, Polityka prywatności i licencje.

**Onboarding:** bramka 18+ i akceptacja dokumentów (`assets/legal/*.md`, wersja
`currentTermsVersion`).

### Konfiguracja

1. Załóż projekt na [supabase.com](https://supabase.com) w regionie **EU Central (Frankfurt)**.
2. W **SQL Editor** uruchom `supabase/migrations/0001_profiles.sql`. Skrypt tworzy:
   - tabelę `profiles` z RLS;
   - trigger zakładający profil;
   - funkcję `delete_my_account()`.
3. **Authentication → Sign In / Providers → Email:** włączone, *Confirm email* włączone.
4. **Authentication → Emails:** w szablonach *Confirm signup* i *Reset password* zamień
   link na kod, np.:
   ```html
   <h2>Twój kod JakWypiję</h2>
   <p>Wpisz w aplikacji kod: <strong>{{ .Token }}</strong></p>
   <p>Kod wygasa po godzinie. Jeśli to nie Ty, zignoruj tę wiadomość.</p>
   ```
5. Wbudowana poczta Supabase wysyła tylko kilka maili na godzinę. Na produkcję podepnij
   własny SMTP (*Authentication → Emails → SMTP*), a na demo możesz wyłączyć
   *Confirm email*.
6. Skopiuj `env/supabase.example.json` do `env/supabase.json` (plik jest w `.gitignore`)
   i wpisz *Project URL* oraz *Publishable key* z **Project Settings → API Keys**.
7. Uruchom:
   ```bash
   flutter run --release --dart-define-from-file=env/supabase.json
   ```

Klucz publishable trafia do aplikacji, a bezpieczeństwo danych zapewnia **row level
security**: każdy widzi i zmienia tylko swój wiersz.

### Przed publikacją w sklepach (do weryfikacji z prawnikiem)

- Uzupełnij administratora danych i kontakt w `assets/legal/*.md` (to szkice).
- Podpisz DPA z Supabase.
- Google Play:
  - strona WWW do usuwania konta;
  - formularz *Data safety*;
  - klasyfikacja 18+.
- Model „promowanie happy hours” sprawdź pod kątem art. 13¹ ustawy o wychowaniu
  w trzeźwości (zakaz reklamy i promocji alkoholu). Bezpieczniej promować wydarzenia,
  jedzenie i opcje 0%.

## Dane i ograniczenia

- **`bars.json`:** fikcyjne bary z cenami, godzinami, dostępnością, happy hours i oceną ogólną.
- **`landmarks.json`:** prawdziwe atrakcje Krakowa z przybliżonymi współrzędnymi, godzinami i cenami biletów.
- **`trips.json`, `events.json`:** gotowe trasy i przykładowe cykliczne wydarzenia.
- **`districts.json`:** 18 dzielnic Krakowa (Paszport).
- **`city_zones.json`:** strefy nocne, profil tłoku (przykładowy), strefy ciszy.
- **`transit_stops.json`:** przystanki i linie (przykładowe). **Docelowo otwarte dane GTFS ZTP Kraków.**
- **Trasy piesze w aplikacji** to linie proste. Pełną nawigację daje eksport do Google Maps; jeden link mieści do 9 punktów pośrednich, dłuższe trasy są dzielone.
- **Otwieranie Google Maps** działa przez własny kanał platformowy (`MainActivity.kt`, `AppDelegate.swift`). Gdy się nie uda, link trafia do schowka. Wersję iOS napisano, ale nie testowano, bo powstała na Windowsie.
- **Godziny nocnego zakazu sprzedaży alkoholu** trzeba zweryfikować z aktualną uchwałą Rady Miasta.

## Wykorzystane zasoby i AI (wymóg regulaminu)

- **Mapy:** © OpenStreetMap contributors (kafelki tile.openstreetmap.org); linki do Google Maps (Maps URLs).
- **Biblioteki:** Flutter, flutter_riverpod, go_router, flutter_map, latlong2, geolocator, mobile_scanner, shared_preferences, google_fonts (Nunito), intl, supabase_flutter.
- **AI:** kod, dane przykładowe i dokumentacja powstały z pomocą **Claude Code (Anthropic)**. Zespół rozumie całe rozwiązanie i za nie odpowiada.
- **Logo:** _uzupełnij źródło / narzędzie_.

## Struktura

```
lib/
  main.dart, app.dart        # start, router (go_router), motyw jasny/ciemny
  core/                      # theme, platform (kanał linków), utils (geo, zł, czas, maps_link)
  core/config/env.dart       # klucze Supabase z --dart-define (brak = tryb demo)
  data/                      # models (Place = Bar | Landmark, UserProfile), repositories
                             # (JSON, profiles), auth (Supabase), storage
  features/                  # splash, onboarding, home, map, bars, bar_detail, landmark_detail,
                             # barobranie, trips, events, gamification, passport, friends,
                             # profile, checkin, account (logowanie, sync), settings (+ legal)
  widgets/                   # wspólne widgety
assets/data/*.json           # mock danych · assets/images/ – logo · assets/legal/ – dokumenty
supabase/migrations/         # SQL: profiles + RLS + delete_my_account()
env/supabase.example.json    # wzór kluczy (env/supabase.json poza repo)
docs/pitch-outline.md        # szkic prezentacji (max 10 slajdów)
```
