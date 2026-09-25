# apps/mobile : app Flutter MultIPTV (Android TV d'abord)

Ce fichier ne contient que ce qui est propre à l'app. Le transverse (mission, flux, contrats, règles de travail) est dans [../../CLAUDE.md](../../CLAUDE.md).

## Où modifier quoi

Point d'entrée par type de demande (chemins relatifs à `lib/`). Ouvre ces fichiers d'abord ; élargis seulement si la modification l'exige.

| Demande | Fichiers |
|---|---|
| Carte / ligne de chaîne | `widgets/channel_tile.dart` ; ligne EPG, menu et liste Live : `features/live/live_screen.dart` |
| Affiches films/séries, cartes 16:9, bande de progression | `widgets/content_cards.dart` (effet de focus : `widgets/focusable_card.dart`) |
| Image réseau, fond flou | `widgets/app_image.dart` |
| Autres widgets partagés | `widgets/` : un fichier par famille, `common.dart` les réexporte |
| Étagère horizontale (accueil, recherche) | `widgets/shelf.dart` ; navigation verticale : `widgets/row_focus_chain.dart` |
| Rail de catégories Live/Films/Séries | `features/content/category_browser.dart` |
| Grille Films/Séries | `features/movies/movies_screen.dart` (Séries la réutilise via `series_screen.dart`) |
| Fiche film / série | `features/movies/movie_detail_screen.dart` (`DetailLayout` partagé), `features/series/series_detail_screen.dart` |
| Métadonnées d'un titre (infos Xtream, TMDB, favori) | `features/content/metadata_providers.dart` |
| Accueil : hero | `features/home/hero_carousel.dart`, `hero_items.dart` (diapos locales), `featured_provider.dart` (« À la une » distant) |
| Accueil : rangées | `features/home/home_screen.dart` |
| Recherche | `features/search/search_screen.dart`, `search_provider.dart`, requêtes `search*` de `core/db/database.dart` |
| Pagination, favoris, historique, EPG now/next | `features/content/content_providers.dart` |
| Lancer une lecture | `features/player/play.dart` |
| Lecteur : options mpv / décodage et repli | `features/player/mpv_tuning.dart` / `features/player/decode_policy.dart` |
| Lecteur : overlay (boutons, barre, EPG, erreur) | `features/player/player_controls.dart` ; état et touches : `player_screen.dart` |
| URL de flux | `core/player/playback.dart` (`StreamResolver`) |
| Réglage | `core/settings/settings.dart` + `features/settings/settings_screen.dart` (tuiles : `settings_tiles.dart`, DNS : `dns_settings_tiles.dart`) |
| Champ d'un modèle Xtream / du portail | `core/xtream/xtream_models.dart` / `core/api/portal_models.dart` |
| Champ stocké en base | `core/db/database.dart` (+ `build_runner`), `core/playlist/playlist_importer.dart`, `core/m3u/m3u_parser.dart` |
| Appel à une Edge Function | `core/api/portal_api.dart` (voir aussi les contrats partagés de la racine) |
| Boot, session, routage d'entrée | `features/splash/splash_screen.dart`, `session_navigation.dart`, `session_gate.dart` ; session : `features/playlists/playlists_provider.dart` |
| Routes, onglets | `app/router.dart`, `features/shell/app_shell.dart` |

## Stack et contraintes Android

- Flutter / Dart, Riverpod 3 **écrit à la main** (pas de codegen), go_router 17, drift, media_kit (mpv), dio.
- Android : `applicationId com.multiptv.app`, namespace `com.multiptv.multiptv` (voir la racine, ne change ni l'un ni l'autre isolément).
- Le manifeste garde, pour rester compatible Android TV et box modestes :
  - `LEANBACK_LAUNCHER` + `android:banner` ;
  - `touchscreen` et `leanback` en `required="false"` ;
  - `usesCleartextTraffic="true"` (panels IPTV souvent en HTTP, proxy DNS en loopback) ;
  - `largeHeap`, `launchMode="singleTop"`, `supportsPictureInPicture` (requis par `enterPip`) et un `configChanges` étendu.
