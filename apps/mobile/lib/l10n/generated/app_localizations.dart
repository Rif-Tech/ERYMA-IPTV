import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'MultIPTV'**
  String get appName;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search channels, movies, series…'**
  String get searchHint;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results.'**
  String get noResults;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @liveTv.
  ///
  /// In en, this message translates to:
  /// **'Live TV'**
  String get liveTv;

  /// No description provided for @movies.
  ///
  /// In en, this message translates to:
  /// **'Movies'**
  String get movies;

  /// No description provided for @series.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get series;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @recentlyViewed.
  ///
  /// In en, this message translates to:
  /// **'Recently viewed'**
  String get recentlyViewed;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @catchUp.
  ///
  /// In en, this message translates to:
  /// **'Catch-up'**
  String get catchUp;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @noChannels.
  ///
  /// In en, this message translates to:
  /// **'No channels.'**
  String get noChannels;

  /// No description provided for @noMovies.
  ///
  /// In en, this message translates to:
  /// **'No movies.'**
  String get noMovies;

  /// No description provided for @noSeries.
  ///
  /// In en, this message translates to:
  /// **'No series.'**
  String get noSeries;

  /// No description provided for @noEpisodes.
  ///
  /// In en, this message translates to:
  /// **'No episodes.'**
  String get noEpisodes;

  /// No description provided for @noEpgAvailable.
  ///
  /// In en, this message translates to:
  /// **'No EPG available.'**
  String get noEpgAvailable;

  /// No description provided for @noFavorites.
  ///
  /// In en, this message translates to:
  /// **'Nothing in favorites yet.'**
  String get noFavorites;

  /// No description provided for @noRecent.
  ///
  /// In en, this message translates to:
  /// **'Nothing watched yet.'**
  String get noRecent;

  /// No description provided for @nowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get nowPlaying;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @season.
  ///
  /// In en, this message translates to:
  /// **'Season {number}'**
  String season(int number);

  /// No description provided for @episode.
  ///
  /// In en, this message translates to:
  /// **'Episode {number}'**
  String episode(int number);

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @resumeFrom.
  ///
  /// In en, this message translates to:
  /// **'Resume from {time}'**
  String resumeFrom(String time);

  /// No description provided for @startOver.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get startOver;

  /// No description provided for @addToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addToFavorites;

  /// No description provided for @removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFromFavorites;

  /// No description provided for @watchTrailer.
  ///
  /// In en, this message translates to:
  /// **'Watch trailer'**
  String get watchTrailer;

  /// No description provided for @cast.
  ///
  /// In en, this message translates to:
  /// **'Cast'**
  String get cast;

  /// No description provided for @director.
  ///
  /// In en, this message translates to:
  /// **'Director'**
  String get director;

  /// No description provided for @genre.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get genre;

  /// No description provided for @releaseDate.
  ///
  /// In en, this message translates to:
  /// **'Release date'**
  String get releaseDate;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @deviceInfo.
  ///
  /// In en, this message translates to:
  /// **'Device information'**
  String get deviceInfo;

  /// No description provided for @deviceType.
  ///
  /// In en, this message translates to:
  /// **'Device type'**
  String get deviceType;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get appVersion;

  /// No description provided for @portalUrl.
  ///
  /// In en, this message translates to:
  /// **'Portal'**
  String get portalUrl;

  /// No description provided for @managePlaylistsOnline.
  ///
  /// In en, this message translates to:
  /// **'Manage my account on the web'**
  String get managePlaylistsOnline;

  /// No description provided for @trialDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'Free trial: {days} day(s) left'**
  String trialDaysLeft(int days);

  /// No description provided for @trialEnded.
  ///
  /// In en, this message translates to:
  /// **'Your free trial has ended. Please activate this device on the portal.'**
  String get trialEnded;

  /// No description provided for @deviceActivated.
  ///
  /// In en, this message translates to:
  /// **'Device activated'**
  String get deviceActivated;

  /// No description provided for @deviceExpired.
  ///
  /// In en, this message translates to:
  /// **'Activation expired on {date}'**
  String deviceExpired(String date);

  /// No description provided for @deviceActiveUntil.
  ///
  /// In en, this message translates to:
  /// **'Active until {date}'**
  String deviceActiveUntil(String date);

  /// No description provided for @deviceActiveUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Active, no expiration'**
  String get deviceActiveUnlimited;

  /// No description provided for @activationRequired.
  ///
  /// In en, this message translates to:
  /// **'Activation required'**
  String get activationRequired;

  /// No description provided for @checkInternet.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection.'**
  String get checkInternet;

  /// No description provided for @portalUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Portal unreachable. Local playlists are still available.'**
  String get portalUnreachable;

  /// No description provided for @pairTitle.
  ///
  /// In en, this message translates to:
  /// **'Link this device to your account'**
  String get pairTitle;

  /// No description provided for @pairStep1.
  ///
  /// In en, this message translates to:
  /// **'On your phone or computer, open {url}'**
  String pairStep1(String url);

  /// No description provided for @pairStep2.
  ///
  /// In en, this message translates to:
  /// **'Sign in (or create a free account).'**
  String get pairStep2;

  /// No description provided for @pairStep3.
  ///
  /// In en, this message translates to:
  /// **'Enter the code below, or scan the QR code.'**
  String get pairStep3;

  /// No description provided for @pairCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get pairCode;

  /// No description provided for @pairExpiresIn.
  ///
  /// In en, this message translates to:
  /// **'Code expires in {time}'**
  String pairExpiresIn(String time);

  /// No description provided for @pairExpired.
  ///
  /// In en, this message translates to:
  /// **'This code has expired.'**
  String get pairExpired;

  /// No description provided for @pairNewCode.
  ///
  /// In en, this message translates to:
  /// **'New code'**
  String get pairNewCode;

  /// No description provided for @pairWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for confirmation…'**
  String get pairWaiting;

  /// No description provided for @pairConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Device linked! Loading your account…'**
  String get pairConfirmed;

  /// No description provided for @pairFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start pairing: {error}'**
  String pairFailed(String error);

  /// No description provided for @pairLater.
  ///
  /// In en, this message translates to:
  /// **'Continue without an account'**
  String get pairLater;

  /// No description provided for @addPlaylistTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a playlist'**
  String get addPlaylistTitle;

  /// No description provided for @addPlaylistWebStep1.
  ///
  /// In en, this message translates to:
  /// **'On your phone or computer, scan the QR code or open'**
  String get addPlaylistWebStep1;

  /// No description provided for @addPlaylistWebStep2.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account, then add your M3U or Xtream Codes source.'**
  String get addPlaylistWebStep2;

  /// No description provided for @addPlaylistWebStep3.
  ///
  /// In en, this message translates to:
  /// **'Come back here: the playlist shows up automatically, or press the button below.'**
  String get addPlaylistWebStep3;

  /// No description provided for @addPlaylistDone.
  ///
  /// In en, this message translates to:
  /// **'I added my playlist'**
  String get addPlaylistDone;

  /// No description provided for @addPlaylistChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get addPlaylistChecking;

  /// No description provided for @addPlaylistAutoRefresh.
  ///
  /// In en, this message translates to:
  /// **'This screen refreshes itself every {seconds} seconds.'**
  String addPlaylistAutoRefresh(int seconds);

  /// No description provided for @addPlaylistNotYet.
  ///
  /// In en, this message translates to:
  /// **'No playlist found yet. Check that it is saved on the portal and accessible to this profile.'**
  String get addPlaylistNotYet;

  /// No description provided for @addPlaylistPairIntro.
  ///
  /// In en, this message translates to:
  /// **'Playlists are managed on the web. Scan the QR code or enter this code on {url} to add an M3U or Xtream Codes source to your account.'**
  String addPlaylistPairIntro(String url);

  /// No description provided for @addPlaylistConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Playlist added! Syncing…'**
  String get addPlaylistConfirmed;

  /// No description provided for @whoIsWatching.
  ///
  /// In en, this message translates to:
  /// **'Who\'s watching?'**
  String get whoIsWatching;

  /// No description provided for @switchProfile.
  ///
  /// In en, this message translates to:
  /// **'Switch profile'**
  String get switchProfile;

  /// No description provided for @kidsProfile.
  ///
  /// In en, this message translates to:
  /// **'Kids'**
  String get kidsProfile;

  /// No description provided for @manageProfilesHint.
  ///
  /// In en, this message translates to:
  /// **'Profiles are created and edited on the web portal.'**
  String get manageProfilesHint;

  /// No description provided for @noProfileAccess.
  ///
  /// In en, this message translates to:
  /// **'This profile has no access to any playlist. Edit its access on the web portal.'**
  String get noProfileAccess;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @accountPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get accountPlan;

  /// No description provided for @accountDevices.
  ///
  /// In en, this message translates to:
  /// **'Up to {count} device(s)'**
  String accountDevices(int count);

  /// No description provided for @accountExpired.
  ///
  /// In en, this message translates to:
  /// **'Account expired'**
  String get accountExpired;

  /// No description provided for @accountManageOnline.
  ///
  /// In en, this message translates to:
  /// **'Manage your devices, profiles and playlists at {url}'**
  String accountManageOnline(String url);

  /// No description provided for @deviceName.
  ///
  /// In en, this message translates to:
  /// **'Device name'**
  String get deviceName;

  /// No description provided for @unpairDevice.
  ///
  /// In en, this message translates to:
  /// **'Unlink this device'**
  String get unpairDevice;

  /// No description provided for @unpairDeviceConfirm.
  ///
  /// In en, this message translates to:
  /// **'The device will be detached from your account and must be linked again with a new code. Your playlists and history stay on your account.'**
  String get unpairDeviceConfirm;

  /// No description provided for @unpaired.
  ///
  /// In en, this message translates to:
  /// **'Device not linked'**
  String get unpaired;

  /// No description provided for @unpairedDescription.
  ///
  /// In en, this message translates to:
  /// **'This device is no longer linked to an account. Link it again to get your playlists back.'**
  String get unpairedDescription;

  /// No description provided for @pairDevice.
  ///
  /// In en, this message translates to:
  /// **'Link device'**
  String get pairDevice;

  /// No description provided for @noPlaylistTitle.
  ///
  /// In en, this message translates to:
  /// **'No playlist'**
  String get noPlaylistTitle;

  /// No description provided for @noPlaylistDescription.
  ///
  /// In en, this message translates to:
  /// **'Your account has no playlist this profile can access yet.'**
  String get noPlaylistDescription;

  /// No description provided for @addPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add playlist'**
  String get addPlaylist;

  /// No description provided for @addM3u.
  ///
  /// In en, this message translates to:
  /// **'Add M3U URL'**
  String get addM3u;

  /// No description provided for @addM3uFile.
  ///
  /// In en, this message translates to:
  /// **'Add M3U file'**
  String get addM3uFile;

  /// No description provided for @addXtream.
  ///
  /// In en, this message translates to:
  /// **'Add Xtream Codes login'**
  String get addXtream;

  /// No description provided for @refreshPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshPlaylists;

  /// No description provided for @changePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Change playlist'**
  String get changePlaylist;

  /// No description provided for @myPlaylists.
  ///
  /// In en, this message translates to:
  /// **'My playlists'**
  String get myPlaylists;

  /// No description provided for @playlistName.
  ///
  /// In en, this message translates to:
  /// **'Playlist name'**
  String get playlistName;

  /// No description provided for @playlistUrl.
  ///
  /// In en, this message translates to:
  /// **'M3U URL'**
  String get playlistUrl;

  /// No description provided for @epgUrl.
  ///
  /// In en, this message translates to:
  /// **'EPG URL (XMLTV, optional)'**
  String get epgUrl;

  /// No description provided for @serverUrl.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get serverUrl;

  /// No description provided for @serverUrlHint.
  ///
  /// In en, this message translates to:
  /// **'http://example.com:8080'**
  String get serverUrlHint;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @protectWithPin.
  ///
  /// In en, this message translates to:
  /// **'Protect with a PIN'**
  String get protectWithPin;

  /// No description provided for @pinCode.
  ///
  /// In en, this message translates to:
  /// **'PIN code'**
  String get pinCode;

  /// No description provided for @enterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter the PIN code'**
  String get enterPin;

  /// No description provided for @pinIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN.'**
  String get pinIncorrect;

  /// No description provided for @playlistProtected.
  ///
  /// In en, this message translates to:
  /// **'This playlist is protected.'**
  String get playlistProtected;

  /// No description provided for @deletePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Delete playlist'**
  String get deletePlaylist;

  /// No description provided for @editPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Edit playlist'**
  String get editPlaylist;

  /// No description provided for @editOnPortal.
  ///
  /// In en, this message translates to:
  /// **'Portal playlists are edited on the web portal.'**
  String get editOnPortal;

  /// No description provided for @deletePlaylistConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\" from this device?'**
  String deletePlaylistConfirm(String name);

  /// No description provided for @playlistFromPortal.
  ///
  /// In en, this message translates to:
  /// **'From the portal'**
  String get playlistFromPortal;

  /// No description provided for @playlistLocal.
  ///
  /// In en, this message translates to:
  /// **'Added on this device'**
  String get playlistLocal;

  /// No description provided for @playlistExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires: {date}'**
  String playlistExpires(String date);

  /// No description provided for @invalidM3u.
  ///
  /// In en, this message translates to:
  /// **'Please provide a valid M3U playlist.'**
  String get invalidM3u;

  /// No description provided for @invalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Invalid URL.'**
  String get invalidUrl;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get fieldRequired;

  /// No description provided for @playlistLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading playlist…'**
  String get playlistLoading;

  /// No description provided for @importProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} / {total}'**
  String importProgress(String done, String total);

  /// No description provided for @importingLive.
  ///
  /// In en, this message translates to:
  /// **'Importing live channels…'**
  String get importingLive;

  /// No description provided for @importingMovies.
  ///
  /// In en, this message translates to:
  /// **'Importing movies…'**
  String get importingMovies;

  /// No description provided for @importingSeries.
  ///
  /// In en, this message translates to:
  /// **'Importing series…'**
  String get importingSeries;

  /// No description provided for @importingEpg.
  ///
  /// In en, this message translates to:
  /// **'Importing EPG…'**
  String get importingEpg;

  /// No description provided for @importDone.
  ///
  /// In en, this message translates to:
  /// **'Playlist loaded.'**
  String get importDone;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Playlist is not working. Check the URL or credentials.'**
  String get importFailed;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Check the username and password.'**
  String get loginFailed;

  /// No description provided for @accountExpires.
  ///
  /// In en, this message translates to:
  /// **'Account expires: {date}'**
  String accountExpires(String date);

  /// No description provided for @activeConnections.
  ///
  /// In en, this message translates to:
  /// **'Connections: {active} / {max}'**
  String activeConnections(String active, String max);

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeAmoled.
  ///
  /// In en, this message translates to:
  /// **'AMOLED black'**
  String get themeAmoled;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @parentalControl.
  ///
  /// In en, this message translates to:
  /// **'Parental control'**
  String get parentalControl;

  /// No description provided for @parentalPin.
  ///
  /// In en, this message translates to:
  /// **'Parental PIN'**
  String get parentalPin;

  /// No description provided for @setParentalPin.
  ///
  /// In en, this message translates to:
  /// **'Set parental PIN'**
  String get setParentalPin;

  /// No description provided for @changeParentalPin.
  ///
  /// In en, this message translates to:
  /// **'Change parental PIN'**
  String get changeParentalPin;

  /// No description provided for @confirmPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get confirmPin;

  /// No description provided for @pinMismatch.
  ///
  /// In en, this message translates to:
  /// **'The PIN codes do not match.'**
  String get pinMismatch;

  /// No description provided for @pinChanged.
  ///
  /// In en, this message translates to:
  /// **'PIN changed.'**
  String get pinChanged;

  /// No description provided for @hideCategories.
  ///
  /// In en, this message translates to:
  /// **'Hide categories'**
  String get hideCategories;

  /// No description provided for @hideLiveCategories.
  ///
  /// In en, this message translates to:
  /// **'Hidden live categories'**
  String get hideLiveCategories;

  /// No description provided for @hideMovieCategories.
  ///
  /// In en, this message translates to:
  /// **'Hidden movie categories'**
  String get hideMovieCategories;

  /// No description provided for @hideSeriesCategories.
  ///
  /// In en, this message translates to:
  /// **'Hidden series categories'**
  String get hideSeriesCategories;

  /// No description provided for @lockedChannels.
  ///
  /// In en, this message translates to:
  /// **'Locked channels'**
  String get lockedChannels;

  /// No description provided for @lockChannel.
  ///
  /// In en, this message translates to:
  /// **'Lock channel'**
  String get lockChannel;

  /// No description provided for @unlockChannel.
  ///
  /// In en, this message translates to:
  /// **'Unlock channel'**
  String get unlockChannel;

  /// No description provided for @channelLocked.
  ///
  /// In en, this message translates to:
  /// **'This channel is locked.'**
  String get channelLocked;

  /// No description provided for @liveStreamFormat.
  ///
  /// In en, this message translates to:
  /// **'Live stream format'**
  String get liveStreamFormat;

  /// No description provided for @formatTs.
  ///
  /// In en, this message translates to:
  /// **'MPEG-TS (default)'**
  String get formatTs;

  /// No description provided for @formatHls.
  ///
  /// In en, this message translates to:
  /// **'HLS (m3u8)'**
  String get formatHls;

  /// No description provided for @autoUpdatePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Auto-update playlist'**
  String get autoUpdatePlaylist;

  /// No description provided for @autoUpdateNever.
  ///
  /// In en, this message translates to:
  /// **'Manually'**
  String get autoUpdateNever;

  /// No description provided for @autoUpdateDaily.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get autoUpdateDaily;

  /// No description provided for @autoUpdateAlways.
  ///
  /// In en, this message translates to:
  /// **'Every launch'**
  String get autoUpdateAlways;

  /// No description provided for @layout.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get layout;

  /// No description provided for @layoutGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get layoutGrid;

  /// No description provided for @layoutList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get layoutList;

  /// No description provided for @sortOrder.
  ///
  /// In en, this message translates to:
  /// **'Sort order'**
  String get sortOrder;

  /// No description provided for @sortDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get sortDefault;

  /// No description provided for @sortAz.
  ///
  /// In en, this message translates to:
  /// **'A → Z'**
  String get sortAz;

  /// No description provided for @sortZa.
  ///
  /// In en, this message translates to:
  /// **'Z → A'**
  String get sortZa;

  /// No description provided for @sortAdded.
  ///
  /// In en, this message translates to:
  /// **'Recently added'**
  String get sortAdded;

  /// No description provided for @sortRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get sortRating;

  /// No description provided for @subtitles.
  ///
  /// In en, this message translates to:
  /// **'Subtitles'**
  String get subtitles;

  /// No description provided for @subtitleSize.
  ///
  /// In en, this message translates to:
  /// **'Subtitle size'**
  String get subtitleSize;

  /// No description provided for @subtitleColor.
  ///
  /// In en, this message translates to:
  /// **'Subtitle color'**
  String get subtitleColor;

  /// No description provided for @subtitleBackground.
  ///
  /// In en, this message translates to:
  /// **'Subtitle background'**
  String get subtitleBackground;

  /// No description provided for @audioTrack.
  ///
  /// In en, this message translates to:
  /// **'Audio track'**
  String get audioTrack;

  /// No description provided for @subtitleTrack.
  ///
  /// In en, this message translates to:
  /// **'Subtitle track'**
  String get subtitleTrack;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @videoFit.
  ///
  /// In en, this message translates to:
  /// **'Video fit'**
  String get videoFit;

  /// No description provided for @fitContain.
  ///
  /// In en, this message translates to:
  /// **'Fit'**
  String get fitContain;

  /// No description provided for @fitCover.
  ///
  /// In en, this message translates to:
  /// **'Fill'**
  String get fitCover;

  /// No description provided for @fitStretch.
  ///
  /// In en, this message translates to:
  /// **'Stretch'**
  String get fitStretch;

  /// No description provided for @videoDecoder.
  ///
  /// In en, this message translates to:
  /// **'Video decoding'**
  String get videoDecoder;

  /// No description provided for @decoderAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic (tries direct, then hardware, then software)'**
  String get decoderAuto;

  /// No description provided for @decoderDirect.
  ///
  /// In en, this message translates to:
  /// **'Direct hardware — smoothest'**
  String get decoderDirect;

  /// No description provided for @decoderCompat.
  ///
  /// In en, this message translates to:
  /// **'Hardware (copy) — compatible'**
  String get decoderCompat;

  /// No description provided for @decoderSoftware.
  ///
  /// In en, this message translates to:
  /// **'Software — works everywhere, slower'**
  String get decoderSoftware;

  /// No description provided for @qualityNotSupportedLowEnd.
  ///
  /// In en, this message translates to:
  /// **'This quality is not supported on this device'**
  String get qualityNotSupportedLowEnd;

  /// No description provided for @performanceMode.
  ///
  /// In en, this message translates to:
  /// **'Performance mode'**
  String get performanceMode;

  /// No description provided for @performanceAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic (on for TV boxes)'**
  String get performanceAuto;

  /// No description provided for @performanceOn.
  ///
  /// In en, this message translates to:
  /// **'On — lighter visuals, smoother'**
  String get performanceOn;

  /// No description provided for @performanceOff.
  ///
  /// In en, this message translates to:
  /// **'Off — full visuals'**
  String get performanceOff;

  /// No description provided for @networkDns.
  ///
  /// In en, this message translates to:
  /// **'Network / DNS'**
  String get networkDns;

  /// No description provided for @dnsMode.
  ///
  /// In en, this message translates to:
  /// **'DNS'**
  String get dnsMode;

  /// No description provided for @dnsModeSystem.
  ///
  /// In en, this message translates to:
  /// **'System (device default)'**
  String get dnsModeSystem;

  /// No description provided for @dnsModeAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic — picks the fastest'**
  String get dnsModeAuto;

  /// No description provided for @dnsModeServer.
  ///
  /// In en, this message translates to:
  /// **'Choose a server'**
  String get dnsModeServer;

  /// No description provided for @dnsModeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get dnsModeCustom;

  /// No description provided for @dnsServer.
  ///
  /// In en, this message translates to:
  /// **'DNS server'**
  String get dnsServer;

  /// No description provided for @dnsCustomAddresses.
  ///
  /// In en, this message translates to:
  /// **'Custom DNS addresses'**
  String get dnsCustomAddresses;

  /// No description provided for @dnsCustomAddressesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 1.1.1.1, 1.0.0.1'**
  String get dnsCustomAddressesHint;

  /// No description provided for @dnsTest.
  ///
  /// In en, this message translates to:
  /// **'Test DNS'**
  String get dnsTest;

  /// No description provided for @dnsTestHint.
  ///
  /// In en, this message translates to:
  /// **'Checks which DNS can load your playlist\'s server'**
  String get dnsTestHint;

  /// No description provided for @dnsTestNoPlaylist.
  ///
  /// In en, this message translates to:
  /// **'No active playlist to test against.'**
  String get dnsTestNoPlaylist;

  /// No description provided for @reportProblem.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get reportProblem;

  /// No description provided for @reportProblemHint.
  ///
  /// In en, this message translates to:
  /// **'Sends the log of your recent actions for analysis.'**
  String get reportProblemHint;

  /// No description provided for @problemReported.
  ///
  /// In en, this message translates to:
  /// **'Report sent (ref. {id}).'**
  String problemReported(String id);

  /// No description provided for @clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get clearCache;

  /// No description provided for @clearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get clearHistory;

  /// No description provided for @cleared.
  ///
  /// In en, this message translates to:
  /// **'Done.'**
  String get cleared;

  /// No description provided for @timeFormat.
  ///
  /// In en, this message translates to:
  /// **'Time format'**
  String get timeFormat;

  /// No description provided for @timeFormat24.
  ///
  /// In en, this message translates to:
  /// **'24-hour'**
  String get timeFormat24;

  /// No description provided for @timeFormat12.
  ///
  /// In en, this message translates to:
  /// **'12-hour'**
  String get timeFormat12;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @disclaimer.
  ///
  /// In en, this message translates to:
  /// **'MultIPTV is a general media player and does not include any content or playlists.'**
  String get disclaimer;

  /// No description provided for @externalPlayer.
  ///
  /// In en, this message translates to:
  /// **'Open in external player'**
  String get externalPlayer;

  /// No description provided for @externalPlayerMissing.
  ///
  /// In en, this message translates to:
  /// **'No external player found (VLC or MX Player).'**
  String get externalPlayerMissing;

  /// No description provided for @myGroups.
  ///
  /// In en, this message translates to:
  /// **'My groups'**
  String get myGroups;

  /// No description provided for @addGroup.
  ///
  /// In en, this message translates to:
  /// **'Add group'**
  String get addGroup;

  /// No description provided for @groupName.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get groupName;

  /// No description provided for @addChannels.
  ///
  /// In en, this message translates to:
  /// **'Add channels'**
  String get addChannels;

  /// No description provided for @removeGroup.
  ///
  /// In en, this message translates to:
  /// **'Remove group'**
  String get removeGroup;

  /// No description provided for @playbackError.
  ///
  /// In en, this message translates to:
  /// **'Playback error'**
  String get playbackError;

  /// No description provided for @playbackErrorDescription.
  ///
  /// In en, this message translates to:
  /// **'The stream could not be played. Try again or choose another stream.'**
  String get playbackErrorDescription;

  /// No description provided for @channelList.
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get channelList;

  /// No description provided for @programGuide.
  ///
  /// In en, this message translates to:
  /// **'Program guide'**
  String get programGuide;

  /// No description provided for @playbackSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get playbackSpeed;

  /// No description provided for @nextEpisode.
  ///
  /// In en, this message translates to:
  /// **'Next episode'**
  String get nextEpisode;

  /// No description provided for @previousChannel.
  ///
  /// In en, this message translates to:
  /// **'Previous channel'**
  String get previousChannel;

  /// No description provided for @nextChannel.
  ///
  /// In en, this message translates to:
  /// **'Next channel'**
  String get nextChannel;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @exitDescription.
  ///
  /// In en, this message translates to:
  /// **'Do you want to exit the app?'**
  String get exitDescription;

  /// No description provided for @continueWatching.
  ///
  /// In en, this message translates to:
  /// **'Continue watching'**
  String get continueWatching;

  /// No description provided for @recentChannels.
  ///
  /// In en, this message translates to:
  /// **'Recent channels'**
  String get recentChannels;

  /// No description provided for @updateRequired.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get updateRequired;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get updateNow;

  /// No description provided for @updateDescription.
  ///
  /// In en, this message translates to:
  /// **'A new version is required to continue. Please update the app.'**
  String get updateDescription;

  /// No description provided for @maintenance.
  ///
  /// In en, this message translates to:
  /// **'The service is under maintenance. Please try again later.'**
  String get maintenance;

  /// No description provided for @featured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get featured;

  /// No description provided for @recentlyAddedMovies.
  ///
  /// In en, this message translates to:
  /// **'New movies'**
  String get recentlyAddedMovies;

  /// No description provided for @recentlyAddedSeries.
  ///
  /// In en, this message translates to:
  /// **'New series'**
  String get recentlyAddedSeries;

  /// No description provided for @moreInfo.
  ///
  /// In en, this message translates to:
  /// **'More info'**
  String get moreInfo;

  /// No description provided for @nowLabel.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get nowLabel;

  /// No description provided for @nextLabel.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextLabel;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'{time} left'**
  String remaining(String time);

  /// No description provided for @episodeNumber.
  ///
  /// In en, this message translates to:
  /// **'Episode {n}'**
  String episodeNumber(int n);

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @playback.
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get playback;

  /// No description provided for @episodesTitle.
  ///
  /// In en, this message translates to:
  /// **'Episodes'**
  String get episodesTitle;

  /// No description provided for @featuredSource.
  ///
  /// In en, this message translates to:
  /// **'Featured content'**
  String get featuredSource;

  /// No description provided for @featuredCurated.
  ///
  /// In en, this message translates to:
  /// **'Editors\' picks'**
  String get featuredCurated;

  /// No description provided for @featuredPopular.
  ///
  /// In en, this message translates to:
  /// **'Most watched right now'**
  String get featuredPopular;

  /// No description provided for @featuredTmdb.
  ///
  /// In en, this message translates to:
  /// **'Trending on TMDB'**
  String get featuredTmdb;

  /// No description provided for @watchNow.
  ///
  /// In en, this message translates to:
  /// **'Watch'**
  String get watchNow;

  /// No description provided for @openLink.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openLink;

  /// No description provided for @eventNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get eventNow;

  /// No description provided for @todayAt.
  ///
  /// In en, this message translates to:
  /// **'Today at {time}'**
  String todayAt(String time);

  /// No description provided for @tomorrowAt.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow at {time}'**
  String tomorrowAt(String time);

  /// No description provided for @seasonsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 season} other{{count} seasons}}'**
  String seasonsCount(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
