# API MultIPTV (Supabase Edge Functions)

Base URL : `https://<projet>.supabase.co/functions/v1` (local : `http://127.0.0.1:54321/functions/v1`).
Toutes les réponses sont en JSON ; les erreurs ont la forme `{ "error": "message" }` avec un code HTTP 4xx/5xx.

Les fonctions côté appareil n'utilisent pas de JWT Supabase (`verify_jwt = false`). Authentification par **identité d'installation** : en-têtes `x-device-id: <device_uuid>` + `x-device-secret: <secret>`. Le `device_uuid` est un UUID v4 généré une fois par installation ; le secret (32 octets aléatoires) est généré par l'app, seul son SHA-256 est envoyé lors de l'appairage et il ne devient valable qu'une fois l'appairage confirmé par le propriétaire du compte sur le web. Un appareil révoqué/supprimé (ou toute requête sans identité) reçoit `401 {"error":"UNPAIRED"}` : l'app efface son secret et revient à l'écran d'appairage.

## Comptes, appairage et profils

### `POST /pairing-create`
Ouvre une session d'appairage temporaire (10 min, usage unique). Aucune authentification pour `kind = device` ; identité d'installation requise pour `kind = playlist`.
```json
{ "kind": "device", "device_uuid": "…", "secret_hash": "<sha256 hex du secret>", "device_type": "tv", "platform": "android", "app_version": "2.0.0", "manufacturer": "Xiaomi", "model": "MIBOX4", "os": "Android TV", "os_version": "9" }
```
Un appareil déjà appairé doit fournir son secret (`x-device-secret`) pour ouvrir une nouvelle session (`401` sinon).
Réponse `201` : `{ session_id, code, token, expires_at, url }` — `code` = 6 caractères sans ambiguïté (`ABCDEFGHJKMNPQRSTUVWXYZ23456789`), `token` = jeton du QR code (`<PORTAL_URL>/activate?token=…` ou `/add-playlist?token=…`), `url` nul si le secret `PORTAL_URL` n'est pas configuré (l'app construit alors l'URL). Une nouvelle session annule les sessions en attente du même appareil.

### `GET /pairing-status?session_id=…&token=…`
Interrogé par l'appareil toutes les 2 s : `{ status: pending|confirmed|expired|cancelled, kind, expires_at, result: { device_id, playlist_id } }`. `404`/`410` si la session est inconnue ou expirée.

### `/pairing-confirm` (utilisateur connecté : `Authorization: Bearer <JWT Supabase>`)
- `GET ?code=…` ou `?token=…` → aperçu `{ kind, expires_at, device: { device_type, name, model, manufacturer, platform } }`.
- `POST { code|token, name?, playlist? }` → appelle la fonction SQL atomique `confirm_pairing` : verrou du compte, vérification de l'expiration, **limite d'appareils du plan** (`409 DEVICE_LIMIT`), abonnement expiré (`402 ACCOUNT_EXPIRED`), rattachement de l'appareil (promotion du `secret_hash`), accès accordé à tous les profils. Pour `kind = playlist` : `payload` = formulaire playlist (`400 PAYLOAD_REQUIRED`, `409 PLAYLIST_LIMIT`, `403 DEVICE_NOT_OWNED`). La session passe à `confirmed` et ne peut plus être réutilisée.

### `GET /device-session` (identité d'installation)
Tout ce dont l'app a besoin au démarrage :
```json
{ "device": { "id", "name", "device_type", "status" },
  "account": { "plan", "plan_name", "max_devices", "max_profiles", "max_playlists", "activated", "is_trial", "expired", "trial_ends_at", "expires_at" },
  "profiles": [ { "id", "name", "avatar", "is_kids", "position", "playlist_ids": […] } ],
  "playlists": [ … ],
  "context": { "profile_id", "playlist_id" } }
```
`playlists` est vide quand l'abonnement est expiré. `playlist_ids` = accès du profil (`profile_playlists`) ; l'app filtre localement.

### `PUT /device-context` (identité d'installation)
`{ profile_id, playlist_id }` → mémorise le contexte actif de l'appareil (`set_device_context`, vérifie la propriété et l'accès du profil).

### `/device-progress` (identité d'installation)
Reprise de lecture synchronisée, **toujours** indexée par `(profile_id, playlist_id, kind, item_id)` : un titre vu dans une playlist n'est jamais rapproché d'un titre d'une autre playlist, même homonyme.
- `GET ?profile_id=…&playlist_id=…[&since=ISO]` → `{ items: [{ kind, item_id, parent_id, position_ms, duration_ms, completed, last_watched_at }] }`
- `PUT { profile_id, playlist_id, items: […] }` → upsert (200 items max) ; `403 PROFILE_HAS_NO_ACCESS` si le profil n'a pas accès à la playlist.

## Fonctions communes (app mobile / TV)

### `GET /app-info`
```json
{ "app_status": "ok", "message": null, "min_version": "1.0.0", "latest_version": "1.0.0", "apk_link": null, "trial_days": 7, "portal_url": "https://portail.example.com" }
```
`app_status = "maintenance"` bloque l'app ; `min_version` supérieure à la version installée impose une mise à jour ; `portal_url` (config admin) remplace l'URL compilée dans l'app pour les QR codes et instructions.

