import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

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
    Locale('pt'),
  ];

  /// The application name, shown in the window title bar.
  ///
  /// In en, this message translates to:
  /// **'Alexandria'**
  String get appTitle;

  /// The action on every failure state that can be retried.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// Heading of the core-unavailable state (UC-38 AF-04). The catalog is not reachable and no catalog call is attempted from here.
  ///
  /// In en, this message translates to:
  /// **'Alexandria\'s core is not available'**
  String get coreUnavailableTitle;

  /// Startup step 1 failed. The path attempted is named because it is the only thing that makes this actionable.
  ///
  /// In en, this message translates to:
  /// **'The Alexandria core could not be loaded from {path}.'**
  String failureCoreLibraryNotLoaded(String path);

  /// Startup step 2 failed: the application-support directory could not be resolved or created.
  ///
  /// In en, this message translates to:
  /// **'The application folder {path} could not be created.'**
  String failureApplicationDirectoryUnavailable(String path);

  /// Startup step 3 failed: alexandria_index_init returned a non-success code.
  ///
  /// In en, this message translates to:
  /// **'The Alexandria core could not open the catalog.'**
  String get failureCoreInitializationFailed;

  /// Startup step 4 failed: the core's health status is not the success code.
  ///
  /// In en, this message translates to:
  /// **'The Alexandria core reported that it is not healthy.'**
  String get failureCoreUnhealthy;

  /// Startup step 4 failed: the core's version is outside the supported range. Both versions are stated.
  ///
  /// In en, this message translates to:
  /// **'This version of Alexandria needs a core matching {required}, but found {found}.'**
  String failureCoreVersionUnsupported(String found, String required);

  /// Startup step 5 fell back. Reported, not fatal.
  ///
  /// In en, this message translates to:
  /// **'Your preferences could not be read, so the system theme and language are being used.'**
  String get failurePreferencesUnreadable;

  /// The core rejected the input. Its verdict is final even when local validation passed.
  ///
  /// In en, this message translates to:
  /// **'Alexandria rejected that as invalid.'**
  String get failureInvalidInput;

  /// The session is absent, expired, or rejected.
  ///
  /// In en, this message translates to:
  /// **'Your session has ended. Please sign in again.'**
  String get failureUnauthorized;

  /// A call was made before the core was initialized — a fault in the startup sequence rather than something the owner did.
  ///
  /// In en, this message translates to:
  /// **'Alexandria is not ready yet. Please restart the application.'**
  String get failureNotInitialized;

  /// The record does not exist, or has passed the retention window that made it reachable.
  ///
  /// In en, this message translates to:
  /// **'That item no longer exists.'**
  String get failureNotFound;

  /// The record exists but is in the wrong state for the operation.
  ///
  /// In en, this message translates to:
  /// **'That cannot be done to this item right now.'**
  String get failureInvalidState;

  /// A filesystem operation failed. The core leaves the catalog untouched when this happens.
  ///
  /// In en, this message translates to:
  /// **'The file could not be read or written on disk. Nothing was changed.'**
  String get failureDisk;

  /// The on-disk file and the catalog record have diverged.
  ///
  /// In en, this message translates to:
  /// **'The file on disk no longer matches what Alexandria recorded.'**
  String get failureIntegrity;

  /// The core's own configuration is missing or unusable.
  ///
  /// In en, this message translates to:
  /// **'Alexandria\'s configuration could not be read.'**
  String get failureConfiguration;

  /// A status code this version does not recognize. Keeps the mapping total so an unknown code still reads as a message rather than a raw number.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong in Alexandria.'**
  String get failureUnexpected;
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
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
