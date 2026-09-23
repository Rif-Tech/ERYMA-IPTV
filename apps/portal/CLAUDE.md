# apps/portal : portail Next.js 16 (utilisateur + admin)

Ce fichier ne contient que ce qui est propre au portail. Le transverse est dans [../../CLAUDE.md](../../CLAUDE.md).

## Avant toute ligne de code Next

**Next 16 diffère de ce que tu connais.** Lis `node_modules/next/dist/docs/` avant d'écrire une route, un layout ou une Server Action — en particulier les pages sur la version 16 et les Server Actions.

Points déjà en jeu dans ce dépôt :
- `proxy.ts` remplace `middleware.ts`.
- `cookies()`, `headers()`, `params` et `searchParams` sont **uniquement asynchrones** : `await`-les toujours.
- `next lint` a disparu ; `next build` ne lance plus le lint.
- Helpers de typage globaux générés `PageProps<'/route'>` / `LayoutProps<'/route'>`, sans interface maison. Sur un clone neuf, `npx next typegen` avant `tsc` (probable, à vérifier si `tsc` échoue étrangement).
- `next.config.ts` fixe `agentRules: false` : Next ne génère ni ne réécrit `AGENTS.md`/`CLAUDE.md` automatiquement. **Garde cette option à false** tant que ces fichiers sont rédigés à la main, sinon `next dev` insérerait un bloc géré dans ce fichier.

## Commandes (cwd `apps/portal`)

- `npm run dev` (localhost:3000) ; `npm run dev:lan` (0.0.0.0:3000, restreint à `allowedDevOrigins` : `100.88.208.52`, `localhost`, `127.0.0.1`).
- `npm run panel` : build + `next start -H 0.0.0.0 -p 3000`. **À utiliser pour tester depuis une TV ou un téléphone** : en `next dev`, chaque recompilation invalide les Server Actions en cours et le navigateur affiche « Unexpected token '<' ».
- Validation : `npx tsc --noEmit -p .; if ($?) { npm run lint }` (PowerShell 5.1, pas de `&&`).
- **`apps/portal/.env.local` pointe sur la PROD** (`zeproepijcixdmszlkmf`) : `npm run dev`/`panel` lisent et écrivent de vraies données. Pour des actions destructrices, demande d'abord, ou pointe vers une stack Supabase locale.

## Architecture

- [lib/supabase.ts](lib/supabase.ts) est le point d'entrée unique vers Supabase :
  - `createSupabaseServer()` (clé anon + cookies) ;
  - `currentUser()`, `requireUser()`, `requireAdmin()` (`profiles.role === 'admin'`) ;
  - `callAsUser()` vers les Edge Functions (Bearer + apikey, `cache: 'no-store'`), lève `FunctionError`.

  **Aucun client navigateur, aucune clé service_role.**
- [proxy.ts](proxy.ts) ne fait que rafraîchir les cookies de session : **ce n'est pas une garde**.
- **Pages protégées** : chaque Server Component refait sa propre garde — `requireUser()` puis `redirect('/login?next=…')`, ou `requireAdmin()` puis `redirect('/admin/login')`. Il n'existe pas de `app/admin/layout.tsx` : si tu en crées un, exclus `/admin/login` pour ne pas boucler la redirection.
- **Server Actions** : fichier `actions.ts` à côté de la route, marqué `"use server"`. Chaque action qui lit ou modifie des données commence par sa garde — en pratique un helper **local, non exporté**, redéfini par fichier (`owner()` dans `account/actions.ts`, `admin()` dans `admin/actions.ts`, `admin/accounts/actions.ts`, `admin/featured/actions.ts`, `admin/dns/actions.ts`) : ce ne sont pas des helpers partagés, ne suppose pas qu'ils existent ailleurs.
  - **Chaque export d'un fichier `"use server"` devient un endpoint POST public.** N'y exporte que des actions voulues comme telles. Contre-exemple à corriger, pas à reproduire : [app/pairing/actions.ts](app/pairing/actions.ts) exporte `describeError`/`normalizeCode`, deux helpers, sans aucune garde.
  - Formulaires : `(_prev: ActionState, form: FormData) => Promise<ActionState>` ([lib/types.ts](lib/types.ts) : `{ error?: string; ok?: boolean }`), consommés par `useActionState`.
  - Mutation → `revalidatePath(route exacte)` **avant** `redirect()`.

