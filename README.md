
HBWFC Overlijst - Flutter source (ready to build)
===============================================

Inhoud:
- Flutter project with main implementation in lib/main.dart
- Gebruik: Flutter SDK + Android toolchain vereist om een APK te bouwen.
- Map waar CSV's worden opgeslagen: Downloads/HBWFC_Overlijst (op Android).

Belangrijk:
1) Je hebt Android Studio / Flutter SDK nodig om deze code te bouwen naar een .apk.
   - Als je zelf geen tooling wilt installeren, kun je iemand anders vragen om de map te bouwen,
     of ik kan (indien mogelijk) helpen met het bouwen als je mij een toegestane uploadmethode
     biedt en toestemming geeft om te bouwen op een beschikbare buildserver. Momenteel kan ik
     in deze omgeving geen Android SDK build uitvoeren.
2) Build stappen (kort):
   - unzip het project
   - open terminal in projectmap
   - run `flutter pub get`
   - sluit een Android-apparaat aan of start een emulator
   - run `flutter build apk --release`
   - of maak een debug apk: `flutter build apk --debug`

Kleuren:
- Hoofdkleur (uit logo): #2E8B3A (groen approximatie)
- Accent / achtergrond: wit

Bestandsnaam CSV:
- Format: Over-lijst YYYY-MM-DD hh:mm:ss.csv (timestamp is het moment waarop de scansessie start)

Opmerkingen over features (zoals aangevraagd door Tom Welters):
- Begin scherm: Historie / Scannen
- Scannen: automatische detectie, popup met gescande code + numeriek invoer
- Dubbele detectie: melding met "Aantal aanpassen" of "Negeren"
- CSV opgeslagen in Downloads/HBWFC_Overlijst en ook zichtbaar in app
- Historie met bestanden, openen, delen, en "Doorgaan met scannen" (maakt V2/V3 bestand)

Als je wilt dat ik wél de APK voor je bouw en upload, geef dan aan hoe je wilt dat ik het upload (WeTransfer of soortgelijk)
en bevestig dat je akkoord bent met een debug-key build (standaard debug signing). Ik kan geen APK genereren in deze environment.

