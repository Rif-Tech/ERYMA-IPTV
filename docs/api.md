# API MultIPTV (Supabase Edge Functions)

Base URL : `https://<projet>.supabase.co/functions/v1` (local : `http://127.0.0.1:54321/functions/v1`).
Toutes les réponses sont en JSON ; les erreurs ont la forme `{ "error": "message" }` avec un code HTTP 4xx/5xx.

Les fonctions côté appareil n'utilisent pas de JWT Supabase (`verify_jwt = false`) : l'authentification repose sur le couple **adresse MAC + clé appareil** généré par l'application.

## Appareil (app mobile / TV)

### `POST /device-register`
Enregistre ou met à jour un appareil.

```json
{ "mac": "02:AB:CD:12:34:56", "device_key": "ABC123", "device_type": "tv", "platform": "android", "app_version": "1.0.0" }
```
Réponse : statut de l'appareil.
```json
{ "registered": true, "activated": false, "is_trial": true, "expired": false, "trial_ends_at": "…", "expires_at": null, "device": { … } }
```
`409` si la MAC est déjà liée à une autre clé.

### `GET /device-playlists?mac=…&key=…`
Statut + playlists de l'appareil (vide si l'appareil est expiré).
```json
{ "status": { … }, "playlists": [ { "id": "…", "name": "…", "type": "xtream", "url": "http://…", "username": "…", "password": "…", "epg_url": null, "is_protected": false, "pin_code": null, "expires_at": null, "position": 0 } ] }
```

### `POST /device-playlists`
Crée une playlist depuis l'app : `{ mac, key, name, type, url, username?, password?, epg_url?, is_protected?, pin_code? }` → `{ playlist }`.

### `DELETE /device-playlists`
`{ mac, key, id }` → `{ ok: true }`.

### `GET /app-info`
```json
{ "app_status": "ok", "message": null, "min_version": "1.0.0", "latest_version": "1.0.0", "apk_link": null, "trial_days": 7 }
```
`app_status = "maintenance"` bloque l'app ; `min_version` supérieure à la version installée impose une mise à jour.

### `GET /featured?mac=…&key=…&mode=curated|popular|tmdb&lang=fr-FR`
Contenu du carrousel « À la une ». `curated` = sélection admin (`featured_items`), `popular` = titres les plus regardés sur 7 jours (`popular_titles()`), `tmdb` = tendances TMDB de la semaine. Réponse `{ mode, items: [{ id, kind: movie|tv|live|custom, tmdb_id, title, subtitle, overview, year, poster_url, backdrop_url, link_kind, link_query, require_match }] }`. La correspondance avec les playlists se fait **sur l'appareil** (titre normalisé + année) : le serveur ne voit jamais leur contenu.

### `GET /tmdb?action=search|trending|details&type=movie|tv&q=…&id=…&lang=…`
Proxy TMDB (la clé reste côté serveur). Authentification : appareil (`mac`/`key`) **ou** administrateur (`x-admin-token: <JWT Supabase>`). Renvoie `503` si `TMDB_API_KEY` n'est pas configurée.

### `POST /watch-events`
`{ mac, key, kind: movie|tv|live, title_key, title, year?, tmdb_id? }` → `{ ok }`. Statistique anonyme (aucune MAC ni URL de playlist stockée, seulement l'identifiant interne de l'appareil pour dédoublonner), un événement max par appareil/titre/heure, purge après 30 jours.

## Portail utilisateur (web)

### `POST /portal-login`
`{ mac, device_key }` → `{ token, status, device }`. Le jeton (HMAC-SHA256, 24 h) est stocké par le portail dans un cookie `httpOnly`.

### `/portal-playlists` (en-tête `Authorization: Bearer <token>` ou `x-portal-token`)
| Méthode | Corps | Réponse |
|---|---|---|
| `GET` | — | `{ status, device, playlists }` |
| `POST` | playlist | `{ playlist }` |
| `PUT` | `{ id, …champs }` | `{ playlist }` |
| `PATCH` | `{ order: [id, …] }` | `{ ok }` |
| `DELETE` | `{ id }` | `{ ok }` |

Validation : `type` ∈ `m3u | xtream` ; `url` en `http(s)://` ; `username`/`password` obligatoires pour Xtream ; `pin_code` de 4 à 8 chiffres si `is_protected`. Maximum 20 playlists par appareil.

## Administration
Le portail `/admin` utilise Supabase Auth (e-mail / mot de passe) et accède directement aux tables via RLS : seuls les profils `role = 'admin'` (table `profiles`) peuvent lire/écrire `devices`, `playlists`, `app_config` et `featured_items`. La vue `devices_with_status` expose le statut calculé par `device_status()`. La page `/admin/featured` gère le carrousel (recherche TMDB via la fonction `tmdb`, bannières personnalisées avec lien chaîne/film/série/URL, ordre, activation).

## Statut d'un appareil
- **Essai** : `now() < trial_started_at + trial_days` et non activé.
- **Activé** : `activated = true` et (`expires_at` nul ou futur).
- **Expiré** : ni l'un ni l'autre → l'app affiche « activation requise » et ne charge pas les playlists du portail.

## Secrets
- `PORTAL_TOKEN_SECRET` (secret Edge Functions) : clé de signature des jetons portail. À défaut, la clé service role est utilisée.
- `TMDB_API_KEY` (secret Edge Functions) : clé API v3 TMDB pour `tmdb` et les modes `tmdb`/`popular` de `featured`. Dashboard Supabase → Edge Functions → Secrets, ou `supabase secrets set TMDB_API_KEY=…`. Sans elle, l'app retombe sur le contenu local et le portail affiche « Clé TMDB non configurée ».
- Le portail Next.js a besoin de `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY` et éventuellement `SUPABASE_FUNCTIONS_URL`.
- L'app Flutter se configure avec `--dart-define=API_BASE_URL=… --dart-define=API_ANON_KEY=… --dart-define=PORTAL_URL=…`.