### `GET /featured?mode=curated|popular|tmdb&lang=fr-FR` (identité d'installation)
Contenu du carrousel « À la une ». `curated` = sélection admin (`featured_items`), `popular` = titres les plus regardés sur 7 jours (`popular_titles()`), `tmdb` = tendances TMDB de la semaine. Réponse `{ mode, items: [{ id, kind: movie|tv|live|custom, tmdb_id, title, subtitle, overview, year, poster_url, backdrop_url, link_kind, link_query, require_match }] }`. La correspondance avec les playlists se fait **sur l'appareil** (titre normalisé + année) : le serveur ne voit jamais leur contenu.

### `GET /tmdb?action=search|trending|details&type=movie|tv&q=…&id=…&lang=…`
Proxy TMDB (la clé reste côté serveur). Authentification : identité d'installation **ou** administrateur (`x-admin-token: <JWT Supabase>`). Renvoie `503` si `TMDB_API_KEY` n'est pas configurée.

### `POST /watch-events` (identité d'installation)
`{ kind: movie|tv|live, title_key, title, year?, tmdb_id? }` → `{ ok }`. Statistique anonyme (aucune URL de playlist stockée, seulement l'identifiant interne de l'appareil pour dédoublonner), un événement max par appareil/titre/heure, purge après 30 jours.

## Portail utilisateur (web)

Le portail Next.js utilise Supabase Auth (e-mail / mot de passe, inscription ouverte, confirmation par e-mail, mot de passe oublié) et accède aux tables du compte **directement via RLS** (`auth.uid() = account_id`) : `viewer_profiles`, `profile_playlists`, `playlists`, `devices` (lecture, renommage, révocation, suppression), `watch_progress`. Pages : `/login`, `/signup`, `/forgot-password`, `/reset-password`, `/auth/callback`, `/activate?code|token` (appairage d'appareil), `/add-playlist?code|token` (ajout de playlist depuis un appareil), `/account` (appareils), `/account/profiles`, `/account/playlists`. Les seules fonctions appelées par le portail utilisateur sont `pairing-confirm` (avec le JWT de session).

Validation des playlists : `type` ∈ `m3u | xtream` ; `url` en `http(s)://` ; `username`/`password` obligatoires pour Xtream ; `pin_code` de 4 à 8 chiffres si `is_protected` ; nombre maximal fixé par le plan (`max_playlists`).

## Administration
Le portail `/admin` utilise Supabase Auth (e-mail / mot de passe) et accède directement aux tables via RLS : seuls les profils `role = 'admin'` (table `profiles`) peuvent lire/écrire `devices`, `playlists`, `app_config`, `featured_items`, `accounts`, `subscriptions`, `viewer_profiles`. La vue `devices_with_status` expose les appareils avec le compte propriétaire (`account_email`) ; la vue `accounts_overview` agrège plan, abonnement, compteurs et statut (`account_status()`). Pages : `/admin` (appareils), `/admin/accounts` + `/admin/accounts/[id]` (formule `trial`/`standard`, statut, expiration, note, révocation de tous les appareils), `/admin/featured`, `/admin/config`.

## Statut d'un compte
- **Essai** : `subscriptions.status = 'trial'` et `accounts.created_at + trial_days` dans le futur (plan `trial` : 3 appareils, 5 profils, 5 playlists).
- **Actif** : `status = 'active'` et (`expires_at` nul ou futur) — plan `standard` : 5 appareils, 5 profils, 20 playlists. L'activation est manuelle (admin).
- **Expiré** : sinon → `device-session` renvoie `account.expired = true` et aucune playlist ; l'app affiche « activation requise ».

## Statut d'un appareil (legacy)
- **Essai** : `now() < trial_started_at + trial_days` et non activé.
- **Activé** : `activated = true` et (`expires_at` nul ou futur).
- **Expiré** : ni l'un ni l'autre → l'app affiche « activation requise » et ne charge pas les playlists du portail.

## Secrets
- `PORTAL_URL` (secret Edge Functions, optionnel) : URL publique du portail, utilisée par `pairing-create` / `app-info` quand la clé `portal_url` de `app_config` (page `/admin/config`) est vide. Sans l'un ni l'autre, l'app utilise son propre `--dart-define=PORTAL_URL`.
- `PORTAL_TOKEN_SECRET` (secret Edge Functions) : clé de signature des jetons portail. À défaut, la clé service role est utilisée.
- `TMDB_API_KEY` (secret Edge Functions) : clé API v3 TMDB pour `tmdb` et les modes `tmdb`/`popular` de `featured`. Dashboard Supabase → Edge Functions → Secrets, ou `supabase secrets set TMDB_API_KEY=…`. Sans elle, l'app retombe sur le contenu local et le portail affiche « Clé TMDB non configurée ».
- Le portail Next.js a besoin de `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY` et éventuellement `SUPABASE_FUNCTIONS_URL`.
- L'app Flutter se configure avec `--dart-define=API_BASE_URL=… --dart-define=API_ANON_KEY=… --dart-define=PORTAL_URL=…`.