- `MainActivity` force `FlutterRenderer.debugForceSurfaceProducerGlTextures = true` : la surface vidéo par défaut de Flutter (ImageReader, Android 10+) empêche les décodeurs Amlogic de démarrer et bloque le thread principal (ANR). Ne le retire pas sans retester la vidéo sur une Mi Box S.
- Les box 32 bits (Mi Box S…) n'acceptent que l'APK `armeabi-v7a`. Le release est buildé avec `--obfuscate --split-debug-info` : **archive `build/symbols` avec chaque APK publié**, sinon les crashs de prod sont illisibles (`flutter symbolize`).
- Sans `android/key.properties`, Gradle signe le release avec la **clé debug**, silencieusement. `build-release.ps1` affiche seulement un avertissement, il ne bloque pas.
- `--split-per-abi` donne un `versionCode` = 1000×ABI+N (armeabi-v7a 1001, arm64 2001, x86_64 4001), l'APK universel garde N. Publie un seul canal par parc de box, sinon `INSTALL_FAILED_VERSION_DOWNGRADE` en changeant de canal.

## Commandes (cwd `apps/mobile`, ou `..\..\scripts\*.ps1` depuis ici)

- `flutter analyze` ; `flutter test` ; `flutter test test/<fichier>_test.dart`.
- `flutter gen-l10n` : après toute modification de `lib/l10n/app_{en,fr}.arb`. `pubspec.yaml` a `generate: true` : `pub get`/`run`/`build` la relancent aussi.
- `dart run build_runner build --delete-conflicting-outputs` : après toute modification de `lib/core/db/database.dart`.
- `..\..\scripts\emulator.ps1 -Target tv` : démarre l'AVD `multiptv_tv` (doit déjà exister ; le script ne fait que régler `hw.dPad`/`hw.keyboard`/`hw.mainKeys`). Un émulateur déjà lancé n'est pas remplacé.
- `..\..\scripts\run-app.ps1 -Mode flutter [-PortalUrl http://<ip-lan>:3000]` : `flutter run` en debug, backend **prod** par défaut (seul `PORTAL_URL` est surchargé, pas `API_BASE_URL`).
  - `-Mode apk` installe l'APK x86_64 de `dist\` : **émulateur seulement**, `-PortalUrl` est ignoré. Sur une box ARM, `adb install -r dist\app-armeabi-v7a-release.apk` (ou arm64-v8a) à la main.
- `..\..\scripts\screenshot.ps1` : capture dans `logs\screenshots`, utile pour contrôler l'état du focus.
- `flutter run --dart-define=API_BASE_URL=… --dart-define=API_ANON_KEY=… --dart-define=PORTAL_URL=…` pour surcharger la config de build.

## Boot et session

- **Aucun redirect go_router.** L'accès se contrôle de façon impérative, à trois endroits :
  - `SplashScreen._boot` : restaure l'URL du portail, attend l'identité et le secret, `ProfileController.restore()`, puis `db.watchPlaylists().first`. Le serveur (`device-session`, timeout 20 s) n'est attendu **que** s'il manque une playlist locale **ou** un profil actif ; sinon on passe directement à `resumeNavigation`.
  - `resumeNavigation`/`redirectedBySession()`/`openPlaylist` ([session_navigation.dart](lib/features/splash/session_navigation.dart)) : sélectionne le profil ou la playlist, ou ouvre le sélecteur correspondant.
  - `SessionGate` : `unpaired` → `/pairing`, `blocked` (en ligne + compte expiré) → `/no-playlist`, `maintenance`/mise à jour requise → écran bloquant.
  - Toute nouvelle route d'entrée ou nouvel état de session se câble aux **trois**.
- `deviceSession()` s'attend **séparément** de `app-info`, jamais via `Future.wait` : une erreur groupée masquerait le 401.
- `ProviderScope(retry: (_, __) => null)` dans `main.dart` reste désactivé : Riverpod 3 réessaie sinon un provider en échec indéfiniment, ce qui ressemble à un chargement bloqué.
- Identité ([device_identity.dart](lib/core/device/device_identity.dart)) : secure storage, **toujours** recopié en clair dans SharedPreferences (pas seulement en repli) — ne considère pas ce secret comme protégé au repos. Le secret `pending` survit à un redémarrage ; il tourne sur `PairingNotifier.restart()` (`rotatePending`) et sur un `401 UNPAIRED`.

## Riverpod 3 : règles

- Providers écrits à la main : `Provider`, `NotifierProvider`, `AsyncNotifierProvider`, `.family`, `.autoDispose`. Tear-off `XxxNotifier.new`.
- `.autoDispose` réservé au contenu paginé ou paramétré ; session, appairage et réglages restent en vie.
- Après un `await` dans un Notifier : vérifie `ref.mounted` avant d'écrire l'état.
- N'attends jamais le `.future` d'un StreamProvider sans listener actif (Riverpod 3 le met en pause) : lis plutôt `db.watchX().first`.
- Dans un `ConsumerStatefulWidget` : lis les providers dans `initState`, garde-les en `late final`. **Jamais de `ref` dans `dispose()`.**

