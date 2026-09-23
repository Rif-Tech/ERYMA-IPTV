# CLAUDE.md : MultIPTV (dépôt ERYMA-IPTV)

Ce fichier donne le cadre de tout le dépôt. Selon le dossier où tu travailles, lis aussi le fichier de la zone concernée :
- [apps/mobile/CLAUDE.md](apps/mobile/CLAUDE.md) ;
- [apps/portal/CLAUDE.md](apps/portal/CLAUDE.md) ;
- [supabase/CLAUDE.md](supabase/CLAUDE.md).

Les priorités et la dette connue sont dans [docs/roadmap.md](docs/roadmap.md).

Les fichiers et les symboles cités ici sont à relire avant d'agir. `[À CONFIRMER]` marque une décision ouverte : pose la question au lieu de trancher.

## 1. Mission et principes directeurs

- **Le produit.** MultIPTV est un lecteur IPTV (M3U / Xtream Codes). Il comprend trois parties :
  - une app Flutter ;
  - un portail web de gestion ;
  - un backend Supabase.

  Le dépôt s'appelle ERYMA-IPTV, mais « ERYMA » n'apparaît nulle part dans le code [À CONFIRMER : futur nom ?].
- **Android TV d'abord.** La cible n° 1, ce sont les box et TV Android pilotées à la télécommande : D-pad, OK, Retour, CH+/CH-.
  - Une fonctionnalité n'est terminée que si elle s'utilise **entièrement au D-pad**, sur une box 32 bits (Mi Box S) avec 2 Go de RAM et un Android ancien.
  - Le mobile et la tablette Android viennent ensuite.
  - iOS n'est qu'un squelette Flutter, sans Podfile, et les API natives (PiP, statFs) n'existent que sous Android. Ce n'est pas une priorité.
- **Aucun contenu fourni.** L'app lit seulement les sources de l'utilisateur. N'ajoute jamais de source, de catalogue ni de lien vers du contenu.
- **Confidentialité des playlists.** Le serveur ne voit jamais le contenu d'une playlist.
  - Le rapprochement « À la une » ↔ catalogue se fait sur l'appareil : titre normalisé + année.
  - `watch_events` ne stocke ni URL ni contenu. Il est seulement pseudonyme (`device_id`, `account_id`).
- **Hors ligne d'abord.** Si les données locales suffisent, le démarrage n'attend pas le réseau. Le verdict du serveur (maintenance, mise à jour forcée, expiration, révocation) est appliqué ensuite.
- **Identité d'un appareil = `device_uuid` + secret d'installation.** L'ancien modèle MAC / device key / activation par appareil, copié de l'app d'origine, a été supprimé ([drop_legacy](supabase/migrations/20260923000000_drop_legacy.sql)). **Ne le réintroduis jamais.**
- **Playlists ajoutées depuis le web uniquement**, sur `/account/playlists`. L'app n'a aucun formulaire de saisie.
- **Références.**
  - Doc produit : [README.md](README.md).
  - Contrat d'API : [docs/api.md](docs/api.md), en partie obsolète (voir la roadmap).
  - App d'origine, Shamel TV (modèle IBO Player Pro) : [docs/apk-analysis.md](docs/apk-analysis.md).

## 2. Carte du monorepo

| Zone | Stack | Rôle |
|---|---|---|
| [apps/mobile](apps/mobile) | Flutter / Dart 3.13, Riverpod 3 (sans codegen), go_router 17, drift, media_kit (mpv), dio | App TV, mobile et tablette |
| [apps/portal](apps/portal) | Next.js 16, React 19, Tailwind 4, @supabase/ssr | Compte utilisateur (`/account`, `/activate`) et admin (`/admin/*`) |
| [supabase](supabase) | Postgres + RLS, Edge Functions Deno | API appareil, appairage, synchro, configuration |
| [scripts](scripts) | PowerShell | emulator, run-app, screenshot, build-release, deploy-functions, smoke-test |

