# MultIPTV

Monorepo d'un lecteur IPTV multi-plateforme (Android, iOS, Android TV) et de son portail web de gestion de playlists.

```
apps/mobile     Application Flutter (mobile, tablette, TV)
apps/portal     Portail web Next.js (utilisateur + admin)
supabase        Base Postgres, RLS, Edge Functions (API appareil/portail)
docs            Analyse de l'application d'origine, API
```

## Fonctionnement

1. Au premier lancement, l'app génère une identité d'appareil (pseudo-adresse MAC + clé) et s'enregistre auprès de l'API.
2. L'utilisateur ajoute ses playlists (M3U ou Xtream Codes) soit dans l'app, soit sur le portail web en se connectant avec la MAC + la clé (ou via le QR code affiché par l'app).
3. L'app synchronise les playlists du portail, importe chaînes / films / séries / EPG en base locale et lit les flux avec `media_kit`.
4. Un essai gratuit est ouvert à l'enregistrement ; l'administrateur active ensuite l'appareil depuis `/admin`.
5. Le carrousel « À la une » de l'accueil est piloté par l'administrateur (`/admin/featured`, films/séries par ID TMDB ou bannières libres) ; l'utilisateur peut aussi choisir « les plus regardés » ou les tendances TMDB. Un film/série n'apparaît que s'il existe dans ses playlists.

L'application ne fournit aucun contenu : elle lit uniquement les sources fournies par l'utilisateur.

## Démarrage rapide

Le backend est déployé sur Supabase cloud (`https://zeproepijcixdmszlkmf.supabase.co`) : schéma via [supabase/migrations](supabase/migrations), fonctions via [supabase/functions](supabase/functions). Test rapide : `.\scripts\smoke-test.ps1`.

Secrets Edge Functions à définir (Dashboard → Edge Functions → Secrets ou `npx supabase secrets set`) : `TMDB_API_KEY` (recherche/visuels TMDB) et, en production, `PORTAL_TOKEN_SECRET`.

```powershell
# App Flutter (pointe par défaut sur le cloud ; surchargez avec --dart-define=API_BASE_URL/API_ANON_KEY/PORTAL_URL)
cd apps/mobile
flutter pub get
dart run build_runner build -d
flutter run

# Portail (apps/portal/.env.local contient l'URL et la clé publique du projet)
cd apps/portal
npm install
npm run dev

# Backend local (optionnel, nécessite Docker)
supabase start
supabase db reset
supabase functions serve
```

Redéployer une fonction après modification : `npx supabase functions deploy <nom>` (après `npx supabase login` et `npx supabase link --project-ref zeproepijcixdmszlkmf`), ou via le MCP Supabase.

Voir [docs/api.md](docs/api.md) pour les endpoints et [docs/apk-analysis.md](docs/apk-analysis.md) pour l'analyse de l'application d'origine.
