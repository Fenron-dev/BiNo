# Konzept: Personal Notes & Capture App ("MindFeed")

> **Arbeitstitel:** MindFeed (Platzhalter, frei änderbar)
> **Plattform:** Android (Mobile-First), Flutter
> **Zielgerät (Referenz):** Samsung Galaxy S21 FE — SM-G990B/DS, Exynos 2100, 6/8 GB RAM, Android 14
> **Sprache:** Deutsch (primär), Englisch (UI-Strings i18n-ready)
> **Konzept-Version:** 0.1 (für Claude-Code-Briefing)

---

## 1. Vision & Kernidee

Eine schnelle, persönliche "Second Brain"-App im Stil eines WhatsApp-Chats mit sich selbst. Erfassen muss in unter 5 Sekunden gehen — Text, Fotos, Audio, Weblinks, OCR. Wiederfinden über Tags, Volltextsuche, semantische Suche und konfigurierbare Hub-Tabs.

**Leitprinzipien:**
1. **Capture-Friction = 0** — Schnelleingabe wichtiger als Schönheit.
2. **Lokal first, Cloud opt-in** — Alle Daten lokal in SQLite. AI-Anreicherung nur, wenn der User aktiv auf einen Button drückt.
3. **Obsidian-Style Flexibilität** — Eigene Tags, Eigenschaften, Wikilinks `[[...]]`, keine starre Hierarchie.
4. **Wiederfinden ist gleich wichtig wie Erfassen** — Hub-Tabs, Resurface, Random Card, semantische Suche.

---

## 2. Hauptnavigation (Bottom-Tabs)

Bottom-Navigation mit dynamischer Tab-Anzahl. Drei feste Tabs + zentraler Capture-Button + bis zu N benutzerdefinierte Hub-Tabs.

```
[ Feed ] [ Projekte ]   [ + ]   [ Bereiche ] [ Hub:Buch ]
                       (FAB)
```

### 2.1 Feste Tabs

**Feed (Standard-Tab)**
- Chronologische Liste aller Einträge, neueste unten (wie WhatsApp).
- Auto-Scroll auf neuesten Eintrag beim Öffnen.
- Pull-to-Refresh zeigt "On this day"-Resurface-Karten oben.
- Pinned-Einträge sticky oben (max. 5).
- Filter-Chip-Leiste oberhalb: schnell nach Tag / Typ / Projekt filtern.
- Suchfeld als Header — kombiniert FTS5 + Embedding-Suche.

**Projekte**
- Liste aller als "Projekt" markierten Container.
- Pro Projekt: Cover-Karte mit Titel, Beschreibung, Eintragsanzahl, letzter Aktivität.
- Drill-Down zeigt alle Einträge des Projekts als Mini-Feed.

**Bereiche**
- Identisch zu Projekten, aber semantisch für "laufende Lebensbereiche" (Arbeit, Hobby, Familie, ...) statt zeitlich begrenzte Vorhaben.
- Technisch gleicher Datentyp wie Projekte, nur anderes Label/Icon.

### 2.2 Capture-Button (FAB, mittig)

Zentraler "+" Button im Bottom-Bar.
- **Tap:** Öffnet Quick-Capture-Sheet (Text-Eingabe + Action-Row).
- **Long-Press:** Direkter Audio-Aufnahme-Modus (Push-to-talk-Style).
- **Swipe-Up auf Tab-Bar:** Volle Capture-Detailseite mit allen Feldern.

### 2.3 Hub-Tabs (Benutzerdefiniert)

Zentrales Feature, ersetzt starre Kategorien:
- User kann in Settings beliebige Tabs hinzufügen, die auf gespeicherten Filtern basieren.
- Beispiele: Tab "Bücher" = alle Einträge mit Tag `#buch`; Tab "ToRead" = alle Einträge mit Status `inbox` und Typ `link`.
- Pro Hub-Tab konfigurierbar: Name, Icon, Filter-Definition, Sortierung, View-Modus (Liste / Grid / Karten).
- Max. 4 sichtbare Tabs in Bottom-Bar (sonst Overflow ins "Mehr"-Menü).
- Tab-Reihenfolge per Drag-and-Drop in Settings änderbar.

