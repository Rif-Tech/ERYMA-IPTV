// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'MultIPTV';

  @override
  String get loading => 'Loading…';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get confirm => 'Confirm';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get close => 'Close';

  @override
  String get search => 'Search';

  @override
  String get searchHint => 'Search channels, movies, series…';

  @override
  String get noResults => 'No results.';

  @override
  String get home => 'Home';

  @override
  String get liveTv => 'Live TV';

  @override
  String get movies => 'Movies';

  @override
  String get series => 'Series';

  @override
  String get favorites => 'Favorites';

  @override
  String get recentlyViewed => 'Recently viewed';

  @override
  String get settings => 'Settings';

  @override
  String get catchUp => 'Catch-up';

  @override
  String get all => 'All';

  @override
  String get categories => 'Categories';

  @override
  String get noChannels => 'No channels.';

  @override
  String get noMovies => 'No movies.';

  @override
  String get noSeries => 'No series.';

  @override
  String get noEpisodes => 'No episodes.';

  @override
  String get noEpgAvailable => 'No EPG available.';

  @override
  String get noFavorites => 'Nothing in favorites yet.';

  @override
  String get noRecent => 'Nothing watched yet.';

  @override
  String get nowPlaying => 'Now';

  @override
  String get next => 'Next';

  @override
  String season(int number) {
    return 'Season $number';
  }

  @override
  String episode(int number) {
    return 'Episode $number';
  }

  @override
  String get play => 'Play';

  @override
  String get resume => 'Resume';

  @override
  String resumeFrom(String time) {
    return 'Resume from $time';
  }

  @override
  String get startOver => 'Start over';

  @override
  String get addToFavorites => 'Add to favorites';

  @override
  String get removeFromFavorites => 'Remove from favorites';

  @override
  String get watchTrailer => 'Watch trailer';

  @override
  String get cast => 'Cast';

  @override
  String get director => 'Director';

  @override
  String get genre => 'Genre';

  @override
  String get releaseDate => 'Release date';

  @override
  String get duration => 'Duration';

  @override
  String get rating => 'Rating';

  @override
  String get deviceInfo => 'Device information';

  @override
  String get deviceType => 'Device type';

  @override
  String get appVersion => 'App version';

  @override
  String get portalUrl => 'Portal';

  @override
  String get managePlaylistsOnline => 'Manage my account on the web';

  @override
  String trialDaysLeft(int days) {
    return 'Free trial: $days day(s) left';
  }

  @override
  String get trialEnded =>
      'Your free trial has ended. Please activate this device on the portal.';

  @override
  String get deviceActivated => 'Device activated';

  @override
  String deviceExpired(String date) {
    return 'Activation expired on $date';
  }

  @override
  String deviceActiveUntil(String date) {
    return 'Active until $date';
  }

  @override
  String get deviceActiveUnlimited => 'Active, no expiration';

  @override
  String get activationRequired => 'Activation required';

  @override
  String get checkInternet => 'Please check your internet connection.';

  @override
  String get portalUnreachable =>
      'Portal unreachable. Local playlists are still available.';

  @override
  String get pairTitle => 'Link this device to your account';

  @override
  String pairStep1(String url) {
    return 'On your phone or computer, open $url';
  }

  @override
  String get pairStep2 => 'Sign in (or create a free account).';

  @override
  String get pairStep3 => 'Enter the code below, or scan the QR code.';

  @override
  String get pairCode => 'Code';

  @override
  String pairExpiresIn(String time) {
    return 'Code expires in $time';
  }

  @override
  String get pairExpired => 'This code has expired.';

  @override
  String get pairNewCode => 'New code';

  @override
  String get pairWaiting => 'Waiting for confirmation…';

  @override
  String get pairConfirmed => 'Device linked! Loading your account…';

  @override
  String pairFailed(String error) {
    return 'Could not start pairing: $error';
  }

  @override
  String get pairLater => 'Continue without an account';

  @override
  String get addPlaylistTitle => 'Add a playlist';

  @override
  String get addPlaylistWebStep1 =>
      'On your phone or computer, scan the QR code or open';

  @override
  String get addPlaylistWebStep2 =>
      'Sign in to your account, then add your M3U or Xtream Codes source.';

  @override
  String get addPlaylistWebStep3 =>
      'Come back here: the playlist shows up automatically, or press the button below.';

  @override
  String get addPlaylistDone => 'I added my playlist';

  @override
  String get addPlaylistChecking => 'Checking…';

  @override
  String addPlaylistAutoRefresh(int seconds) {
    return 'This screen refreshes itself every $seconds seconds.';
  }

  @override
  String get addPlaylistNotYet =>
      'No playlist found yet. Check that it is saved on the portal and accessible to this profile.';

  @override
  String addPlaylistPairIntro(String url) {
    return 'Playlists are managed on the web. Scan the QR code or enter this code on $url to add an M3U or Xtream Codes source to your account.';
  }

  @override
  String get addPlaylistConfirmed => 'Playlist added! Syncing…';

  @override
  String get whoIsWatching => 'Who\'s watching?';

  @override
  String get switchProfile => 'Switch profile';

  @override
  String get kidsProfile => 'Kids';

  @override
  String get manageProfilesHint =>
      'Profiles are created and edited on the web portal.';

  @override
  String get noProfileAccess =>
      'This profile has no access to any playlist. Edit its access on the web portal.';

  @override
  String get account => 'Account';

  @override
  String get accountPlan => 'Plan';

  @override
  String accountDevices(int count) {
    return 'Up to $count device(s)';
  }

  @override
  String get accountExpired => 'Account expired';

  @override
  String accountManageOnline(String url) {
    return 'Manage your devices, profiles and playlists at $url';
  }

  @override
  String get deviceName => 'Device name';

  @override
  String get unpairDevice => 'Unlink this device';

  @override
  String get unpairDeviceConfirm =>
      'The device will be detached from your account and must be linked again with a new code. Your playlists and history stay on your account.';

  @override
  String get unpaired => 'Device not linked';

  @override
  String get unpairedDescription =>
      'This device is no longer linked to an account. Link it again to get your playlists back.';

  @override
  String get pairDevice => 'Link device';

  @override
  String get noPlaylistTitle => 'No playlist';

  @override
  String get noPlaylistDescription =>
      'Your account has no playlist this profile can access yet.';

  @override
  String get addPlaylist => 'Add playlist';

  @override
  String get addM3u => 'Add M3U URL';

  @override
  String get addM3uFile => 'Add M3U file';

  @override
  String get addXtream => 'Add Xtream Codes login';

  @override
  String get refreshPlaylists => 'Refresh';

  @override
  String get changePlaylist => 'Change playlist';

  @override
  String get myPlaylists => 'My playlists';

  @override
  String get playlistName => 'Playlist name';

  @override
  String get playlistUrl => 'M3U URL';

  @override
  String get epgUrl => 'EPG URL (XMLTV, optional)';

  @override
  String get serverUrl => 'Server URL';

  @override
  String get serverUrlHint => 'http://example.com:8080';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get protectWithPin => 'Protect with a PIN';

  @override
  String get pinCode => 'PIN code';

  @override
  String get enterPin => 'Enter the PIN code';

  @override
  String get pinIncorrect => 'Incorrect PIN.';

  @override
  String get playlistProtected => 'This playlist is protected.';

  @override
  String get deletePlaylist => 'Delete playlist';

  @override
  String get editPlaylist => 'Edit playlist';

  @override
  String get editOnPortal => 'Portal playlists are edited on the web portal.';

  @override
  String deletePlaylistConfirm(String name) {
    return 'Delete \"$name\" from this device?';
  }

  @override
  String get playlistFromPortal => 'From the portal';

  @override
  String get playlistLocal => 'Added on this device';

  @override
  String playlistExpires(String date) {
    return 'Expires: $date';
  }

  @override
  String get invalidM3u => 'Please provide a valid M3U playlist.';

  @override
  String get invalidUrl => 'Invalid URL.';

  @override
  String get fieldRequired => 'This field is required.';

  @override
  String get playlistLoading => 'Loading playlist…';

  @override
  String importProgress(String done, String total) {
    return '$done / $total';
  }

  @override
  String get importingLive => 'Importing live channels…';

  @override
  String get importingMovies => 'Importing movies…';

  @override
  String get importingSeries => 'Importing series…';

  @override
  String get importingEpg => 'Importing EPG…';

  @override
  String get importDone => 'Playlist loaded.';

  @override
  String get importFailed =>
      'Playlist is not working. Check the URL or credentials.';

  @override
  String get loginFailed => 'Login failed. Check the username and password.';

  @override
  String accountExpires(String date) {
    return 'Account expires: $date';
  }

  @override
  String activeConnections(String active, String max) {
    return 'Connections: $active / $max';
  }

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeAmoled => 'AMOLED black';

  @override
  String get languageSystem => 'System';

  @override
  String get parentalControl => 'Parental control';

  @override
  String get parentalPin => 'Parental PIN';

  @override
  String get setParentalPin => 'Set parental PIN';

  @override
  String get changeParentalPin => 'Change parental PIN';

  @override
  String get confirmPin => 'Confirm PIN';

  @override
  String get pinMismatch => 'The PIN codes do not match.';

  @override
  String get pinChanged => 'PIN changed.';

  @override
  String get hideCategories => 'Hide categories';

  @override
  String get hideLiveCategories => 'Hidden live categories';

  @override
  String get hideMovieCategories => 'Hidden movie categories';

  @override
  String get hideSeriesCategories => 'Hidden series categories';

  @override
  String get lockedChannels => 'Locked channels';

  @override
  String get lockChannel => 'Lock channel';

  @override
  String get unlockChannel => 'Unlock channel';

  @override
  String get channelLocked => 'This channel is locked.';

  @override
  String get liveStreamFormat => 'Live stream format';

  @override
  String get formatTs => 'MPEG-TS (default)';

  @override
  String get formatHls => 'HLS (m3u8)';

  @override
  String get autoUpdatePlaylist => 'Auto-update playlist';

  @override
  String get autoUpdateNever => 'Manually';

  @override
  String get autoUpdateDaily => 'Every day';

  @override
  String get autoUpdateAlways => 'Every launch';

  @override
  String get layout => 'Layout';

  @override
  String get layoutGrid => 'Grid';

  @override
  String get layoutList => 'List';

  @override
  String get sortOrder => 'Sort order';

  @override
  String get sortDefault => 'Default';

  @override
  String get sortAz => 'A → Z';

  @override
  String get sortZa => 'Z → A';

  @override
  String get sortAdded => 'Recently added';

  @override
  String get sortRating => 'Rating';

  @override
  String get subtitles => 'Subtitles';

  @override
  String get subtitleSize => 'Subtitle size';

  @override
  String get subtitleColor => 'Subtitle color';

  @override
  String get subtitleBackground => 'Subtitle background';

  @override
  String get audioTrack => 'Audio track';

  @override
  String get subtitleTrack => 'Subtitle track';

  @override
  String get off => 'Off';

  @override
  String get videoFit => 'Video fit';

  @override
  String get fitContain => 'Fit';

  @override
  String get fitCover => 'Fill';

  @override
  String get fitStretch => 'Stretch';

  @override
  String get videoDecoder => 'Video decoding';

  @override
  String get decoderAuto =>
      'Automatic (tries direct, then hardware, then software)';

  @override
  String get decoderDirect => 'Direct hardware — smoothest';

  @override
  String get decoderCompat => 'Hardware (copy) — compatible';

  @override
  String get decoderSoftware => 'Software — works everywhere, slower';

  @override
  String get qualityNotSupportedLowEnd =>
      'This quality is not supported on this device';

  @override
  String get performanceMode => 'Performance mode';

  @override
  String get performanceAuto => 'Automatic (on for TV boxes)';

  @override
  String get performanceOn => 'On — lighter visuals, smoother';

  @override
  String get performanceOff => 'Off — full visuals';

  @override
  String get networkDns => 'Network / DNS';

  @override
  String get dnsMode => 'DNS';

  @override
  String get dnsModeSystem => 'System (device default)';

  @override
  String get dnsModeAuto => 'Automatic — picks the fastest';

  @override
  String get dnsModeServer => 'Choose a server';

  @override
  String get dnsModeCustom => 'Custom';

  @override
  String get dnsServer => 'DNS server';

  @override
  String get dnsCustomAddresses => 'Custom DNS addresses';

  @override
  String get dnsCustomAddressesHint => 'e.g. 1.1.1.1, 1.0.0.1';

  @override
  String get dnsTest => 'Test DNS';

  @override
  String get dnsTestHint => 'Checks which DNS can load your playlist\'s server';

  @override
  String dnsTestIpHost(String host) {
    return 'This playlist uses an IP address ($host): no DNS is involved. If your internet provider blocks it, changing DNS will not help.';
  }

  @override
  String get dnsTestNoPlaylist => 'No active playlist to test against.';

  @override
  String get reportProblem => 'Report a problem';

  @override
  String get reportProblemHint =>
      'Sends the log of your recent actions for analysis.';

  @override
  String problemReported(String id) {
    return 'Report sent (ref. $id).';
  }

  @override
  String get clearCache => 'Clear cache';

  @override
  String get clearHistory => 'Clear history';

  @override
  String get cleared => 'Done.';

  @override
  String get timeFormat => 'Time format';

  @override
  String get timeFormat24 => '24-hour';

  @override
  String get timeFormat12 => '12-hour';

  @override
  String get about => 'About';

  @override
  String get disclaimer =>
      'MultIPTV is a general media player and does not include any content or playlists.';

  @override
  String get externalPlayer => 'Open in external player';

  @override
  String get externalPlayerMissing =>
      'No external player found (VLC or MX Player).';

  @override
  String get myGroups => 'My groups';

  @override
  String get addGroup => 'Add group';

  @override
  String get groupName => 'Group name';

  @override
  String get addChannels => 'Add channels';

  @override
  String get removeGroup => 'Remove group';

  @override
  String get playbackError => 'Playback error';

  @override
  String get playbackErrorDescription =>
      'The stream could not be played. Try again or choose another stream.';

  @override
  String get channelList => 'Channels';

  @override
  String get programGuide => 'Program guide';

  @override
  String get playbackSpeed => 'Speed';

  @override
  String get nextEpisode => 'Next episode';

  @override
  String get previousChannel => 'Previous channel';

  @override
  String get nextChannel => 'Next channel';

  @override
  String get exit => 'Exit';

  @override
  String get exitDescription => 'Do you want to exit the app?';

  @override
  String get continueWatching => 'Continue watching';

  @override
  String get recentChannels => 'Recent channels';

  @override
  String get updateRequired => 'Update required';

  @override
  String get updateNow => 'Update now';

  @override
  String get updateDescription =>
      'A new version is required to continue. Please update the app.';

  @override
  String get maintenance =>
      'The service is under maintenance. Please try again later.';

  @override
  String get featured => 'Featured';

  @override
  String get recentlyAddedMovies => 'New movies';

  @override
  String get recentlyAddedSeries => 'New series';

  @override
  String get moreInfo => 'More info';

  @override
  String get nowLabel => 'Now';

  @override
  String get nextLabel => 'Next';

  @override
  String remaining(String time) {
    return '$time left';
  }

  @override
  String episodeNumber(int n) {
    return 'Episode $n';
  }

  @override
  String get appearance => 'Appearance';

  @override
  String get playback => 'Playback';

  @override
  String get episodesTitle => 'Episodes';

  @override
  String get featuredSource => 'Featured content';

  @override
  String get featuredCurated => 'Editors\' picks';

  @override
  String get featuredPopular => 'Most watched right now';

  @override
  String get featuredTmdb => 'Trending on TMDB';

  @override
  String get watchNow => 'Watch';

  @override
  String get openLink => 'Open';

  @override
  String get eventNow => 'Now';

  @override
  String todayAt(String time) {
    return 'Today at $time';
  }

  @override
  String tomorrowAt(String time) {
    return 'Tomorrow at $time';
  }

  @override
  String seasonsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seasons',
      one: '1 season',
    );
    return '$_temp0';
  }
}
