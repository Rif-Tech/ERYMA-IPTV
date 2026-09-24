# supabase : Postgres + RLS + Edge Functions Deno

Ce fichier ne contient que ce qui est propre au backend. Le transverse est dans [../CLAUDE.md](../CLAUDE.md).

> **`zeproepijcixdmszlkmf` est le seul projet Supabase, et c'est la PRODUCTION.** `db push`, `functions deploy`, `secrets set` et les outils MCP en écriture ne se lancent que sur demande explicite. Travaille en local avec `npx supabase start` puis `npx supabase db reset` (Docker requis — absent de ce poste, à vérifier avant de t'appuyer dessus). **N'applique jamais `seed.sql` au cloud** : il crée `admin@multiptv.local` / `multiptv-admin` (rôle admin) et `user@multiptv.local` / `multiptv-user`.

## Modèle de données

- **`profiles`** (id = `auth.users`, rôle `admin`/`user`, lu par `is_admin()`) ≠ **`viewer_profiles`** (profils de visionnage : `account_id`, name, avatar, `is_kids`, position). Ne les confonds pas.
- **Comptes et plans** : `accounts` 1-1 avec `subscriptions` (`plan_id` → `plans`, status trial/active/expired/cancelled, `expires_at`). Plans : `trial` (3 appareils, 5 profils, 5 playlists), `standard` (5, 5, 20).
  - L'essai se calcule depuis `accounts.created_at + app_config.trial_days`, **pas** depuis `subscriptions.started_at` : changer `trial_days` dans `/admin/config` déplace rétroactivement la fin d'essai de tous les comptes en essai.
  - Source de vérité du statut : `account_status()` (`accounts.sql`).