## Données (drift, [database.dart](lib/core/db/database.dart))

- Schéma et requêtes vivent dans `database.dart` (exception existante, à ne pas étendre : quelques update/delete dans [playlist_importer.dart](lib/core/playlist/playlist_importer.dart)).
- Toute donnée personnelle (favoris, historique, verrous, catégories masquées, groupes) filtre sur `profileId` **et** `playlistId`. Change de profil uniquement via `ProfileController.select` ; `''` désigne les données d'avant les profils, réclamées par `claimLegacyProfileData`.
- Migrations : bloc `if (from < N)` qui ne touche que ce qui existe à cette étape ; teste l'upgrade depuis **chaque version livrée** (la v2 a existé, voir [docs/roadmap.md](../../docs/roadmap.md)) avec `NativeDatabase.memory` + DDL brut.
- Import ([playlist_importer.dart](lib/core/playlist/playlist_importer.dart)) : insertions par lots de 500 ; parsing lourd dans `Isolate.run` au-delà de 256 Ko ; JSON Xtream lu via des accesseurs souples (`jStr`/`jInt`/…, [xtream_models.dart](lib/core/xtream/xtream_models.dart)) ; erreurs en `ImportException`. Épisodes Xtream chargés à la demande à la première ouverture d'une série, pas à l'import.
- `name_key == normalizeTitle(name)`, calculé à l'import : sert à la recherche et au matching « À la une ». Si tu modifies `normalizeTitle`, force un ré-import (`lastSyncedAt = null`).
- Playlists `source = local` (héritées d'avant le portail) : visibles par tous les profils, jamais synchronisées. Ne casse pas ce chemin sans décision produit.
- Synchronisation ([progress_sync.dart](lib/core/sync/progress_sync.dart)) : seulement pour les playlists `portal-*`. Le préfixe ne s'écrit que via [playlist_ids.dart](lib/core/playlist/playlist_ids.dart) (`portalPlaylistId`, `serverIdOf`, `serverPlaylistId`), jamais à la main ; les identifiants Xtream d'une playlist via `playlist.xtreamCredentials` (même fichier). Seuil « terminé » : `ProgressSync.isCompleted`, à réutiliser partout. `schedule()` est un **debounce** de 20 s, pas un throttle : si le lecteur le réarme toutes les 10 s, rien ne part avant la fermeture — voir la roadmap.

## Lecture et réseau

- Ouvre le lecteur uniquement via [play.dart](lib/features/player/play.dart) (`openPlayer`/`playChannels`/`playMovie`/`playEpisodes`), sauf le fallback de rétrogradation du décodage interne à `PlayerScreen`.
- URL construite uniquement par `StreamResolver` ([playback.dart](lib/core/player/playback.dart)), jamais stockée en base pour Xtream (les identifiants y transiteraient).
- Lecteur ([features/player](lib/features/player)) : `player_screen.dart` garde le state (cycle de vie mpv, overlay, seek, touches D-pad, progression) ; options mpv dans `tuneMpv` ([mpv_tuning.dart](lib/features/player/mpv_tuning.dart)), attendues avant `player.open` ; chemin de décodage initial, repli et classement des erreurs mpv dans [decode_policy.dart](lib/features/player/decode_policy.dart) (fonctions pures, `test/decode_policy_test.dart`) ; widgets de l'overlay dans [player_controls.dart](lib/features/player/player_controls.dart).
- Valeurs à haute fréquence (position, buffering) : `ValueNotifier`/`ValueListenableBuilder`, jamais un `setState` sur tout l'écran.
- DNS ([core/net](lib/core/net)) : le proxy loopback n'écoute que sur 127.0.0.1 ; les URL DoH doivent être des IP littérales (un nom d'hôte boucle sur lui-même). `activeDnsResolverProvider` observe **tout** `settingsProvider` sans `.select` : n'importe quel réglage relance le proxy sur un nouveau port pendant que mpv garde l'ancien — voir la roadmap avant d'y toucher. Le libellé `'Système'` sert de sentinelle en mode auto : ne le traduis pas sans introduire un id.
- Natif : un seul MethodChannel `'multiptv/platform'` ([native_platform.dart](lib/core/platform/native_platform.dart)) ; réponds `result.success(false)` si l'API demandée n'existe pas.
- **Logs diagnostiques** ([core/log](lib/core/log)) : `ref.read(appLoggerProvider).error/warn/info/debug(category, message, context:)` journalise en local (comme `debugPrint`) et vers `device-logs` (Supabase, table `app_logs`, 48h), avec debounce 15 s + flush au passage en arrière-plan. Ne couvre pas les crashs natifs (mpv/MediaCodec/pilote GPU) : c'est le rôle de Sentry (`main.dart`, projet `riftech/flutter` par défaut, désactivé par `--dart-define=SENTRY_DSN=` vide). N'y journalise jamais un identifiant, un mot de passe ou une URL de playlist.
- **Sentry** ([telemetry.dart](lib/core/log/telemetry.dart)) : `Telemetry.breadcrumb/context/tags/capture/exception/feedback`, tous sans effet sans DSN. `capture` crée une issue : réserve-le aux anomalies ; une action de l'utilisateur (test DNS) est un breadcrumb, un rapport est un `feedback` (Sentry → User Feedback). Chaque entrée `AppLogger` y est recopiée (breadcrumb + Sentry Logs, et un événement pour `warn`/`error`). `capture` est limité par empreinte (`throttle`) : un problème répété à chaque segment HLS ne doit pas vider le quota. Tout texte passe par `Telemetry.scrub` (une URL devient `schéma://hôte/…ext`) ; n'y passe jamais un titre. Les sondes : [remote_key_tracker.dart](lib/core/log/remote_key_tracker.dart) (chaque touche : chemin lisible avant/après, position une fois le défilement terminé, défilements, code qui a traité la touche ; alertes « focus perdu », « flèche sans effet » ×4 (sauf si un gestionnaire a noté une action ou si la liste est déjà au bout), « focus hors écran », « Gauche/Droite a quitté la rangée » (seulement depuis une liste horizontale `h#` : passer du rail de catégories à la grille est voulu)), [layout_audit.dart](lib/core/log/layout_audit.dart) (débordements `Row`/`Column`, texte multi-lignes tronqué, texte/image coupé au bord de l'écran, relancé après navigation ou 2 s d'inactivité de la télécommande), [playback_telemetry.dart](lib/features/player/playback_telemetry.dart) (format réel lu via mpv : codec, profil, résolution, HDR/Dolby Vision, bits, hwdec ; premier rendu, coupures, images perdues, proxy DNS contourné ou périmé), [telemetry_providers.dart](lib/app/telemetry_providers.dart) (route, appareil, compte, profil, playlist, réglages).