## Conventions

- Découpage : la page serveur charge les données ; l'interactivité va dans un `"use client"` voisin (`*-form(s).tsx`, `*-list.tsx`, `*-tabs.tsx`).
- Validation manuelle (pas de zod) : `String(form.get('x') ?? '').trim()`, chaîne vide → null, regex pour URL http(s)/PIN/UUID.
- Styles : Tailwind 4 CSS-first (`@import 'tailwindcss'`, pas de `tailwind.config`). Classes de [globals.css](app/globals.css) : `btn-primary/secondary/danger`, `card`/`card-strong`, `badge`, `notice-success/error`, `segmented`, `skeleton`. **N'ajoute pas de nouvelles classes `slate-*`** : elles sont remappées de force.
- Thème sombre uniquement, accent `#0a84ff`.
- Langues et dates : libellés en **français codés en dur**, `Intl.DateTimeFormat('fr-FR', { timeZone: 'Europe/Paris' })`.
- Filtres PostgREST (`.or()`, `.ilike()`) : restreins toute saisie utilisateur au jeu de caractères sûr avant de l'injecter.
- Paramètre `next` (redirection après connexion) : chemin relatif uniquement — refuse `//` **et** `/\` (un navigateur normalise `/\` en `//`), pas seulement `startsWith('/')`.
- `allowedOrigins` de `next.config.ts` : `*` couvre un label DNS entier, jamais un port. `*.ts.net` ne matche pas `machine.tailnet.ts.net:3000` ; il faudrait `**.ts.net:3000` (utile seulement derrière un reverse-proxy qui réécrit `x-forwarded-host`).

## Invariants

- Révocation d'un appareil : `status='revoked'`, `revoked_at`, `secret_hash=null`, **et** `active_profile_id`/`active_playlist_id` remis à null.
- Un compte garde toujours au moins un profil.
- Clés d'avatar partagées avec l'app : blue, red, green, orange, purple, pink, teal, yellow (non validées côté serveur : l'app retombe sur blue).
- `app_config.trial_days` reste un nombre JSON ; `portal_url` doit rester http(s), idéalement pas localhost (non imposé aujourd'hui, voir la racine).
- Un seul serveur DNS `is_default` à la fois : remets les autres à false avant de fixer le nouveau.
- Recherche TMDB admin : Edge Function `tmdb` avec le JWT admin en `x-admin-token`. La clé TMDB ne transite jamais par le portail. Réutilise `functionsUrl()` de `lib/supabase.ts` plutôt qu'une copie locale (celle de `admin/featured/actions.ts` n'a pas son repli local).
- Limites de plan (profils, playlists) et abonnement expiré : **contrôlés uniquement ici**, en deux temps non atomiques (compter puis insérer) — une policy RLS « owner all » permet de les contourner par PostgREST direct. Le serveur, lui, ne bloque l'expiration qu'à l'appairage d'un appareil et dans `device-session`.
- Validation d'une playlist : garde-la alignée avec `validatePlaylistInput` côté Edge Function (voir la racine, « contrats partagés ») ; elles divergent aujourd'hui.

## Checklist d'une modification du portail

- Garde en tête de page **et** en tête de chaque Server Action touchée.
- `ActionState` en retour, `revalidatePath` avant `redirect`.
- Validation alignée avec `validatePlaylistInput` pour tout ce qui touche aux playlists.
- Libellés en français, dates en `fr-FR`/`Europe/Paris`.
- `npx tsc --noEmit -p .; if ($?) { npm run lint }`.
- Testé via `npm run panel` si l'écran doit s'ouvrir depuis une TV ou un téléphone.
