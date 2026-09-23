# Feuille de route et dette connue

Document vivant. Coche un point traité, ajoute toute dette découverte pendant le travail. Voir [../CLAUDE.md](../CLAUDE.md) pour le cadre général.

## P0 — Sécurité backend

- [ ] **RPC `SECURITY DEFINER` sans REVOKE.** `confirm_pairing`, `set_device_context`, `ensure_account` et `expire_pairing_sessions` ([supabase/migrations/20260922000000_accounts.sql](../supabase/migrations/20260922000000_accounts.sql)) n'ont qu'un `GRANT ... TO service_role`, sans `REVOKE FROM public, anon, authenticated`. Elles seraient donc potentiellement appelables via `/rest/v1/rpc` avec la clé publishable embarquée dans l'APK, ce qui permettrait de rattacher un appareil au compte d'une victime en contournant `pairing-confirm`.
  - À vérifier en premier (lecture seule, sur le projet réel) : `select has_function_privilege('anon', 'public.confirm_pairing(uuid,text,text,jsonb)', 'execute');`.
  - Correction : nouvelle migration avec `revoke execute ... from public, anon, authenticated;`, sur le modèle de [20260921000100_harden_functions.sql](../supabase/migrations/20260921000100_harden_functions.sql).
- [ ] **Limites de plan contournables.** `max_profiles`/`max_playlists` et l'abonnement expiré ne sont vérifiés que par le portail, en deux temps non atomiques (compter puis insérer). La policy RLS « owner all » sur `viewer_profiles`/`playlists` permet de les dépasser via un appel PostgREST direct.
- [ ] **`devices: owner update` sans restriction de colonne.** Un propriétaire peut réécrire n'importe quelle colonne de son appareil via PostgREST, y compris réactiver un appareil révoqué (à condition de reposer `secret_hash`, que `authenticateInstall` exige).
- [ ] **Aucune limitation de débit** sur `pairing-create`/`pairing-confirm` : un code d'appairage (6 caractères, alphabet `ABCDEFGHJKMNPQRSTUVWXYZ23456789`, 10 min) peut en théorie être deviné par force brute.

## P0 — Fiabilité des données

- [ ] **Migration drift v2→v4 cassée.** Dans [apps/mobile/lib/core/db/database.dart](../apps/mobile/lib/core/db/database.dart), le bloc `if (from < 3)` crée l'index `history_recent` sur `profile_id`, colonne qui n'est ajoutée que par le bloc `if (from < 4)`. La v2 a existé (commits `12da42e`, `2738782`) ; seul le chemin v3→v4 est couvert par un test. À corriger et à tester depuis la v2.
- [ ] **`ProgressSync.schedule()` est un debounce, pas un throttle** ([apps/mobile/lib/core/sync/progress_sync.dart](../apps/mobile/lib/core/sync/progress_sync.dart)). Le lecteur écrit l'historique local toutes les 10 s et réarme ce debounce de 20 s à chaque écriture : en pratique, **rien ne part au serveur pendant la lecture**. L'envoi n'a lieu qu'à la fermeture du lecteur ou au prochain pull. Si le process est tué (box éteinte), la progression n'est jamais envoyée. Passer à un throttle.
- [ ] **Ids M3U instables.** Les ids d'éléments M3U (`streamId`/`episodeId` = `url.hashCode`) reposent sur `String.hashCode`, non garanti stable d'une version du SDK Dart à l'autre. Une montée de Flutter/Dart peut rendre orphelins favoris, historique et progression serveur pour toutes les playlists M3U. Envisager un hash stable (`package:crypto`) avec une migration de conversion.

## P1 — UX télécommande

