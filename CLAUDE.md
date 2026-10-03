# JakWypiję – aplikacja mobilna Flutter (MVP na hackathon HackYeah, kategoria Smart City)
Cel: planowanie wieczoru na mapie, grywalizacja odwiedzania mniej znanych barów w Krakowie,
oceny od znajomych, "Barobranie" – układanie trasy wieczoru (bar crawl) na mapie,
z bezpiecznym powrotem komunikacją nocną. Wątki Smart City: bezpieczny powrót (MPK nocne),
rozładowanie tłoku (Kazimierz/Rynek → inne dzielnice), dostępność bez barier, strefy ciszy i godziny.

Stack: Flutter 3.41+, Dart 3.5+, flutter_riverpod, go_router, flutter_map + latlong2 (OSM),
geolocator, mobile_scanner, shared_preferences, google_fonts, intl.
Dane: mock w assets/data/*.json (bars, city_zones, transit_stops, friends, reviews), bez backendu.

Struktura: lib/
  main.dart, app.dart (router, motyw)
  core/ (theme + theme_controller, utils: haversine, formatowanie zł, oś czasu wieczoru)
  data/ (models, repositories ładujące JSON, local_storage, location)
  features/splash, features/home, features/map, features/bars, features/bar_detail,
  features/barobranie (trasa + bezpieczny powrót), features/friends (ligi, pucharki),
  features/profile, features/checkin
  widgets/ (wspólne)

Nawigacja: Start · Mapa · Bary · Barobranie · Znajomi; Profil z awatara na Starcie.

Zasady:
- UI po polsku, kod i nazwy po angielsku.
- Modele niemutowalne z fromJson/toJson (bez generatorów kodu – pisz ręcznie).
- Po każdej zmianie uruchom `flutter analyze` i popraw wszystkie błędy i ostrzeżenia.
- Nie dodawaj pakietów spoza listy bez pytania.
- Motyw: jasny kremowy (jak logo) domyślny + ciemny przełączany przez użytkownika (Profil, Start).
  Paleta z logo: tło krem #F7F1E5, tekst brąz #3B2314, akcent bursztyn #FFB300,
  trasa/„OK” zieleń #2E9E44, tłok/ostrzeżenia koral #FF6F61, noc/strefy ciszy indygo #5C6BC0.
- Wszystkie nazwy barów są fikcyjne.
- Godziny wieczoru trzymamy na „osi wieczoru” (01:30 = 25:30), patrz core/utils/time.dart.
- Seria w lidze liczona w tygodniach, nie dniach – nie nagradzamy codziennego picia.
- Dane miejskie (tłok, MPK) to przykłady – w UI oznaczaj je jako prognozę/demo.