---

## 3. Datenmodell

### 3.1 Kern-Entity: `Entry`

| Feld | Typ | Beschreibung |
|------|-----|--------------|
| `id` | UUID | Primärschlüssel |
| `created_at` | DateTime (UTC) | Erfassungszeitpunkt, auto |
| `updated_at` | DateTime (UTC) | Letzte Änderung, auto |
| `type` | Enum | `text` \| `link` \| `image` \| `audio` \| `mixed` |
| `title` | String? | Optionaler Titel (auto-generiert aus erstem Satz wenn leer) |
| `body` | Markdown-String | Hauptinhalt, unterstützt Wikilinks `[[...]]` und Tags `#tag` |
| `status` | Enum | `inbox` \| `active` \| `done` \| `archived` |
| `pinned` | Bool | Sticky im Feed |
| `geo_lat`, `geo_lng` | Double? | Optionaler Standort |
| `reminder_at` | DateTime? | Optionale Erinnerung |
| `source_url` | String? | Bei Link-Typ |
| `source_app` | String? | Bei Share-Intent: Herkunfts-App |
| `embedding` | BLOB | Lokaler Vektor (multilingual-e5-small, 384-dim, float32) |
| `ai_enriched_at` | DateTime? | Wann zuletzt mit Cloud-LLM angereichert |
| `lang` | String? | Erkannte Sprache (de/en/...) |

### 3.2 Tags & Subtags

- Tags hierarchisch via "/"-Notation wie in Obsidian: `#buch/sachbuch/psychologie`.
- Eigene Tabelle `tags` mit `id`, `name`, `parent_id?`, `color?`, `icon?`.
- Many-to-Many über `entry_tags`.
- Auto-Vorschläge basieren auf Embedding-Ähnlichkeit zu existierenden Tag-Embeddings.

### 3.3 Custom Properties (Obsidian-Style)

Pro Eintrag beliebige Key-Value-Properties möglich:
- Tabelle `entry_properties` mit `entry_id`, `key`, `value`, `type` (string/number/date/bool/url).
- UI: Im Detail-View als editierbare Tabelle, ähnlich Notion-Properties.
- Auto-erkannte Properties bei AI-Enrich (z.B. `author`, `isbn` bei Buch-Eintrag).

### 3.4 Container (Projekte / Bereiche / Hubs)

Ein generischer `container`-Typ mit Feld `kind` (project / area / hub / tag-view):
- `id`, `kind`, `name`, `description?`, `icon`, `color`, `created_at`, `archived?`.
- Filter-Definition bei `kind=hub` als JSON-Feld (siehe 5.2).
- Einträge zugewiesen über `entry_containers` (m:n).

### 3.5 Verknüpfungen (Wikilinks)

- Wikilink-Syntax `[[Eintragstitel]]` oder `[[uuid:abc...]]` im Body.
- Parser extrahiert Links, schreibt sie in Tabelle `entry_links` (`from_id`, `to_id`).
- Backlink-Anzeige im Detail-View ("Wird verlinkt von ...").

### 3.6 Anhänge

- Tabelle `attachments`: `id`, `entry_id`, `file_path`, `mime_type`, `size`, `width?`, `height?`, `duration_ms?`, `transcription?`, `ocr_text?`.
- Dateien im App-Document-Directory unter `attachments/YYYY/MM/`.

### 3.7 Volltext-Index (SQLite FTS5)

- Virtuelle Tabelle `entries_fts` mit Spalten `title`, `body`, `ocr_text`, `transcription`, `tag_names`.
- Trigger auf Insert/Update halten FTS5 automatisch synchron.
- Snippet-Funktion für Such-Highlighting.