- [ ] **Menu de chaîne inaccessible au D-pad.** `showChannelMenu` (favori, verrou, groupe) ne s'ouvre que par `onLongPress` ([apps/mobile/lib/features/live/live_screen.dart](../apps/mobile/lib/features/live/live_screen.dart)).
- [ ] **Vol de focus probable sur Films/Séries.** `BrowserScaffold` met un autofocus sur la catégorie 0 *et* sur l'élément 0 de la grille ([movies_screen.dart](../apps/mobile/lib/features/movies/movies_screen.dart)) ; le focus d'une catégorie la sélectionne aussitôt. À confirmer sur appareil, puis n'autofocaliser que le rail de catégories.
- [ ] **PIN des playlists protégées jamais demandé.** `is_protected`/`pin_code` sont copiés dans drift mais aucun code ne les vérifie ; seul un cadenas s'affiche.
- [ ] **`SessionGate` ne tolère que le chemin exact `/settings`** ([apps/mobile/lib/features/splash/session_gate.dart](../apps/mobile/lib/features/splash/session_gate.dart)) : les sous-routes `/settings/parental` et `/settings/groups` seraient renvoyées vers `/pairing`.
- [ ] **Secret d'installation et PIN parental en clair.** Le secret est toujours recopié en clair dans SharedPreferences (pas seulement en repli du secure storage). Le PIN parental (`AppSettings.parentalPin`) est aussi stocké en clair. À chiffrer ou à accepter comme risque documenté.

## P1 — Robustesse du lecteur et du réseau

- [ ] **Proxy DNS relancé à chaque réglage.** `activeDnsResolverProvider` observe tout `settingsProvider` sans `.select` : n'importe quel réglage (même le format d'image dans le lecteur) redémarre `DnsProxy` sur un nouveau port, alors que mpv garde l'ancien port lu dans `initState` — la lecture en cours casse avec un DNS personnalisé actif.
- [ ] **Watchdog d'écran noir (8 s) sur flux audio seul**, et ses drapeaux `directDecodeUnsupported`/`hardwareCopyUnsupported` ne sont jamais réinitialisés ([player_screen.dart](../apps/mobile/lib/features/player/player_screen.dart)).
- [ ] **Fin du dernier VOD** : le même titre est relancé au lieu de s'arrêter proprement.
- [ ] **Mode performance et lecteur.** `performanceModeProvider` ne pilote que les effets visuels des widgets, pas le buffer mpv (`isLowEndDeviceProvider`), pas le cache d'images (`lowEnd` de `main()`), pas le décodage (dépend de la détection TV). `README.md` affirme le contraire : à corriger dans la doc ou dans le code.
- [ ] **URL DoH à nom d'hôte** : cause plausible d'une boucle de résolution ; le portail n'impose que le préfixe `https://` ([apps/portal/app/admin/dns/actions.ts](../apps/portal/app/admin/dns/actions.ts)).

## P1 — Portail

- [ ] **Open redirect via `//` ou `/\`** sur `next`, login/signup et `/auth/callback` (seul `startsWith('/')` est vérifié ; un navigateur normalise `/\` en `//`).
- [ ] **Écritures non atomiques.** `saveProfileAction` remplace les accès playlist d'un profil par DELETE puis INSERT : une insertion en échec supprime tous les accès. `createPlaylistAction` ignore l'erreur d'insertion de `profile_playlists`.
- [ ] **Messages d'erreur non traduits** sur `/add-playlist` : seuls 6 codes sont traduits, les erreurs de `validatePlaylistInput` remontent en anglais.
- [ ] **Server Action exportées sans garde.** `describeError`/`normalizeCode` dans [app/pairing/actions.ts](../apps/portal/app/pairing/actions.ts) sont exportées d'un fichier `"use server"` sans protection : à déplacer hors de ce fichier.
- [ ] `'*.ts.net'` dans `allowedOrigins` ([next.config.ts](../apps/portal/next.config.ts)) ne couvre pas les hôtes MagicDNS avec port (il faudrait `**.ts.net:3000`) ; n'a d'effet que derrière un reverse-proxy qui réécrit `x-forwarded-host`.

## P2 — Fonctions de l'app d'origine à brancher ou à retirer

À trancher avec le propriétaire, voir [docs/apk-analysis.md](apk-analysis.md) pour la liste complète de Shamel TV.