**Nommage.** Le produit s'appelle `MultIPTV` et le package Dart `multiptv`.
- **`applicationId com.multiptv.app` est immuable** : les APK installés hors Play Store ne pourraient plus être mis à jour.
- Il diffère volontairement du namespace Kotlin `com.multiptv.multiptv`.

## 3. Flux de bout en bout

1. **Appairage**
   - L'app génère `device_uuid` + secret, puis appelle `pairing-create` avec `secret_hash = sha256(secret)`.
   - Elle affiche un QR code `<portal_url>/activate?token=…` et un code à 6 caractères (10 min, usage unique), puis interroge `pairing-status` toutes les 2 s.
   - L'utilisateur confirme sur `/activate`. La chaîne d'appels est : Server Action → Edge Function `pairing-confirm` (JWT) → fonction SQL atomique `confirm_pairing`.
2. **Session**
   - `device-session` (en-têtes `x-device-id` / `x-device-secret`) renvoie l'appareil, le compte, les profils avec leurs `playlist_ids`, les playlists (vides si le compte a expiré) et le contexte.
   - Les playlists sont copiées dans drift sous l'id `portal-<uuid>`.
   - `app-info` (portal_url, dns_servers, min_version, app_status) est appelé à côté.
3. **Profil puis playlist**
   - Un seul profil, ou une seule playlist, est sélectionné automatiquement ; sinon l'app ouvre un sélecteur.
   - `PUT device-context`, puis pull de la progression.
4. **Import** : Xtream par étapes (live, VOD, séries), M3U parsé dans un isolate, EPG XMLTV optionnel.
5. **Lecture** : `play.dart` ouvre `/player` (mpv). L'historique local est écrit toutes les 10 s, puis `ProgressSync` l'envoie par `PUT device-progress` dans `watch_progress`.
6. **Révocation**
   - Depuis `/account`, l'appareil passe à `status='revoked'`, avec `secret_hash=null` et un contexte remis à null.
   - L'appel suivant reçoit `401 {"error":"UNPAIRED"}`.
   - L'app efface alors son secret et les playlists `portal-*`, puis revient à `/pairing`.

## 4. Commandes essentielles

Le poste tourne sous **Windows PowerShell 5.1** : `&&` n'y existe pas, enchaîne avec `cmd1; if ($?) { cmd2 }`. Git Bash est aussi disponible.
- **Présents** : Flutter (`C:\src\flutter`), Android SDK / adb (`C:\src\android-sdk`), JDK 17 (`C:\src\jdk17`), Node 24.
- **Absents** : Docker, Deno, CLI `supabase` global et `gh`. Utilise `npx supabase …`. Sans Docker, pas de stack Supabase locale.