### 3.8 Vector-Index (sqlite-vec)

- Virtuelle Tabelle `entries_vec` mit `embedding` (384-dim).
- KNN-Suche via `vec_distance_cosine`.
- Hybrid-Suche: FTS5-Treffer + Vec-Treffer reranked und gemerged.

---

## 4. Capture-Flows

### 4.1 Quick-Text-Capture (Default)

1. Tap auf "+".
2. Bottom-Sheet schiebt hoch, Tastatur ist automatisch fokussiert.
3. Multiline-Textfeld, oberhalb eine horizontale Scroll-Bar mit Action-Buttons:
   - 📷 Foto (Kamera-Sheet)
   - 🖼️ Galerie
   - 🎤 Audio
   - 🔗 URL einfügen (Clipboard auto-detect)
   - 📍 Standort hinzufügen
   - 🏷️ Tag (öffnet Tag-Picker)
   - ✨ AI-Enrich (nach dem Speichern, Cloud)
4. "Senden"-Button (Pfeil rechts unten wie WhatsApp).
5. Beim Senden: Entry wird sofort gespeichert, Bottom-Sheet schließt, Feed scrollt zum neuen Eintrag.
6. Im Hintergrund: Embedding wird generiert, Auto-Tags vorgeschlagen (Toast "3 Tags vorgeschlagen — anwenden?").

### 4.2 Share-Intent (Killer-Feature)

- App registriert sich als Share-Target für `text/plain`, `text/uri-list`, `image/*`, `video/*`, `audio/*`.
- Beim Teilen aus anderer App: kleines Confirm-Sheet mit Vorschau + Tag-Vorschlägen + "Speichern"-Button.
- Default-Verhalten: in 2 Taps gespeichert.
- Quelle wird in `source_app` festgehalten.

### 4.3 URL/Link-Capture

- Wird URL erkannt (Clipboard oder Share-Intent):
  - Hintergrund-Job holt Open-Graph-Metadaten (Titel, Beschreibung, Vorschaubild).
  - Vorschaubild wird lokal gespeichert als Anhang.
  - Eintrag erhält Typ `link` und automatisch befüllte Properties (`og_title`, `og_description`, `og_image`, `domain`).

### 4.4 Foto / OCR

- Direkt aus Capture-Sheet die Kamera öffnen (`camera`-Package).
- Nach Aufnahme: Bild wird als Anhang gespeichert, ML-Kit Text-Recognition läuft im Hintergrund.
- Erkannter Text landet in `attachments.ocr_text` und wird Teil des FTS5-Index (aber NICHT in den `body`, damit der User entscheidet).
- UI-Aktion "Text aus Bild übernehmen" kopiert OCR-Text in den `body`.

### 4.5 Audio / Transkription

- Long-Press auf "+" startet Aufnahme (Haptic-Feedback).
- WhatsApp-Style: Finger auf Button halten = aufnehmen, Loslassen = senden, Hochziehen = sperren für längere Aufnahmen.
- Audio wird als M4A gespeichert.
- Transkription läuft danach asynchron via Android Speech Recognition API (`speech_to_text` Package):
  - **Wichtig:** `onDevice: true` und `EXTRA_PREFER_OFFLINE` setzen.
  - Settings-Hinweis für User: in Android unter Gboard → Spracheingabe → "Offline-Spracheingabe" Deutsch herunterladen.
- Optional (später): Whisper-Lokal als Premium-Modus.

### 4.6 Homescreen-Widget

- Drei-Button-Widget: ✏️ Text, 📷 Foto, 🎤 Audio.
- Jeder Button öffnet die App direkt im jeweiligen Capture-Mode.
- Package: `home_widget`.

---

## 5. Anreicherung & Smart-Features

### 5.1 Automatisch lokal (immer aktiv)