- **Playlists** : `type` m3u|xtream, `is_protected`/`pin_code`. `profile_playlists` : un trigger garantit que le profil et la playlist appartiennent au même compte.
- **Appareils et appairage** : `devices` (`device_uuid` unique, `secret_hash`, status active/revoked), `pairing_sessions` (kind device|playlist, code unique parmi les sessions pending, `token_hash`, `secret_hash`, TTL 10 min).
- **`watch_progress`** : unique sur `(profile_id, playlist_id, kind, item_id)`, un trigger exige l'accès via `profile_playlists`.
- **`watch_events`** : pseudonyme, pas anonyme — chaque ligne porte `device_id` **et** `account_id` (dédoublonnage par appareil/titre/heure). Purge à 30 jours **opportuniste** : `purge_watch_events()` se déclenche environ une fois sur 50 dans `watch-events`, pas sur un cron. Supprimer un appareil supprime en cascade ses `watch_events` (perte de l'historique « populaires »).
- **`app_logs`** : logs diagnostiques par appareil/compte (niveau, catégorie, message, `context` jsonb), même pattern que `watch_events` — purge à 48h opportuniste (`purge_app_logs()`, ~1 appel sur 20 dans `device-logs`), lecture admin/`service_role` seulement. Ne couvre pas les crashs natifs (voir Sentry, `apps/mobile/lib/main.dart`).
- **Configuration** : `app_config` (clé → jsonb, non validée par un CHECK), `featured_items`, `dns_servers` (un seul `is_default`).
- **Vues** `security_invoker` : `devices_with_status`, `accounts_overview`. Après un `ALTER` de la table source, supprime puis recrée la vue **et** son `GRANT`.

## Edge Functions (`/functions/v1`, toutes `verify_jwt = false` dans [config.toml](config.toml))

| Fonction | Authentification |
|---|---|
| `app-info`, `pairing-status` | Aucune (anonyme par conception) |
| `pairing-create` | Aucune pour `kind=device` ; identité d'installation pour `kind=playlist` ou un ré-appairage |
| `device-session`, `device-context`, `device-progress`, `featured`, `watch-events`, `device-logs` | Identité d'installation (`x-device-id` + `x-device-secret`) |
| `tmdb` | Identité d'installation **ou** admin (`x-admin-token`) |
| `pairing-confirm` | JWT utilisateur (Bearer) |

Les fonctions anonymes par conception (`app-info`, `pairing-status`, `pairing-create` kind device) n'ont **aucune limitation de débit** : toute logique ajoutée doit rester sûre pour un appelant anonyme.

**Squelette recommandé pour une nouvelle fonction** (voir [_shared/http.ts](functions/_shared/http.ts)) : contrôle de méthode (405) → authentification (**avant** toute requête) → `adminClient()` → `json()`/`HttpError`. `device-progress` et `pairing-confirm` s'en écartent (ils gèrent plusieurs méthodes après authentification) : ne reproduis pas cette exception dans du nouveau code.

- **Authentification** : uniquement via [_shared/device.ts](functions/_shared/device.ts) — `readInstallCredentials`, `authenticateInstall`/`authenticateAny`, `authenticateUser`, `authenticateAdmin`, `authenticateDeviceOrAdmin`. Ne réimplémente pas la comparaison de hash (`safeEqual`) ; `_shared/http.ts` a aussi un `safeEqualStr` (utilisé par `pairing-status`) qui fait doublon — à fusionner un jour, pas à supprimer à l'aveugle.
- **Erreurs** : `{ "error": "CODE_UPPER_SNAKE" }`. En SQL : `raise exception 'CODE' using errcode = 'P0001'`. Tout nouveau code s'ajoute à `mapSqlError` ([_shared/device.ts](functions/_shared/device.ts)) **et** à la traduction du portail ([pairing/actions.ts](../apps/portal/app/pairing/actions.ts)).
  - `401 UNPAIRED` : identité absente/inconnue/révoquée/sans compte, ou mauvais secret, **dans les fonctions appareil authentifiées**. Un `device_uuid` mal formé donne `400`. `pairing-create` (kind device) renvoie un 401 au message différent quand le secret manque pour un ré-appairage.
  - Codes courants : `PAIRING_NOT_FOUND` (404), `PAIRING_EXPIRED` (410), `DEVICE_LIMIT`/`PLAYLIST_LIMIT` (409), `ACCOUNT_EXPIRED` (402), `DEVICE_NOT_OWNED`/`PROFILE_NOT_OWNED`/`PROFILE_HAS_NO_ACCESS` (403), `PROFILE_REQUIRED`/`PAYLOAD_REQUIRED` (400).
- **Entrées** : `requireString`/`optionalString` avec une longueur maximale. Playlists : `validatePlaylistInput` + `convertGetPhp` — garde-les alignées avec la validation du portail (voir la racine).
- **Imports** : `npm:@supabase/supabase-js@2` et chemins relatifs `../_shared/*.ts`. Pas de `deno.json`.
- **Nouvelle fonction côté appareil** : déclare-la dans [config.toml](config.toml) (`verify_jwt = false`) **et** dans `$noJwt` de [../scripts/deploy-functions.ps1](../scripts/deploy-functions.ps1). Sinon le gateway renvoie 401 à l'app.
- **Env local** : [.env.example](functions/.env.example) est obsolète (ne cite que `PORTAL_TOKEN_SECRET`, plus utilisé). Les secrets réels sont `TMDB_API_KEY` et `PORTAL_URL`. Mets à jour ce fichier avec tout changement de secret.

## Migrations

- Nommage `YYYYMMDDHHMMSS_snake_case.sql`. **⚠ La dernière migration ([20260924000000_dns_servers.sql](migrations/20260924000000_dns_servers.sql)) est datée dans le futur** : `npx supabase migration new` génère l'heure UTC courante, qui peut lui être **inférieure**. Nomme toujours le fichier à la main, avec un horodatage strictement supérieur au plus grand fichier existant.
- **Ne modifie jamais une migration déjà appliquée** : crée-en une nouvelle.
- RLS activé sur toute nouvelle table. Nommage des policies : `"<table>: <rôle> <action>"`. Propriétaire : `auth.uid() = account_id`. Admin : `public.is_admin()` en `using` + `with check`. Tables filles : `exists (...)` sur `viewer_profiles`.
- **Toute fonction `SECURITY DEFINER` nouvelle** : `set search_path = public`, puis `revoke execute on function ... from public, anon[, authenticated];`, puis un `grant` explicite. Modèle : [20260921000100_harden_functions.sql](migrations/20260921000100_harden_functions.sql).
  - **Exceptions existantes à corriger** (voir [docs/roadmap.md](../docs/roadmap.md)) : `confirm_pairing`, `set_device_context`, `ensure_account`, `expire_pairing_sessions` n'ont qu'un GRANT à `service_role`, sans REVOKE.
- Vues `security_invoker` : recrée-les avec leur GRANT après tout ALTER de la table source.
- `updated_at` : trigger `<table>_touch_updated_at`. Exceptions sans trigger, gérées à la main par le portail : `featured_items`, `dns_servers`, `app_config`.
- Vérification en lecture seule des privilèges d'une fonction : `select has_function_privilege('anon', 'public.confirm_pairing(uuid,text,text,jsonb)', 'execute');`.

## Checklist d'une nouvelle migration ou fonction

- Horodatage strictement supérieur au dernier fichier de `migrations/`.
- RLS + policies propriétaire et/ou admin.
- `SECURITY DEFINER` : `search_path` + `REVOKE` + `GRANT` explicite.
- Trigger `touch_updated_at` si la table a une colonne `updated_at`.
- Vues recréées si la table source change.
- Vérifiée en local (`supabase db reset`), **jamais directement sur le cloud**.
- Si c'est un changement de contrat : voir la checklist de la racine (`docs/api.md` inclus).
