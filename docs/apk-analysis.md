# Analyse de `shamel.apk`

Application d'origine : **Shamel TV** (`app.shamel.tv`). Application Android **native Kotlin** (non portable vers iOS), template de type « IBO Player Pro ».

## Stack technique

| Domaine | Bibliothèque |
|---|---|
| Réseau | Retrofit 2, OkHttp 3, Gson, Cronet (Play Services) |
| Lecteur | androidx.media3 ExoPlayer (HLS, TS, DASH, sous-titres TTML/SSA) |
| Données | Realm (`librealm-jni.so`), Room + WorkManager |
| Images | Glide (+ GIF `libpl_droidsonroids_gif.so`) |
| TV | androidx.leanback (`LiveVerticalGridView`, `LiveHorizontalGridView`) |
| Divers | Google Cast (`CastOptionsProvider`), Play Core (mise à jour / avis in-app), Google Sign-In, Material, Firebase encoders |

## Portail web

- URL : `https://shamel.tv/manage-playlists/login/`
- Connexion par **adresse MAC** + **device key** ; QR code affiché par l'app (« Scan QR to add playlist. »).
- Modèle d'essai gratuit puis activation par MAC : `mac_registered`, `mac_activated`, `is_trial`, `trial_ended`, `tv_mac_expired`, `expire_date`, `plan_id`, `pay_with_google_pay`.
- Playlists : `playlist_id`, `playlist_name`, `playlist_url`, `playlist_type`, `is_protected`, `pin_code`, `playlist_expire_date`, `playlist_position`.
- `AppInfoModel` : `app_version`, `app_status`, `apk_link`, `UrlModel`, `AndroidTestingModel` (mise à jour forcée, URLs pilotées par le serveur).
- `WordModels` / `LanguageModel` : traductions de l'interface téléchargées depuis le serveur.
- Messages : « There is no playlist uploaded for your Device. », « Playlists can be added or managed via the app or the website. », « Your device is activated successfully. », « Shamel TV doesn't sell playlist or subscriptions. », « Shamel TV is General Media Player and it doesn't include any content or playlists. »

## API Xtream Codes utilisée

`player_api.php?action=` : `get_live_categories`, `get_live_streams`, `get_vod_categories`, `get_vod_streams`, `get_vod_info`, `get_series_categories`, `get_series`, `get_series_info`, `get_short_epg`, `get_simple_data_table` (catch-up).
`xmltv.php` (EPG), `get.php?username=…&password=…&type=m3u_plus&output=ts`.
Chemins de flux : `/live/`, `/movie/`, `/series/`, `/timeshift/`.
`LoginResponse{user_info{exp_date, active_cons, max_connections, is_trial}, server_info}`.

## Écrans (activities)

Main/Splash, Home, Live, LiveChannel, Category, AddGroup (« My Groups »), Movie, MovieInfo, MovieCredit, MoviePlayer, MovieSecond, Series, SeriesInfo, Season, SeriesPlayer, SeriesSecond, CatchUp, CatchUpPlayer, Search, Setting, ChangePlaylist ; variantes mobiles : LiveMobile, LiveChannelMobile, MovieMobilePlayer, SeriesMobilePlayer.

## Fonctionnalités

Favoris (chaînes / films / séries), récents + reprise (`last_position`), contrôle parental (PIN, verrouillage de chaînes, masquage de catégories live/vod/séries, mot de passe parent), thèmes, langues, disposition grille/liste, tri (A-Z, Z-A, ajout, numéro, note), format live TS / m3u8, mise à jour auto de la playlist (chaque jour / à chaque lancement), sous-titres (taille, couleur, fond), piste audio, ajustement fit/fill, lecteur externe (MX Player, VLC), catch-up / TV archive, EPG (court + XMLTV), fiches TMDB (casting, bande-annonce YouTube), sous-titres en ligne (type OpenSubtitles), vider cache / historique, supprimer / rafraîchir la playlist, recharger le portail, format d'heure, résolution par défaut, Chromecast.