| Feature | Tech | Aufwand pro Eintrag |
|--------|------|---------------------|
| Embedding-Generierung | ONNX Runtime + multilingual-e5-small (~120 MB) | 50–200 ms |
| OCR | google_mlkit_text_recognition | 200–500 ms |
| Sprach-Erkennung der Sprache | google_mlkit_language_id | <50 ms |
| Spracherkennung (S2T) | speech_to_text mit `onDevice:true` | Real-time |
| Tag-Vorschläge | Cosine-Similarity zu Tag-Embeddings | <100 ms |
| Verwandte-Notizen | KNN über sqlite-vec | <100 ms |
| Duplikat-Erkennung | Embedding-Cosine > 0.92 → Warnung | <100 ms |
| Open-Graph-Fetch | metadata_fetch | 500–2000 ms (Netzwerk) |

### 5.2 Hub-Filter-Definition (JSON-Schema)

Beispiel-Definition für einen Hub-Tab:

```json
{
  "name": "Bücher (laufend)",
  "icon": "menu_book",
  "color": "#9C27B0",
  "filters": {
    "tags_any": ["buch", "buch/sachbuch"],
    "status_in": ["inbox", "active"],
    "type_in": ["text", "link"],
    "created_after": null,
    "created_before": null,
    "container_id": null
  },
  "sort": { "field": "created_at", "order": "desc" },
  "view_mode": "card"
}
```

Der Filter-Builder in Settings erlaubt UI-basiertes Zusammenklicken, JSON ist nur das interne Format.

### 5.3 AI-Enrich (Cloud, manuell)

Per Button "✨ Mit AI anreichern" am einzelnen Eintrag.

- Settings: User hinterlegt **eigenen API-Key** (Anthropic / OpenAI / OpenRouter / Gemini). Kein eigener Backend-Server, kein Tracking.
- Provider-Auswahl pro Aktion möglich (z.B. "Schnell + günstig" = Haiku/Flash, "Beste Qualität" = Sonnet/4o).
- Verfügbare Aktionen:
  1. **Zusammenfassen** — Generiert 1–3 Sätze Zusammenfassung in `properties.summary`.
  2. **Strukturieren** — Extrahiert Properties (z.B. Buch → author, isbn, genre).
  3. **Tags vorschlagen mit Begründung** — Generiert 3–5 Tag-Vorschläge inkl. Erklärung.
  4. **Titel generieren** — Wenn Titel leer ist.
  5. **Übersetzen** — Optional auf Knopfdruck.
- Batch-Modus: mehrere Einträge auswählen → Enrich.
- Konfigurierbare Prompts pro Aktion in Settings (Power-User).
- Kosten-Anzeige nach jedem Call (geschätzte Tokens × Provider-Pricing).

### 5.4 Q&A über Notizen (RAG)

Eigener Tab oder Search-Modus "Frag deine Notizen":
1. User-Frage wird embedded.
2. Top-N (z.B. 8) ähnliche Einträge via sqlite-vec gezogen.
3. Kontext + Frage an gewähltes Cloud-LLM.
4. Antwort mit Quellenangaben (klickbare Eintrags-Karten).

### 5.5 Resurface & Wiederfinden

- **On-this-day-Card** oben im Feed: Eintrag von vor 1 Woche / 1 Monat / 1 Jahr (sofern vorhanden).
- **Random-Card** beim App-Start (in Settings deaktivierbar): zufälliger alter Eintrag aus `archived`/`done`.
- **Inbox-Badge**: Anzahl ungetaggter Einträge im Settings/Profil-Icon.
- **Wochen-Notification** (Sonntag 18:00): "X neue Einträge diese Woche, Y ungetaggt." → Tap öffnet Wochenrückblick-View.
- **Erinnerungen**: Optional pro Eintrag `reminder_at` setzen via `flutter_local_notifications`. Snoozable.

---

## 6. Suche

Hybrid-Suche kombiniert drei Mechanismen:

