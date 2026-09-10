import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'twist_music_localizations_ar.dart';
import 'twist_music_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of TwistMusicLocalizations
/// returned by `TwistMusicLocalizations.of(context)`.
///
/// Applications need to include `TwistMusicLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/twist_music_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: TwistMusicLocalizations.localizationsDelegates,
///   supportedLocales: TwistMusicLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the TwistMusicLocalizations.supportedLocales
/// property.
abstract class TwistMusicLocalizations {
  TwistMusicLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static TwistMusicLocalizations of(BuildContext context) {
    return Localizations.of<TwistMusicLocalizations>(
        context, TwistMusicLocalizations)!;
  }

  static const LocalizationsDelegate<TwistMusicLocalizations> delegate =
      _TwistMusicLocalizationsDelegate();

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
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @swimlaneTitle.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get swimlaneTitle;

  /// No description provided for @swimlaneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Promoted by Twist'**
  String get swimlaneSubtitle;

  /// No description provided for @previewLabel.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get previewLabel;

  /// No description provided for @nowPlayingLabel.
  ///
  /// In en, this message translates to:
  /// **'Now Playing'**
  String get nowPlayingLabel;

  /// No description provided for @miniPlayerExpand.
  ///
  /// In en, this message translates to:
  /// **'Open full player'**
  String get miniPlayerExpand;

  /// No description provided for @miniPlayerClose.
  ///
  /// In en, this message translates to:
  /// **'Close player'**
  String get miniPlayerClose;

  /// No description provided for @playAction.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playAction;

  /// No description provided for @pauseAction.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pauseAction;

  /// No description provided for @nextTrack.
  ///
  /// In en, this message translates to:
  /// **'Next track'**
  String get nextTrack;

  /// No description provided for @previousTrack.
  ///
  /// In en, this message translates to:
  /// **'Previous track'**
  String get previousTrack;

  /// No description provided for @playbackPosition.
  ///
  /// In en, this message translates to:
  /// **'Playback position'**
  String get playbackPosition;

  /// No description provided for @fullPlayerCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse player'**
  String get fullPlayerCollapse;

  /// No description provided for @fullPlayerSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'PLAYING FROM TWIST MUSIC'**
  String get fullPlayerSectionLabel;

  /// No description provided for @fullPlayerUpNext.
  ///
  /// In en, this message translates to:
  /// **'Up Next'**
  String get fullPlayerUpNext;

  /// No description provided for @promoTitle.
  ///
  /// In en, this message translates to:
  /// **'Listen to the full song on Twist'**
  String get promoTitle;

  /// No description provided for @promoCta.
  ///
  /// In en, this message translates to:
  /// **'Get app'**
  String get promoCta;

  /// No description provided for @downloadPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Want to enjoy the full experience?'**
  String get downloadPromptTitle;

  /// No description provided for @downloadPromptSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Download Twist app and listen to millions of songs'**
  String get downloadPromptSubtitle;

  /// No description provided for @downloadPromptCta.
  ///
  /// In en, this message translates to:
  /// **'Download Twist'**
  String get downloadPromptCta;

  /// No description provided for @downloadPromptDismiss.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get downloadPromptDismiss;

  /// No description provided for @notificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'Music playback'**
  String get notificationChannelName;
}

class _TwistMusicLocalizationsDelegate
    extends LocalizationsDelegate<TwistMusicLocalizations> {
  const _TwistMusicLocalizationsDelegate();

  @override
  Future<TwistMusicLocalizations> load(Locale locale) {
    return SynchronousFuture<TwistMusicLocalizations>(
        lookupTwistMusicLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_TwistMusicLocalizationsDelegate old) => false;
}

TwistMusicLocalizations lookupTwistMusicLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return TwistMusicLocalizationsAr();
    case 'en':
      return TwistMusicLocalizationsEn();
  }

  throw FlutterError(
      'TwistMusicLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
