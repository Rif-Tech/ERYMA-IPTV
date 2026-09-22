# MultIPTV

Monorepo d'un lecteur IPTV multi-plateforme (Android, iOS, Android TV) et de son portail web de gestion de playlists.

```
apps/mobile     Application Flutter (mobile, tablette, TV)
apps/portal     Portail web Next.js (utilisateur + admin)
supabase        Base Postgres, RLS, Edge Functions (API appareil/portail)
docs            Analyse de l'application d'origine, API
```

## Fonctionnement

1. L'utilisateur crée un **compte** sur le portail (e-mail + mot de passe, Supabase Auth). Le compte porte l'abonnement (essai puis formule activée par l'administrateur), les **profils** (« Qui regarde ? »), les **listes de lecture** (M3U / Xtream Codes) et les **appareils**.
2. Au premier lancement, l'app génère une identité d'installation (`device_uuid` + secret aléatoire, stockés en secure storage) et affiche un **QR code + code court** (10 min, usage unique). L'utilisateur le scanne / le saisit sur `/activate` : l'appareil est rattaché au compte si la limite d'appareils du plan le permet.
3. L'app charge ensuite la session du compte (`device-session`) : profils, listes accessibles au profil, statut d'abonnement. Une seule liste / un seul profil → sélection automatique ; sinon sélecteur. Les listes s'ajoutent **uniquement depuis le web** (`/account/playlists` ou `/add-playlist` via un code affiché par l'appareil).
4. Historique, favoris, verrous parentaux et groupes sont **par profil et par liste**. La reprise de lecture est synchronisée avec le serveur (`watch_progress`) par (profil, liste, élément) : jamais rapprochée entre deux listes.
5. Depuis `/account`, l'utilisateur renomme, déconnecte ou supprime ses appareils ; un appareil révoqué revient à l'écran d'appairage et perd les listes du compte. L'administrateur (`/admin`, `/admin/accounts`) gère les formules, statuts et expirations.
6. Le carrousel « À la une » de l'accueil est piloté par l'administrateur (`/admin/featured`, films/séries par ID TMDB ou bannières libres) ; l'utilisateur peut aussi choisir « les plus regardés » ou les tendances TMDB. Un film/série n'apparaît que s'il existe dans ses playlists.

Les anciennes installations (identité MAC + clé) continuent de fonctionner : lors de l'appairage, leurs playlists et leur activation sont reprises par le compte. Le portail legacy `/manage-playlists` reste disponible pendant la transition.

L'application ne fournit aucun contenu : elle lit uniquement les sources fournies par l'utilisateur.

## Démarrage rapide

Le backend est déployé sur Supabase cloud (`https://zeproepijcixdmszlkmf.supabase.co`) : schéma via [supabase/migrations](supabase/migrations), fonctions via [supabase/functions](supabase/functions). Test rapide : `.\scripts\smoke-test.ps1`.

Secrets Edge Functions à définir (Dashboard → Edge Functions → Secrets ou `npx supabase secrets set`) : `TMDB_API_KEY` (recherche/visuels TMDB), `PORTAL_URL` (URL publique du portail, embarquée dans les QR codes d'appairage) et, en production, `PORTAL_TOKEN_SECRET`.

### Déploiement du modèle comptes

1. **Base** : `npx supabase db push` (ou MCP `apply_migration`) applique [supabase/migrations/20260922000000_accounts.sql](supabase/migrations/20260922000000_accounts.sql) — additif et non destructif : nouvelles tables `plans`, `accounts`, `subscriptions`, `viewer_profiles`, `profile_playlists`, `pairing_sessions`, `watch_progress` ; colonnes ajoutées sur `devices`/`playlists` (MAC/clé deviennent optionnels) ; vues `devices_with_status` (statut legacy dans `status_legacy`) et `accounts_overview` ; fonctions `confirm_pairing`, `set_device_context`, `account_status`, `ensure_account` ; RLS propriétaire (`auth.uid() = account_id`) + admin. Les utilisateurs existants reçoivent automatiquement un compte, un profil par défaut et un abonnement d'essai.
2. **Auth** : Dashboard → Authentication : activer l'inscription e-mail (avec confirmation), ajouter `https://<portail>/auth/callback` aux Redirect URLs (voir `supabase/config.toml` pour le local).
3. **Fonctions** : `.\scripts\deploy-functions.ps1` (après `npx supabase login` + `link`) déploie toutes les fonctions avec `--no-verify-jwt` pour celles côté appareil.
4. **URL publique du portail** : `/admin/config` → « URL publique du portail » (ex. `http://100.88.208.52:3000` sur le LAN, `https://…` en prod). C'est cette adresse que les appareils affichent et encodent dans le QR code d'appairage (jamais `localhost`). À défaut, le secret `PORTAL_URL` des fonctions est utilisé, puis le `--dart-define=PORTAL_URL` de l'APK.
5. **Portail** : `apps/portal/.env.local` → `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `SUPABASE_FUNCTIONS_URL` (les liens des e-mails reprennent l'hôte de la requête / `x-forwarded-host`). Pour les tests depuis un téléphone/TV, lancez le panel **en production** : `npm run panel` (build + `next start -H 0.0.0.0 -p 3000`) — en `next dev`, chaque modification de code invalide les Server Actions en cours et le navigateur affiche « Unexpected token '<' ». Les hôtes autorisés à poster les formulaires sont listés dans `next.config.ts` (`PORTAL_ALLOWED_ORIGINS=host1,host2` pour en ajouter).
6. **App** : `.\scripts\build-release.ps1 -PortalUrl <url>` (repli hors ligne ; le script refuse `localhost`). Les installations existantes migrent leur base locale (schema v4) et montrent l'écran d'appairage ; leurs données locales sont attribuées au premier profil choisi.
7. **Validation** : `flutter test` (apps/mobile), `npx tsc --noEmit -p . && npm run lint` (apps/portal), `.\scripts\smoke-test.ps1`, puis parcours complet : inscription → ajout d'une liste → appairage TV via code → sélection de profil → lecture → vérification de `watch_progress` → révocation depuis `/account` → la TV revient à l'appairage.

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

## Build release Android

```powershell
# Une fois : créer le keystore puis copier apps/mobile/android/key.properties.example → key.properties
.\scripts\build-release.ps1   # → dist\app-{armeabi-v7a,arm64-v8a,x86_64}-release.apk + app-universal-release.apk
```

R8/shrinkResources, obfuscation Dart et découpage par ABI sont activés. Les box 32 bits (Xiaomi Mi Box S…) n'acceptent que `armeabi-v7a` ; publiez l'APK universel comme `apk_link` dans la config admin si un seul lien est souhaité.

L'app détecte les appareils modestes (TV, 32 bits, low-RAM) et active un **mode performance** (réglable dans Réglages → Lecture) : visuels allégés, caches réduits, décodage vidéo direct.

Voir [docs/api.md](docs/api.md) pour les endpoints et [docs/apk-analysis.md](docs/apk-analysis.md) pour l'analyse de l'application d'origine.