1. **Volltext (FTS5)** — exakte/fuzzy Matches in Body, Titel, OCR, Transkript.
2. **Semantisch (sqlite-vec)** — Cosine-Similarity über Embeddings.
3. **Strukturiert** — Filter über Tags, Properties, Datum, Typ, Container.

Such-UI:
- Suchfeld oben → Live-Ergebnisse.
- Filter-Chips unter dem Suchfeld (Typ, Tag, Zeitraum, Container).
- Ergebnis-Liste zeigt Snippet mit Highlighting.
- "Gespeicherte Suche"-Button → speichert aktuellen Filter als Hub-Tab.

---

## 7. Export & Teilen

### 7.1 Markdown-Export

- Pro Eintrag oder per Multi-Select.
- YAML-Frontmatter mit allen Metadaten (Tags, Properties, Datum, Container).
- Body als Markdown inkl. Wikilinks.
- Anhänge werden in einen Unterordner `attachments/` mitkopiert.
- Output: ZIP-Datei oder direkter Ordner-Export via SAF (Storage Access Framework).
- → **Obsidian-kompatibel**: Wenn User den Export in einen Obsidian-Vault legt, funktionieren Wikilinks und Tags 1:1.

### 7.2 PDF-Export

- Pro Eintrag oder Sammlung.
- Template-basiert (1–2 schlichte Templates erstmal reichen).
- Package: `pdf` (von David PHAM).

### 7.3 Teilen (Share-Intent OUT)

- Toggle-Mode im Feed: Long-Press auf einen Eintrag → Multi-Select aktiviert.
- Auswahl → "Teilen"-Button in Action-Bar.
- Optionen:
  - Als Text (für WhatsApp, SMS, etc.) — sauber formatiert.
  - Als Markdown-Datei (für Mail, Cloud-Apps).
  - Als PDF.
- Package: `share_plus`.

---

## 8. Backup & Restore

### 8.1 Lokales Backup

- Settings → "Backup erstellen".
- Erzeugt ZIP mit:
  - SQLite-DB (sqlite-vec inkl.)
  - Anhänge-Ordner
  - Einstellungen-JSON
  - Version-File für Migrationen
- Speichert via SAF an benutzergewählten Ort (interner Speicher, SD-Karte, Cloud-Anbieter, USB-OTG).

### 8.2 Restore

- "Backup wiederherstellen" → ZIP wählen → Bestätigung → App startet neu.
- Schema-Migrationen werden beim Restore automatisch ausgeführt.

### 8.3 Auto-Backup (Stretch)

- Optional: täglich/wöchentlich automatisches Backup in benutzerdefinierten Ordner.
- Rotations-Policy: letzte 7 Backups behalten.

> **Sync zwischen Geräten ist v0.1 explizit nicht im Scope.** Markdown-Export + manuelles Wiederherstellen reicht erstmal.

---

## 9. Settings (Übersicht)

- **Allgemein**: Theme (System/Hell/OLED-Dark), Sprache, Schriftgröße.
- **Sicherheit**: App-Lock (Biometrie), Auto-Lock-Timeout.
- **Capture**: Standort automatisch mitspeichern, Sprache-Eingabe-Sprache, Audio-Format.
- **AI**: API-Keys (Anthropic / OpenAI / Gemini / OpenRouter), Default-Provider pro Aktion, Prompts editieren.
- **Hub-Tabs**: Tabs hinzufügen/anpassen/sortieren.
- **Tags**: Tag-Verwaltung (umbenennen, mergen, Farbe).
- **Erinnerungen**: Wochen-Notification an/aus, On-this-day an/aus, Random-Card an/aus.
- **Backup**: Manuell / Auto.
- **Über**: Version, Open-Source-Lizenzen, Privacy.

---

## 10. Tech-Stack

### 10.1 Framework & Sprache

- **Flutter 3.x** (latest stable)
- **Dart**
- **State Management:** Riverpod (`flutter_riverpod`, `riverpod_annotation`)
- **Routing:** `go_router`

