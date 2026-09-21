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
  String get macAddress => 'MAC address';

  @override
  String get deviceKey => 'Device key';

  @override
  String get deviceType => 'Device type';

  @override
  String get appVersion => 'App version';

  @override
  String get portalUrl => 'Portal';

  @override
  String get scanQr =>
      'Scan the QR code to add a playlist from the web portal.';

  @override
  String get openPortal => 'Open the portal';

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
  String get deviceKeyConflict =>
      'This MAC address is already registered with another device key. Ask the administrator to delete the device on the portal, then restart the app.';

  @override
  String get noPlaylistTitle => 'No playlist for this device';

  @override
  String get noPlaylistDescription =>
      'Playlists can be added here or on the web portal using your MAC address and device key.';

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
  String get accountExpired => 'Account expired';

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
  String get themeSystem => 'System';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get themeAmoled => 'AMOLED black';

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
  String get seeAll => 'See all';

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
}
