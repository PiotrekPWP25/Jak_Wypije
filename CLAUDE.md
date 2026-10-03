# JakWypiję – aplikacja mobilna Flutter (MVP na hackathon HackYeah, kategoria Smart City)
Cel: odkrywanie Krakowa pieszo – trasy łączące atrakcje miasta (zabytki, punkty widokowe,
street art) z mniej znanymi barami, oceny od znajomych, "Barobranie" – układanie trasy
na mapie z eksportem do Google Maps i bezpiecznym powrotem komunikacją nocną.
Wątki Smart City: bezpieczny powrót (MPK nocne), rozładowanie tłoku (Kazimierz/Rynek → inne
dzielnice), dostępność bez barier, strefy ciszy i godziny. Retencja: tryb turysta/mieszkaniec,
wyzwania i wydarzenia tygodnia, Paszport 18 dzielnic, happy hours i nowe miejsca.

Stack: Flutter 3.41+, Dart 3.5+, flutter_riverpod, go_router, flutter_map + latlong2 (OSM),
geolocator, mobile_scanner, shared_preferences, google_fonts, intl, supabase_flutter
(konta e-mail+hasło i profil – zatwierdzony wyjątek v4).
Linki zewnętrzne (Google Maps) otwiera własny kanał platformowy
`pl.hackyeah.jakwypije/external` (MainActivity.kt, AppDelegate.swift) – bez url_launcher;
fallback: schowek.
Dane: mock w assets/data/*.json (bars, landmarks, trips, events, districts, city_zones,
transit_stops, friends, reviews). Backend opcjonalny: Supabase (tabela `profiles`,
SQL w supabase/migrations/), klucze przez `--dart-define-from-file=env/supabase.json`.

Struktura: lib/
  main.dart, app.dart (router, motyw)
  core/ (config/env, theme + theme_controller, platform/external_launcher, utils: haversine,
         zł, oś czasu wieczoru, maps_link)
  data/ (models – Place = Bar | Landmark, UserProfile; repositories ładujące JSON
         i profiles; auth/auth_repository; remote/supabase_provider; local_storage; location)
  features/splash, onboarding, home, map, bars (bary + atrakcje), bar_detail, landmark_detail,
  barobranie (trasa, eksport, bezpieczny powrót), trips, events, gamification (punktacja,
  wyzwania), passport, friends (ligi, pucharki), profile, checkin,
  account (logowanie, kod z maila, synchronizacja profilu), settings (ustawienia, dokumenty)
  widgets/ (wspólne)

Nawigacja: Start · Mapa · Bary · Barobranie · Znajomi; Profil z awatara na Starcie,
Ustawienia (⚙️) z Profilu.

Zasady:
- UI po polsku, kod i nazwy po angielsku.
- Modele niemutowalne z fromJson/toJson (bez generatorów kodu – pisz ręcznie);
  przy zmianie kluczy JSON czytaj też stare (np. barIds → stopIds, barId → placeId).
- Po każdej zmianie uruchom `flutter analyze` i popraw wszystkie błędy i ostrzeżenia.
- Nie dodawaj pakietów spoza listy bez pytania.
- Motyw: jasny kremowy (jak logo) domyślny + ciemny przełączany przez użytkownika (Profil, Start).
  Paleta z logo: tło krem #F7F1E5, tekst brąz #3B2314, akcent bursztyn #FFB300,
  trasa/atrakcje/„OK” zieleń #2E9E44, tłok/ostrzeżenia koral #FF6F61,
  noc/strefy ciszy indygo #5C6BC0.
- Wszystkie nazwy barów są fikcyjne (atrakcje są prawdziwe, godziny/ceny przybliżone).
- Godziny wieczoru trzymamy na „osi wieczoru” (01:30 = 25:30), patrz core/utils/time.dart.
- Odpowiedzialna grywalizacja (features/gamification/scoring.dart): punkty za odkrywanie
  miasta – atrakcje, nowe dzielnice, km spaceru, ukończone trasy; w barach punktujemy
  maks. 2 meldunki na wieczór, żadnych premii za liczbę barów ani napojów; seria w lidze
  liczona w tygodniach, nie dniach.
- Dane miejskie (tłok, MPK, wydarzenia) to przykłady – w UI oznaczaj je jako prognozę/demo.
- Offline-first: Supabase jest opcjonalny – każda funkcja musi działać w trybie demo
  (`supabaseClientProvider` == null). UI czyta stan lokalny, zmiany idą do bazy w tle.
- Każda tabela w Supabase ma RLS; kluczy (env/supabase.json) nie commitujemy.
- Aplikacja 18+: bramka wieku i akceptacja dokumentów w onboardingu; zmiana
  Regulaminu/Polityki = podbij `currentTermsVersion` (features/account/account_providers.dart).