### 10.2 Persistenz

- **drift** (SQLite-Wrapper, typsicher, FTS5-Support)
- **sqlite3_flutter_libs** + **sqlite_async** für `sqlite-vec`-Extension
- **path_provider** für Dateipfade

### 10.3 ML / On-Device-AI

- **onnxruntime** (oder `flutter_onnxruntime`) für Embedding-Inference
- Model: `multilingual-e5-small` (ONNX-Format, ~120 MB), wird beim ersten Start heruntergeladen
- **google_mlkit_text_recognition** (OCR)
- **google_mlkit_language_id** (Spracherkennung)
- **speech_to_text** (mit `onDevice: true`)

### 10.4 Capture & Media

- **camera** (Foto/Video)
- **image_picker** (Galerie)
- **record** (Audio-Aufnahme)
- **just_audio** (Audio-Wiedergabe)
- **geolocator** (Standort)
- **receive_sharing_intent** (Share-Target)
- **home_widget** (Homescreen-Widget)
- **metadata_fetch** oder **any_link_preview** (Open Graph)

### 10.5 Cloud-AI

- **dio** oder **http** für API-Calls
- Eigene leichte Wrapper-Klassen pro Provider (Anthropic, OpenAI, OpenRouter, Gemini)
- API-Keys verschlüsselt via **flutter_secure_storage**

### 10.6 UI

- **Material 3** Komponenten
- **flutter_markdown** (Anzeige)
- Eigener Markdown-Editor (leichtes Custom-Widget, kein fertiges Package erfüllt Obsidian-Wikilink-Anforderung)
- **flutter_local_notifications** (Erinnerungen)
- **share_plus** (Teilen)
- **pdf** + **printing** (PDF-Export)

### 10.7 Utility

- **uuid** (IDs)
- **intl** (Datum/Zahlen)
- **flutter_secure_storage** (API-Keys)
- **package_info_plus** (Versions-Info)

---

## 11. Berechtigungen (AndroidManifest)

- `INTERNET` — für Cloud-AI und Open-Graph-Fetch
- `CAMERA` — Foto-Capture
- `RECORD_AUDIO` — Audio-Capture
- `READ_MEDIA_IMAGES`, `READ_MEDIA_AUDIO` (Android 13+) — Galerie
- `ACCESS_FINE_LOCATION` (optional, nur wenn Geo aktiviert)
- `POST_NOTIFICATIONS` (Android 13+) — Erinnerungen
- `USE_BIOMETRIC` — App-Lock

---

## 12. Projekt-Struktur (Flutter)

