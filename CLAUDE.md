# JakWypiję – aplikacja mobilna Flutter (MVP na hackathon HackYeah, kategoria Smart City)
Cel: planowanie wieczoru na mapie, grywalizacja odwiedzania mniej znanych barów w Krakowie,
oceny od znajomych, "Barobranie" – społeczność ratuje bary zagrożone zamknięciem.

Stack: Flutter 3.24+, Dart 3.5+, flutter_riverpod, go_router, flutter_map + latlong2 (OSM),
geolocator, mobile_scanner, shared_preferences, google_fonts, intl.
Dane: mock w assets/data/*.json, bez backendu.

Struktura: lib/
  main.dart, app.dart (router, motyw)
  core/ (theme, utils: haversine, formatowanie zł)
  data/ (models, repositories ładujące JSON, local_storage)
  features/map, features/bar_detail, features/planner, features/barobranie,
  features/profile, features/checkin, features/friends
  widgets/ (wspólne)

Zasady:
- UI po polsku, kod i nazwy po angielsku.
- Modele niemutowalne z fromJson/toJson (bez generatorów kodu – pisz ręcznie).
- Po każdej zmianie uruchom `flutter analyze` i popraw wszystkie błędy i ostrzeżenia.
- Nie dodawaj pakietów spoza listy bez pytania.
- Ciemny motyw domyślny, kolor akcentu bursztynowy (#FFB300), "uratowane" = zielony, "ratowane" = czerwony/koralowy.
- Wszystkie nazwy barów są fikcyjne.