| Zone (cwd) | Commande | Rôle |
|---|---|---|
| `apps/mobile` | `flutter analyze` ; `flutter test` | Lint et tests unitaires |
| `apps/mobile` | `flutter gen-l10n` ; `dart run build_runner build --delete-conflicting-outputs` | Régénère les fichiers versionnés (l10n, drift) |
| `apps/portal` | `npx tsc --noEmit -p .; if ($?) { npm run lint }` | Validation |
| `apps/portal` | `npm run dev` / `npm run panel` | Dev / build + start sur 0.0.0.0:3000 (tests depuis une TV) |
| racine | `.\scripts\emulator.ps1 -Target tv` ; `.\scripts\run-app.ps1` ; `.\scripts\screenshot.ps1` | Émulateur TV, lancement, capture |
| racine | `.\scripts\build-release.ps1 -PortalUrl https://…` | APK release par ABI + APK universel dans `dist\` |

**⚠ Tout ce qui suit touche la PROD.** Il n'existe qu'un seul projet Supabase, `zeproepijcixdmszlkmf`, et c'est la production. Lance ces commandes **uniquement sur demande explicite** :
- `.\scripts\deploy-functions.ps1` ;
- `.\scripts\smoke-test.ps1`, qui **crée** un appareil et une session d'appairage ;
- `npx supabase db push`, `functions deploy`, `secrets set` ;
- les outils MCP Supabase (`.vscode/mcp.json` pointe sur la prod) : `apply_migration`, `deploy_edge_function`, et `execute_sql` en écriture.

Pour la même raison :
- `apps/portal/.env.local` pointe aussi sur la prod : `npm run dev` manipule de vraies données.
- L'app pointe sur la prod par défaut (`--dart-define` dans [config.dart](apps/mobile/lib/app/config.dart)).

## 5. Invariants transverses (ne jamais casser)

- **Secret d'installation.** Seul son SHA-256 quitte l'appareil. Le serveur ne stocke que le hash.
- **Désappairage.**
  - Les fonctions appareil authentifiées renvoient `401 {"error":"UNPAIRED"}` pour toute identité invalide ou révoquée. C'est le **seul** signal que l'app interprète comme un désappairage : `PortalApiException`, avec 401 + `UNPAIRED`.
  - N'utilise pas ce code pour autre chose, et ne change pas sa forme.
- **Rattachement.** Un appareil, ou une playlist ajoutée par code, se rattache à un compte **uniquement** via `confirm_pairing`. Ses contrôles sont atomiques : verrou du compte, ACCOUNT_EXPIRED, DEVICE_LIMIT, PLAYLIST_LIMIT.
- **Autorisation.**
  - Les Edge Functions tournent avec la clé service role, qui contourne RLS. Chacune authentifie et autorise donc l'appelant **avant** toute requête.
  - Le portail n'utilise que la clé anon + la session utilisateur, et RLS est sa frontière. **Jamais de clé service_role dans le portail ni dans l'app.**
- **Scoping des données.**
  - Favoris, historique, verrous, catégories masquées, groupes et progression sont indexés par **(profil, playlist)**.
  - Un titre vu dans une playlist n'est **jamais** rapproché d'une autre playlist, même homonyme.
- **Seuils partagés.**
  - Un titre est « terminé » à **95 %** : côté app et dans `device-progress`.
  - Un envoi de progression fait **200 lignes au maximum**.
- **`portal_url`.** Elle est encodée dans les QR codes. Ordre de priorité : `app_config`, puis le secret `PORTAL_URL`, puis `--dart-define`. **Elle ne doit jamais valoir localhost.** Aujourd'hui, seul `build-release.ps1` le vérifie.
- **Les playlists du compte ne sont pas livrées à un compte expiré** (`device-session`).

### Contrats partagés : toute modification touche **tous** les côtés dans le même changement

| Contrat | Emplacements |
|---|---|
| Codes d'erreur | `mapSqlError` ([_shared/device.ts](supabase/functions/_shared/device.ts)), table de traduction FR de [pairing/actions.ts](apps/portal/app/pairing/actions.ts), `PortalApiException` ([portal_api.dart](apps/mobile/lib/core/api/portal_api.dart)) |
| URL d'appairage | `/activate?token=|code=`, `/add-playlist?token=|code=` : [config.dart](apps/mobile/lib/app/config.dart), `pairing-create`, pages du portail |
| Clés d'avatar | blue, red, green, orange, purple, pink, teal, yellow : portail et `profile_picker_screen.dart`. Aucune validation serveur : l'app retombe sur blue |
| Serveurs DNS | JSON `DnsServer` (app-info ↔ `fromJson`), `kBuiltinDnsServers` ↔ l'insert de la migration `dns_servers`. Les ids ne sont **pas** partagés |
| Clés `app_config` | `saveConfigAction` + `admin/config/page.tsx` + `app-info` + client Dart. `trial_days` reste un nombre JSON |
| Validation d'une playlist | Portail (`account/actions.ts`) et `validatePlaylistInput` + `convertGetPhp` (`_shared/playlists.ts`). **Divergent aujourd'hui** : tout changement doit les faire converger |

**Checklist d'un changement de contrat**
1. Migration SQL (voir [supabase/CLAUDE.md](supabase/CLAUDE.md)).
2. Edge Function.
3. Client Dart et ses modèles : reste compatible avec les caches SharedPreferences déjà écrits.
4. Portail : actions et traductions.
5. **[docs/api.md](docs/api.md), et [README.md](README.md) si le flux change.**
6. Extension de `smoke-test.ps1` si c'est pertinent.
7. Déploiement **seulement sur demande**.

## 6. Direction et priorités

Le détail, avec les fichiers et les cases à cocher, est dans [docs/roadmap.md](docs/roadmap.md). En résumé :

1. **Sécurité backend** : REVOKE sur les RPC `SECURITY DEFINER` exposées, limites de plan imposées en base, colonnes de `devices` protégées.
2. **Données fiables** : migration drift v2→v4 cassée, sync de progression qui ne part pas pendant la lecture, ids M3U instables.
3. **UX télécommande** : actions accessibles uniquement par appui long, vol de focus, PIN des playlists protégées.
4. **Robustesse du lecteur** : proxy DNS relancé à chaque réglage, watchdog d'écran noir, fin de VOD.
5. **Fonctions de l'app d'origine** à brancher ou à retirer : catch-up, lecteur externe, grille EPG…
6. **Outillage** : CI, environnement Supabase de dev, URL HTTPS du portail, keystore et versionnage.

**Tiens la roadmap à jour.** Coche un point traité. Ajoute toute dette découverte au lieu de la corriger hors périmètre.

## 7. Règles de travail pour Claude

- **Vérifier avant d'affirmer.**
  - Lis le code avant de décrire un comportement.
  - Distingue ce qui est « vérifié » de ce qui est « plausible ».
  - N'invente ni colonne, ni endpoint, ni provider.
- **PROD** : rien d'irréversible ni d'externe sans demande explicite (voir §4).
- **Fichiers générés.**
  - `apps/mobile/lib/core/db/database.g.dart` et `apps/mobile/lib/l10n/generated/*` ne s'éditent jamais à la main : régénère-les et commite-les **avec** leur source.
  - `flutter pub get`, `run` et `build` régénèrent aussi l'l10n (`generate: true`).
- **Migrations** : ne modifie jamais une migration déjà appliquée ; crée-en une nouvelle.
- **Secrets.**
  - Jamais de `key.properties`, `*.jks`, `.env*` (sauf `.env.example`) ni `.vscode/mcp.json` dans git.
  - `*.jks` et `key.properties` ne sont ignorés que sous `apps/mobile/android/`. Vérifie avec `git check-ignore -v <fichier>` avant tout ajout.
- **Hors produit.** Ne parcours pas et ne commite pas `apk_extracted/`, `temp/` (~370 Mo d'APK de référence), `dist/`, `logs/`, `apk_*strings.txt`.
- **Formatage.** Pas de `dart format` ni de prettier sur des fichiers entiers : le code dépasse souvent 80 colonnes et le diff serait noyé. Respecte le style des lignes voisines.
- **Commits.**
  - Conventional Commits, en anglais, à l'impératif, en minuscules : `feat(player): …`, `fix(pairing): …`.
  - Types utilisés : feat, fix, chore, docs, refactor, test.
  - **Un sujet par commit.** Ne reproduis pas les commits agrégés de l'historique (plus de 100 fichiers, toutes zones confondues).
  - Ne commite ou ne pousse que sur demande.
- **Langues.**
  - Code, identifiants et commentaires en anglais ; les commentaires expliquent le « pourquoi ».
  - README, `docs/*` et UI du portail en français.
  - UI de l'app en fr **et** en.
- **Documentation** : un changement de flux, de contrat ou de commande met à jour `README.md`, `docs/api.md` ou le CLAUDE.md concerné **dans le même changement**.
- **Style** : reproduis les patterns existants (voir les CLAUDE.md de zone). Signale la dette hors périmètre sans la corriger en passant.
- **Toute modification d'UI** s'évalue dans cet ordre :
  1. utilisable au D-pad ?
  2. supportable par une box modeste ?
  3. le hors-ligne marche-t-il ?

  Vérifie sur l'émulateur TV (`emulator.ps1 -Target tv`, puis `screenshot.ps1`).