```
lib/
├── main.dart
├── app.dart                          # MaterialApp + Router
├── core/
│   ├── constants.dart
│   ├── theme.dart
│   ├── router.dart
│   └── di.dart                       # Riverpod Provider-Root
├── data/
│   ├── db/
│   │   ├── database.dart             # Drift-DB-Definition
│   │   ├── tables/
│   │   │   ├── entries.dart
│   │   │   ├── tags.dart
│   │   │   ├── containers.dart
│   │   │   ├── attachments.dart
│   │   │   └── ...
│   │   └── daos/
│   ├── models/
│   ├── repositories/
│   │   ├── entry_repository.dart
│   │   ├── tag_repository.dart
│   │   ├── container_repository.dart
│   │   └── search_repository.dart
│   └── ml/
│       ├── embedding_service.dart    # ONNX Wrapper
│       ├── ocr_service.dart          # ML Kit Wrapper
│       └── stt_service.dart          # Speech-to-Text Wrapper
├── domain/
│   ├── usecases/
│   └── filters/
│       └── filter_definition.dart    # JSON-Schema für Hub-Filter
├── features/
│   ├── capture/
│   │   ├── widgets/
│   │   ├── capture_sheet.dart
│   │   └── capture_controller.dart
│   ├── feed/
│   │   ├── feed_screen.dart
│   │   ├── entry_card.dart
│   │   └── resurface_card.dart
│   ├── detail/
│   │   ├── entry_detail_screen.dart
│   │   ├── properties_editor.dart
│   │   └── ai_enrich_panel.dart
│   ├── projects/
│   ├── areas/
│   ├── hubs/
│   │   ├── hub_screen.dart
│   │   └── filter_builder.dart
│   ├── search/
│   │   ├── search_screen.dart
│   │   └── ask_notes_screen.dart     # RAG-Q&A
│   ├── settings/
│   │   ├── settings_screen.dart
│   │   ├── ai_settings.dart
│   │   ├── hub_settings.dart
│   │   └── backup_settings.dart
│   └── share_intent/
│       └── share_intent_handler.dart
├── services/
│   ├── ai/
│   │   ├── ai_provider.dart          # Abstract Provider
│   │   ├── anthropic_provider.dart
│   │   ├── openai_provider.dart
│   │   ├── openrouter_provider.dart
│   │   └── gemini_provider.dart
│   ├── notifications/
│   ├── backup/
│   │   ├── backup_service.dart
│   │   └── restore_service.dart
│   └── export/
│       ├── markdown_exporter.dart
│       └── pdf_exporter.dart
└── ui/
    ├── widgets/                       # Wiederverwendbare Komponenten
    └── markdown_editor/               # Custom Wikilink-Editor
```

---

## 13. Entwicklungs-Roadmap

### Phase 1: Grundgerüst (Sprint 1)
- Projekt-Setup, Riverpod, Routing
- Drift-DB inkl. FTS5-Tabellen und Trigger
- Basis-Datenmodell (Entries, Tags, Containers)
- Bottom-Nav mit 3 festen Tabs + FAB
- Feed-View: einfache Liste, neueste Einträge unten
- Quick-Text-Capture-Sheet (nur Text + Senden)
- Tag-Parser für `#tag` im Body

### Phase 2: Capture-Breite (Sprint 2)
- Foto-Capture (Kamera + Galerie)
- Audio-Capture (Long-Press)
- Speech-to-Text (on-device)
- OCR (ML Kit)
- URL-Capture mit Open-Graph
- Share-Intent IN
- Homescreen-Widget

### Phase 3: Smart-Lokal (Sprint 3)
- ONNX Runtime + Embedding-Model laden
- Embedding-Generierung bei jedem Eintrag
- sqlite-vec Integration
- Auto-Tag-Vorschläge
- Verwandte-Notizen-Vorschläge
- Hybrid-Suche (FTS5 + Vector)

### Phase 4: Container & Hubs (Sprint 4)
- Projekte/Bereiche CRUD
- Hub-Tab-System mit Filter-Builder
- Custom Properties UI
- Wikilink-Parser & Backlinks

### Phase 5: Cloud-AI & Sharing (Sprint 5)
- Provider-Abstraktion + Anthropic/OpenAI/OpenRouter/Gemini-Implementierungen
- Secure-Storage für API-Keys
- AI-Enrich-Aktionen (Zusammenfassen, Strukturieren, Tag-Vorschlag, Titel)
- Q&A über Notizen (RAG)
- Multi-Select & Teilen
- Markdown-Export, PDF-Export

### Phase 6: Resurface & Polish (Sprint 6)
- On-this-day Card
- Random Card
- Erinnerungen
- Wochen-Notification
- Backup/Restore
- App-Lock
- Settings vollständig

### Phase 7: Beta & Hardening (Sprint 7)
- Eigener Beta-Test auf S21 FE
- Performance-Tuning (Embedding-Cache, lazy loading)
- Crash-Reporting (optional via Sentry)
- Onboarding-Flow
- Erste Doku

---

## 14. Performance-Budgets (Zielwerte auf S21 FE)