## UI TV

- **Traçabilité D-pad** : nomme toute nouvelle zone focusable avec `TraceTag('nom', child: …)` et tout nœud isolé avec `TraceTag.name(node, 'nom')` ([trace_tag.dart](lib/core/log/trace_tag.dart)) ; l'index dans les listes/grilles est trouvé automatiquement. Un gestionnaire `onKeyEvent` qui décide d'un déplacement appelle `RemoteKeyTracker.note('qui: quoi')`. Sans cela, Sentry ne voit que des coordonnées (les types sont obfusqués en release).

- Widgets focusables partagés, un fichier par famille dans [widgets/](lib/widgets) (`common.dart` les réexporte tous) : `FocusableCard` (focusable_card), `AppImage`/`BackdropArt` (app_image), `PosterCard`/`LandscapeCard`/`ProgressStrip` (content_cards), `ChannelTile` (channel_tile), `Shelf` (shelf), `PillButton` (pill_button), `LiveBadge`/`MetaBadge` (badges), `GlassPanel` (glass_panel), `Skeleton`/`EmptyState`/`AsyncView` (async_states). Un élément interactif est soit l'un d'eux, soit un bouton/`ListTile` Material thémé, soit un `InkWell` avec `onFocusChange` et un focus dessiné (modèle : `_CategoryItem`, [category_browser.dart](lib/features/content/category_browser.dart)). **Jamais un `GestureDetector` seul, jamais une action accessible uniquement par `onLongPress`.**
- Un seul autofocus **par FocusScope visible à la fois** — pas par écran : dans `BrowserScaffold` ([category_browser.dart](lib/features/content/category_browser.dart), partagé par Live, Films et Séries), c'est le rail de catégories qui le porte, jamais la grille.
- **Pages en rangées empilées** (accueil, recherche) : navigation verticale par `RowFocusChain` ([row_focus_chain.dart](lib/widgets/row_focus_chain.dart)) — une rangée = un `FocusScope` (qui retient sa dernière carte), rangées vides sautées, répétitions de touche gérées. Défilement vertical : `revealSection` uniquement (la section entière visible, déplacement minimal, jamais centrée, rien quand elle est déjà visible) ; ne rajoute pas de `ensureVisible(alignment: 0.5)` sur une carte. Défilement horizontal d'une rangée : `revealInRow` (même fichier), appelé par `Shelf` à chaque focus de carte, quel que soit le code qui a donné le focus.
- Ouvrir une page depuis la barre d'onglets la remet à zéro (`go()` d'`app_shell.dart`) : route racine, catégorie « Tout », recherche vidée, défilements à 0, focus en haut à gauche, et `pageResetProvider` pour les pages qui gardent une mémoire de focus (rangées de l'accueil).
- Deux FocusScopes reliés par `_TvFocusBridge` ([app_shell.dart](lib/features/shell/app_shell.dart)) : la barre d'onglets (`kTopBarHeight`, `_destinations`) et le contenu. Avant d'entrer dans un scope, cherche `scope.focusedChild ?? topLeftFocusable(scope)` ; n'appelle jamais `requestFocus` s'il n'y a rien à focaliser.
- Les onglets hors écran restent montés (`Offstage` + `TickerMode(false)` + `ExcludeFocus`, [router.dart](lib/app/router.dart)) : pas d'animation ni de focus possible hors de l'onglet actif.
- `onKeyEvent` : ignore `KeyUpEvent` sauf besoin explicite (le seek du lecteur se valide au relâchement) ; ne renvoie `handled` que si l'action a eu lieu.
- Jetons de design via `context.tokens` ; tout effet coûteux (flou, ombre, fondu, shimmer, animation perpétuelle) lit `performanceModeProvider` (`responsive.dart`) — il ne pilote que les effets **visuels** des widgets, pas le buffer mpv (`isLowEndDeviceProvider`) ni le cache d'images (`lowEnd` de `main()`) ni le décodage (dépend de la détection TV).
- Passe toujours `decodeWidth` à `AppImage`.
- Listes longues : `itemExtent` fixe, `addAutomaticKeepAlives:false`, `addRepaintBoundaries:false`, pagination par `onNearEnd`.
- Choix d'une énumération dans les réglages : `SettingsEnumTile` ([settings_tiles.dart](lib/features/settings/settings_tiles.dart)) ; tuiles DNS dans [dns_settings_tiles.dart](lib/features/settings/dns_settings_tiles.dart).
- Détection TV via `isTelevisionProvider` (leanback/television), **jamais** par la taille d'écran.

## l10n

- Tout texte d'UI passe par `AppLocalizations.of(context)` : il n'y a pas d'extension `context.l10n`.
- Toute clé doit exister dans **les deux** ARB ([app_en.arb](lib/l10n/app_en.arb) template, [app_fr.arb](lib/l10n/app_fr.arb)), puis `flutter gen-l10n`. Ne laisse pas de clé orpheline (dette déjà présente, voir la roadmap).

## Checklists

**Nouvel écran ou widget TV**
- Uniquement des widgets focusables partagés ou thémés (voir « UI TV »).
- Un seul autofocus par FocusScope visible, focus toujours dessiné.
- Retour (D-pad) géré explicitement.
- Aucune action accessible seulement par appui long.
- Textes dans les deux ARB, puis `flutter gen-l10n`.
- Effets coûteux conditionnés à `performanceModeProvider`.
- Vérifié sur `..\..\scripts\emulator.ps1 -Target tv`, capture via `screenshot.ps1`.
- Nouvel onglet : branche du `StatefulShellRoute` **et** `_destinations` de `app_shell.dart`, dans le même ordre.
- Nouvelle route d'entrée ou état de session : câblage dans `_boot`, `resumeNavigation` **et** `SessionGate`.

**Nouveau réglage**
- Champ dans `AppSettings` ([settings.dart](lib/core/settings/settings.dart)) avec `copyWith`.
- Lu dans `build()`, écrit dans `_persist`, setter dédié.
- Enum stocké par `.name`, avec une valeur de repli.

**Changement de schéma drift**
- `schemaVersion` incrémenté, nouveau bloc `if (from < N)`.
- `build_runner` relancé, `database.g.dart` commité avec la source.
- Test d'upgrade depuis chaque version livrée.
- Filtre `profileId` + `playlistId` sur toute nouvelle donnée perso.
