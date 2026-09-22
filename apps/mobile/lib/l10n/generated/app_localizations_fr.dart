// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'MultIPTV';

  @override
  String get loading => 'Chargement…';

  @override
  String get retry => 'Réessayer';

  @override
  String get cancel => 'Annuler';

  @override
  String get ok => 'OK';

  @override
  String get save => 'Enregistrer';

  @override
  String get delete => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get confirm => 'Confirmer';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get close => 'Fermer';

  @override
  String get search => 'Rechercher';

  @override
  String get searchHint => 'Rechercher chaînes, films, séries…';

  @override
  String get noResults => 'Aucun résultat.';

  @override
  String get home => 'Accueil';

  @override
  String get liveTv => 'TV en direct';

  @override
  String get movies => 'Films';

  @override
  String get series => 'Séries';

  @override
  String get favorites => 'Favoris';

  @override
  String get recentlyViewed => 'Vus récemment';

  @override
  String get settings => 'Réglages';

  @override
  String get catchUp => 'Replay';

  @override
  String get all => 'Tout';

  @override
  String get categories => 'Catégories';

  @override
  String get noChannels => 'Aucune chaîne.';

  @override
  String get noMovies => 'Aucun film.';

  @override
  String get noSeries => 'Aucune série.';

  @override
  String get noEpisodes => 'Aucun épisode.';

  @override
  String get noEpgAvailable => 'Aucun guide disponible.';

  @override
  String get noFavorites => 'Aucun favori pour le moment.';

  @override
  String get noRecent => 'Rien de visionné pour le moment.';

  @override
  String get nowPlaying => 'En cours';

  @override
  String get next => 'À suivre';

  @override
  String season(int number) {
    return 'Saison $number';
  }

  @override
  String episode(int number) {
    return 'Épisode $number';
  }

  @override
  String get play => 'Lire';

  @override
  String get resume => 'Reprendre';

  @override
  String resumeFrom(String time) {
    return 'Reprendre à $time';
  }

  @override
  String get startOver => 'Depuis le début';

  @override
  String get addToFavorites => 'Ajouter aux favoris';

  @override
  String get removeFromFavorites => 'Retirer des favoris';

  @override
  String get watchTrailer => 'Bande-annonce';

  @override
  String get cast => 'Distribution';

  @override
  String get director => 'Réalisateur';

  @override
  String get genre => 'Genre';

  @override
  String get releaseDate => 'Date de sortie';

  @override
  String get duration => 'Durée';

  @override
  String get rating => 'Note';

  @override
  String get deviceInfo => 'Informations appareil';

  @override
  String get macAddress => 'Adresse MAC';

  @override
  String get deviceKey => 'Clé appareil';

  @override
  String get deviceType => 'Type d\'appareil';

  @override
  String get appVersion => 'Version de l\'app';

  @override
  String get portalUrl => 'Portail';

  @override
  String get scanQr =>
      'Scannez le QR code pour ajouter une playlist depuis le portail web.';

  @override
  String get scanQrManage =>
      'Scannez ce QR code pour ajouter, modifier ou supprimer vos playlists depuis le portail web.';

  @override
  String get managePlaylistsOnline => 'Gérer mes playlists sur le web';

  @override
  String get openPortal => 'Ouvrir le portail';

  @override
  String trialDaysLeft(int days) {
    return 'Essai gratuit : $days jour(s) restant(s)';
  }

  @override
  String get trialEnded =>
      'Votre essai gratuit est terminé. Activez cet appareil sur le portail.';

  @override
  String get deviceActivated => 'Appareil activé';

  @override
  String deviceExpired(String date) {
    return 'Activation expirée le $date';
  }

  @override
  String deviceActiveUntil(String date) {
    return 'Actif jusqu\'au $date';
  }

  @override
  String get deviceActiveUnlimited => 'Actif, sans expiration';

  @override
  String get activationRequired => 'Activation requise';

  @override
  String get checkInternet => 'Vérifiez votre connexion internet.';

  @override
  String get portalUnreachable =>
      'Portail injoignable. Les playlists locales restent disponibles.';

  @override
  String get deviceKeyConflict =>
      'Cette adresse MAC est déjà enregistrée avec une autre clé appareil. Demandez à l\'administrateur de supprimer l\'appareil sur le portail, puis relancez l\'application.';

  @override
  String get pairTitle => 'Connectez cet appareil à votre compte';

  @override
  String pairStep1(String url) {
    return 'Sur votre téléphone ou ordinateur, ouvrez $url';
  }

  @override
  String get pairStep2 => 'Connectez-vous (ou créez un compte gratuit).';

  @override
  String get pairStep3 =>
      'Saisissez le code ci-dessous, ou scannez le QR code.';

  @override
  String get pairCode => 'Code';

  @override
  String pairExpiresIn(String time) {
    return 'Le code expire dans $time';
  }

  @override
  String get pairExpired => 'Ce code a expiré.';

  @override
  String get pairNewCode => 'Nouveau code';

  @override
  String get pairWaiting => 'En attente de confirmation…';

  @override
  String get pairConfirmed => 'Appareil connecté ! Chargement de votre compte…';

  @override
  String pairFailed(String error) {
    return 'Impossible de démarrer l\'appairage : $error';
  }

  @override
  String get pairLater => 'Continuer sans compte';

  @override
  String get addPlaylistTitle => 'Ajouter une liste de lecture';

  @override
  String get addPlaylistWebStep1 =>
      'Sur votre téléphone ou ordinateur, scannez le QR code ou ouvrez';

  @override
  String get addPlaylistWebStep2 =>
      'Connectez-vous à votre compte, puis ajoutez votre source M3U ou Xtream Codes.';

  @override
  String get addPlaylistWebStep3 =>
      'Revenez ici : la liste apparaît automatiquement, ou appuyez sur le bouton ci-dessous.';

  @override
  String get addPlaylistDone => 'J\'ai ajouté ma liste';

  @override
  String get addPlaylistChecking => 'Vérification…';

  @override
  String addPlaylistAutoRefresh(int seconds) {
    return 'Cet écran se met à jour tout seul toutes les $seconds secondes.';
  }

  @override
  String get addPlaylistNotYet =>
      'Aucune liste trouvée pour l\'instant. Vérifiez qu\'elle est bien enregistrée sur le portail et accessible à ce profil.';

  @override
  String addPlaylistPairIntro(String url) {
    return 'Les listes de lecture se gèrent depuis le web. Scannez le QR code ou saisissez ce code sur $url pour ajouter une source M3U ou Xtream Codes à votre compte.';
  }

  @override
  String get addPlaylistConfirmed => 'Liste ajoutée ! Synchronisation…';

  @override
  String get whoIsWatching => 'Qui regarde ?';

  @override
  String get switchProfile => 'Changer de profil';

  @override
  String get kidsProfile => 'Enfant';

  @override
  String get manageProfilesHint =>
      'Les profils se créent et se modifient depuis le portail web.';

  @override
  String get noProfileAccess =>
      'Ce profil n\'a accès à aucune liste de lecture. Modifiez ses accès sur le portail web.';

  @override
  String get account => 'Compte';

  @override
  String get accountPlan => 'Formule';

  @override
  String accountDevices(int count) {
    return '$count appareil(s) maximum';
  }

  @override
  String get accountExpired => 'Compte expiré';

  @override
  String accountManageOnline(String url) {
    return 'Gérez vos appareils, profils et listes de lecture sur $url';
  }

  @override
  String get deviceName => 'Nom de l\'appareil';

  @override
  String get unpairDevice => 'Déconnecter cet appareil';

  @override
  String get unpairDeviceConfirm =>
      'L\'appareil sera détaché de votre compte : il faudra le reconnecter avec un nouveau code. Vos listes et votre historique restent sur votre compte.';

  @override
  String get unpaired => 'Appareil non connecté';

  @override
  String get unpairedDescription =>
      'Cet appareil n\'est plus relié à un compte. Reconnectez-le pour retrouver vos listes de lecture.';

  @override
  String get pairDevice => 'Connecter l\'appareil';

  @override
  String get noPlaylistTitle => 'Aucune liste de lecture';

  @override
  String get noPlaylistDescription =>
      'Votre compte ne contient encore aucune liste de lecture accessible à ce profil.';

  @override
  String get addPlaylist => 'Ajouter une playlist';

  @override
  String get addM3u => 'Ajouter une URL M3U';

  @override
  String get addM3uFile => 'Ajouter un fichier M3U';

  @override
  String get addXtream => 'Ajouter un compte Xtream Codes';

  @override
  String get refreshPlaylists => 'Rafraîchir';

  @override
  String get changePlaylist => 'Changer de playlist';

  @override
  String get myPlaylists => 'Mes playlists';

  @override
  String get playlistName => 'Nom de la playlist';

  @override
  String get playlistUrl => 'URL M3U';

  @override
  String get epgUrl => 'URL EPG (XMLTV, optionnel)';

  @override
  String get serverUrl => 'URL du serveur';

  @override
  String get serverUrlHint => 'http://exemple.com:8080';

  @override
  String get username => 'Identifiant';

  @override
  String get password => 'Mot de passe';

  @override
  String get protectWithPin => 'Protéger par un code PIN';

  @override
  String get pinCode => 'Code PIN';

  @override
  String get enterPin => 'Saisissez le code PIN';

  @override
  String get pinIncorrect => 'Code PIN incorrect.';

  @override
  String get playlistProtected => 'Cette playlist est protégée.';

  @override
  String get deletePlaylist => 'Supprimer la playlist';

  @override
  String get editPlaylist => 'Modifier la playlist';

  @override
  String get editOnPortal =>
      'Les playlists du portail se modifient sur le portail web.';

  @override
  String deletePlaylistConfirm(String name) {
    return 'Supprimer « $name » de cet appareil ?';
  }

  @override
  String get playlistFromPortal => 'Depuis le portail';

  @override
  String get playlistLocal => 'Ajoutée sur cet appareil';

  @override
  String playlistExpires(String date) {
    return 'Expire le : $date';
  }

  @override
  String get invalidM3u => 'Veuillez fournir une playlist M3U valide.';

  @override
  String get invalidUrl => 'URL invalide.';

  @override
  String get fieldRequired => 'Ce champ est obligatoire.';

  @override
  String get playlistLoading => 'Chargement de la playlist…';

  @override
  String importProgress(String done, String total) {
    return '$done / $total';
  }

  @override
  String get importingLive => 'Import des chaînes…';

  @override
  String get importingMovies => 'Import des films…';

  @override
  String get importingSeries => 'Import des séries…';

  @override
  String get importingEpg => 'Import du guide TV…';

  @override
  String get importDone => 'Playlist chargée.';

  @override
  String get importFailed =>
      'La playlist ne fonctionne pas. Vérifiez l\'URL ou les identifiants.';

  @override
  String get loginFailed =>
      'Connexion refusée. Vérifiez l\'identifiant et le mot de passe.';

  @override
  String accountExpires(String date) {
    return 'Compte valable jusqu\'au : $date';
  }

  @override
  String activeConnections(String active, String max) {
    return 'Connexions : $active / $max';
  }

  @override
  String get language => 'Langue';

  @override
  String get theme => 'Thème';

  @override
  String get themeDark => 'Sombre';

  @override
  String get themeAmoled => 'Noir AMOLED';

  @override
  String get languageSystem => 'Système';

  @override
  String get parentalControl => 'Contrôle parental';

  @override
  String get parentalPin => 'PIN parental';

  @override
  String get setParentalPin => 'Définir le PIN parental';

  @override
  String get changeParentalPin => 'Changer le PIN parental';

  @override
  String get confirmPin => 'Confirmer le PIN';

  @override
  String get pinMismatch => 'Les codes PIN ne correspondent pas.';

  @override
  String get pinChanged => 'PIN modifié.';

  @override
  String get hideCategories => 'Masquer des catégories';

  @override
  String get hideLiveCategories => 'Catégories TV masquées';

  @override
  String get hideMovieCategories => 'Catégories films masquées';

  @override
  String get hideSeriesCategories => 'Catégories séries masquées';

  @override
  String get lockedChannels => 'Chaînes verrouillées';

  @override
  String get lockChannel => 'Verrouiller la chaîne';

  @override
  String get unlockChannel => 'Déverrouiller la chaîne';

  @override
  String get channelLocked => 'Cette chaîne est verrouillée.';

  @override
  String get liveStreamFormat => 'Format des flux live';

  @override
  String get formatTs => 'MPEG-TS (par défaut)';

  @override
  String get formatHls => 'HLS (m3u8)';

  @override
  String get autoUpdatePlaylist => 'Mise à jour auto de la playlist';

  @override
  String get autoUpdateNever => 'Manuellement';

  @override
  String get autoUpdateDaily => 'Chaque jour';

  @override
  String get autoUpdateAlways => 'À chaque lancement';

  @override
  String get layout => 'Disposition';

  @override
  String get layoutGrid => 'Grille';

  @override
  String get layoutList => 'Liste';

  @override
  String get sortOrder => 'Ordre de tri';

  @override
  String get sortDefault => 'Par défaut';

  @override
  String get sortAz => 'A → Z';

  @override
  String get sortZa => 'Z → A';

  @override
  String get sortAdded => 'Ajouts récents';

  @override
  String get sortRating => 'Note';

  @override
  String get subtitles => 'Sous-titres';

  @override
  String get subtitleSize => 'Taille des sous-titres';

  @override
  String get subtitleColor => 'Couleur des sous-titres';

  @override
  String get subtitleBackground => 'Fond des sous-titres';

  @override
  String get audioTrack => 'Piste audio';

  @override
  String get subtitleTrack => 'Piste de sous-titres';

  @override
  String get off => 'Désactivé';

  @override
  String get videoFit => 'Ajustement vidéo';

  @override
  String get fitContain => 'Ajuster';

  @override
  String get fitCover => 'Remplir';

  @override
  String get fitStretch => 'Étirer';

  @override
  String get videoDecoder => 'Décodage vidéo';

  @override
  String get decoderAuto => 'Automatique (direct sur TV)';

  @override
  String get decoderDirect => 'Matériel direct — le plus fluide';

  @override
  String get decoderCompat => 'Compatibilité — plus lent';

  @override
  String get performanceMode => 'Mode performance';

  @override
  String get performanceAuto => 'Automatique (actif sur les box TV)';

  @override
  String get performanceOn => 'Activé — visuels allégés, plus fluide';

  @override
  String get performanceOff => 'Désactivé — visuels complets';

  @override
  String get clearCache => 'Vider le cache';

  @override
  String get clearHistory => 'Effacer l\'historique';

  @override
  String get cleared => 'Terminé.';

  @override
  String get timeFormat => 'Format de l\'heure';

  @override
  String get timeFormat24 => '24 h';

  @override
  String get timeFormat12 => '12 h';

  @override
  String get about => 'À propos';

  @override
  String get disclaimer =>
      'MultIPTV est un lecteur multimédia générique et n\'inclut aucun contenu ni playlist.';

  @override
  String get externalPlayer => 'Ouvrir dans un lecteur externe';

  @override
  String get externalPlayerMissing =>
      'Aucun lecteur externe trouvé (VLC ou MX Player).';

  @override
  String get myGroups => 'Mes groupes';

  @override
  String get addGroup => 'Ajouter un groupe';

  @override
  String get groupName => 'Nom du groupe';

  @override
  String get addChannels => 'Ajouter des chaînes';

  @override
  String get removeGroup => 'Supprimer le groupe';

  @override
  String get playbackError => 'Erreur de lecture';

  @override
  String get playbackErrorDescription =>
      'Le flux n\'a pas pu être lu. Réessayez ou choisissez un autre flux.';

  @override
  String get channelList => 'Chaînes';

  @override
  String get programGuide => 'Guide des programmes';

  @override
  String get playbackSpeed => 'Vitesse';

  @override
  String get nextEpisode => 'Épisode suivant';

  @override
  String get previousChannel => 'Chaîne précédente';

  @override
  String get nextChannel => 'Chaîne suivante';

  @override
  String get exit => 'Quitter';

  @override
  String get exitDescription => 'Voulez-vous quitter l\'application ?';

  @override
  String get seeAll => 'Tout voir';

  @override
  String get continueWatching => 'Reprendre la lecture';

  @override
  String get recentChannels => 'Chaînes récentes';

  @override
  String get updateRequired => 'Mise à jour requise';

  @override
  String get updateNow => 'Mettre à jour';

  @override
  String get updateDescription =>
      'Une nouvelle version est nécessaire pour continuer. Veuillez mettre à jour l\'application.';

  @override
  String get maintenance =>
      'Le service est en maintenance. Réessayez plus tard.';

  @override
  String get featured => 'À la une';

  @override
  String get recentlyAddedMovies => 'Nouveaux films';

  @override
  String get recentlyAddedSeries => 'Nouvelles séries';

  @override
  String get moreInfo => 'Infos';

  @override
  String get nowLabel => 'Maintenant';

  @override
  String get nextLabel => 'Ensuite';

  @override
  String remaining(String time) {
    return '$time restantes';
  }

  @override
  String episodeNumber(int n) {
    return 'Épisode $n';
  }

  @override
  String get appearance => 'Apparence';

  @override
  String get playback => 'Lecture';

  @override
  String get episodesTitle => 'Épisodes';

  @override
  String get featuredSource => 'Contenu à la une';

  @override
  String get featuredCurated => 'Sélection de l\'équipe';

  @override
  String get featuredPopular => 'Les plus regardés en ce moment';

  @override
  String get featuredTmdb => 'Tendances TMDB';

  @override
  String get watchNow => 'Regarder';

  @override
  String get openLink => 'Ouvrir';

  @override
  String get eventNow => 'Maintenant';

  @override
  String todayAt(String time) {
    return 'Aujourd\'hui à $time';
  }

  @override
  String tomorrowAt(String time) {
    return 'Demain à $time';
  }

  @override
  String seasonsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saisons',
      one: '1 saison',
    );
    return '$_temp0';
  }
}