| Aktion | Zielzeit |
|--------|----------|
| App-Start (cold) | < 2 s |
| Capture-Sheet öffnen | < 200 ms |
| Eintrag speichern (ohne Embedding) | < 50 ms |
| Embedding generieren | < 300 ms |
| Volltextsuche (10k Einträge) | < 100 ms |
| Semantische Suche (10k Einträge) | < 200 ms |
| OCR auf Foto | < 500 ms |
| Feed-Scroll | 60 fps |

---

## 15. Risiken & offene Punkte

1. **sqlite-vec auf Android via Flutter:** Funktioniert grundsätzlich, aber die Integration über `drift` benötigt einen Custom-Build oder das Laden der Extension via `sqlite_async`. Falls zu sperrig: Fallback auf einfache eigene Cosine-Similarity in Dart (für <10k Einträge noch performant).
2. **ONNX Runtime Flutter-Package-Reife:** Aktuell nicht so stabil wie native TFLite. Alternative: TFLite mit konvertiertem Embedding-Model.
3. **Whisper lokal (später):** Nur als Stretch. Erstmal Android-API.
4. **App-Größe:** Mit Embedding-Model und ML-Kit-Modellen wird die App ~150–250 MB groß. Akzeptabel.
5. **Wikilink-Editor:** Kein Off-the-shelf-Paket. Eigenimplementierung nötig (Cursor-Position bei `[[` → Autocomplete-Overlay).

---

## 16. Out of Scope (für v0.1)

- Multi-Device-Sync
- Desktop-Version
- Verschlüsselte E2E-Backups
- Geteilte Notizen / Multi-User
- Audio/Video-Editing
- Lokales generatives LLM (zu langsam auf S21 FE)
- Web-Clipper als Browser-Extension

---

## Anhang A: Beispiel-Workflows

### A.1 "Ich sehe ein interessantes YouTube-Video"
1. YouTube → Teilen → MindFeed.
2. Confirm-Sheet zeigt: Titel + Vorschaubild, Tag-Vorschläge `#video`, `#youtube`.
3. Speichern → Eintrag im Feed mit Link-Preview-Karte.
4. Im Hintergrund: Embedding berechnet.

### A.2 "Ich notiere mir schnell eine Idee in der U-Bahn"
1. Lock-Screen → Widget → "📝 Text".
2. Tippen oder Long-Press für Audio.
3. Speichern → erledigt.

### A.3 "Ich finde später meine Notiz zum Thema Stoizismus wieder"
1. Feed → Suchfeld → "stoizismus".
2. FTS5 + Semantic kombiniert → auch Einträge ohne das exakte Wort.
3. Tap auf Ergebnis → Detail-View mit Backlinks.

### A.4 "Wochenrückblick am Sonntag"
1. Notification: "12 neue Einträge diese Woche, 4 ungetaggt."
2. Tap öffnet Wochenrückblick-View.
3. Optional "✨ Wochenzusammenfassung generieren" (Cloud-LLM).

---

## Anhang B: Initiale Datenbank-Migrations-Reihenfolge

1. `001_initial_schema.sql` — entries, tags, containers, attachments, properties, links
2. `002_fts5.sql` — virtuelle FTS5-Tabelle + Trigger
3. `003_vec.sql` — virtuelle sqlite-vec-Tabelle
4. `004_default_data.sql` — Default-Hub-Tab "Inbox" (alle ungetaggten Einträge)

---

**Ende des Konzepts v0.1**

Übergabe an Claude Code: Dieses Dokument als Briefing in einem neuen Projekt-Ordner ablegen (`PROJECT.md` oder `docs/CONCEPT.md`). Empfohlener Einstieg in Claude Code:

> "Lies docs/CONCEPT.md. Starte mit Phase 1 der Roadmap: Projekt-Setup, Drift-DB mit FTS5, Basis-Datenmodell. Erstelle die Datei-Struktur gemäß Abschnitt 12. Wir gehen Phase für Phase vor."