- [ ] **Catch-up / TV archive** : les briques existent (`timeshiftUrl`, `PlaybackService.catchup()`) mais aucune UI ne les appelle.
- [ ] **Lecteur externe (VLC/MX Player)** : déclaré dans les `<queries>` du manifeste et dans les chaînes l10n, sans aucun code Dart.
- [ ] **Grille EPG** et tri par numéro de chaîne : non implémentés.
- [ ] **`flutter_foreground_task`, `file_picker`** : dépendances déclarées, jamais importées. Le manifeste garde un `ForegroundService` (« Recordings/downloads ») sans code associé : brancher l'enregistrement/téléchargement, ou retirer la dépendance et les permissions.
- [ ] **`NativePlatform.statFs`, `isInPipMode`** : jamais appelés côté Dart.

## P2 — Outillage

- [ ] **Aucune CI** (pas de `.github`) : ni `flutter analyze`/`test`, ni `tsc`/`lint` du portail, ni vérification des Edge Functions à chaque push.
- [ ] **Un seul environnement Supabase** (`zeproepijcixdmszlkmf` = dev = prod). `apps/portal/.env.local` et `.vscode/mcp.json` y pointent aussi. Un environnement de dev séparé réduirait le risque d'écriture accidentelle en prod.
- [ ] **IP LAN/Tailscale codée en dur** (`100.88.208.52:3000`) : valeur par défaut dans [config.dart](../apps/mobile/lib/app/config.dart), les scripts PowerShell, `next.config.ts` et `supabase/config.toml`. Un APK buildé sans `-PortalUrl` l'embarque. À remplacer par une URL HTTPS publique du portail.
- [ ] **Keystore release** : repli silencieux sur la clé debug si `key.properties` est absent ([apps/mobile/android/app/build.gradle.kts](../apps/mobile/android/app/build.gradle.kts)). Le chemin par défaut de l'exemple (`../multiptv-release.jks`) n'est pas ignoré par git — vérifier avec `git check-ignore -v` avant de générer un vrai keystore.
- [ ] **Versionnage jamais incrémenté** : `pubspec.yaml` reste à `1.0.0+1`, alors que la mise à jour forcée compare le versionName à `min_version`. Définir une politique de versionnage avant la première mise à jour forcée.
- [ ] **Symboles d'obfuscation non archivés** : `build-release.ps1` compile avec `--obfuscate --split-debug-info`, mais `build/symbols` est ignoré par git et écrasé à chaque build. Archiver ce dossier avec chaque APK publié.
- [ ] **`versionCode` par ABI vs universel incompatibles** : un appareil ayant reçu un APK par ABI (`--split-per-abi`) refuse l'APK universel publié en `apk_link` (`INSTALL_FAILED_VERSION_DOWNGRADE`). Choisir un seul canal de distribution par parc de box.

## Dette documentaire

- [ ] [docs/api.md](api.md) obsolète : section « Statut d'un appareil (legacy) », `PORTAL_TOKEN_SECRET` (plus utilisé), `dns_servers` absent de la réponse `app-info` documentée, `/admin/dns` absent de la liste des pages admin, `pairing-status` documenté comme répondant `410` alors qu'il répond `200 {status:'expired'}`.
- [ ] `apps/mobile/README.md` et `apps/portal/README.md` restés au gabarit par défaut (Flutter / create-next-app).
- [ ] Clés ARB en double (`accountExpired`, `account`) et clés orphelines héritées d'écrans supprimés ou jamais branchés (voir [apps/mobile/lib/l10n/app_en.arb](../apps/mobile/lib/l10n/app_en.arb)).
- [ ] [supabase/functions/.env.example](../supabase/functions/.env.example) ne cite que `PORTAL_TOKEN_SECRET` : à mettre à jour avec `TMDB_API_KEY` et `PORTAL_URL`.

## Questions ouvertes à trancher par le propriétaire

- Que désigne « ERYMA » (nom du dépôt) ? Faut-il renommer le produit, en gardant `com.multiptv.app` pour ne pas casser les mises à jour existantes ?
- iOS reste-t-il une cible réelle, ou le développement se concentre-t-il sur Android TV / Android ?
- Enregistrement/téléchargement : le manifeste et une dépendance foreground existent sans code — les brancher, ou nettoyer ?
- Paiement en ligne : aujourd'hui, l'activation d'un abonnement est manuelle (admin). Faut-il l'automatiser ?
- Faut-il un environnement Supabase de dev séparé de la production ?
