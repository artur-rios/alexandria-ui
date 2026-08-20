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

  /// Heading of the login screen (UC-02). Presented whenever there is no active session.
  ///
  /// In en, this message translates to:
  /// **'Sign in to Alexandria'**
  String get loginTitle;

  /// Label of the login form's e-mail field.
  ///
  /// In en, this message translates to:
  /// **'E-mail'**
  String get loginEmailLabel;

  /// Label of the login form's password field.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordLabel;

  /// The login form's primary action.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginSubmit;

  /// UC-02 AF-01: the e-mail field was left empty. The core is not called.
  ///
  /// In en, this message translates to:
  /// **'Enter your e-mail address.'**
  String get loginEmailMissing;

  /// UC-02 AF-01: the e-mail field does not hold an address. The core is not called.
  ///
  /// In en, this message translates to:
  /// **'That does not look like an e-mail address.'**
  String get loginEmailMalformed;

  /// UC-02 AF-01: the password field was left empty. The core is not called.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get loginPasswordMissing;

  /// UC-02 AF-02: the core rejected the credentials. Deliberately does not say which of the two was wrong, and does not reveal whether the address is registered.
  ///
  /// In en, this message translates to:
  /// **'That e-mail and password do not match an account.'**
  String get loginRejected;

  /// UC-02 AF-03: the core holds no credentials, so the owner is sent to sign-up (UC-01) by the action beside this message.
  ///
  /// In en, this message translates to:
  /// **'No account has been set up on this computer yet.'**
  String get loginNoAccount;

  /// Heading of the sign-up screen (UC-01). Presented on first launch, when the core holds no account.
  ///
  /// In en, this message translates to:
  /// **'Create your Alexandria account'**
  String get signUpTitle;

  /// UC-01: explains the stakes before the owner chooses. The core owns no mail transport, so there is no reset to fall back on.
  ///
  /// In en, this message translates to:
  /// **'This is the only account. Its password cannot be recovered, so choose one you will not lose.'**
  String get signUpIntro;

  /// Label of the sign-up form's second password field.
  ///
  /// In en, this message translates to:
  /// **'Repeat password'**
  String get signUpPasswordConfirmationLabel;

  /// The sign-up form's primary action.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signUpSubmit;

  /// UC-01 AF-02: the second password field was left empty. The core is not called.
  ///
  /// In en, this message translates to:
  /// **'Repeat your password.'**
  String get signUpPasswordConfirmationMissing;

  /// UC-01 AF-02: the two entries differ. The core is not called.
  ///
  /// In en, this message translates to:
  /// **'The two passwords do not match.'**
  String get signUpPasswordMismatch;

  /// UC-01 AF-03: the core rejected the credentials. The core owns the password policy and does not send its reason across the boundary, so this names the rules it enforces without restating them as front-end validation.
  ///
  /// In en, this message translates to:
  /// **'Alexandria did not accept those credentials. Try a longer, less predictable password that is not your e-mail address.'**
  String get signUpRejected;

  /// UC-01 AF-04: the core already holds an account, so registration is refused and the owner is sent to the login screen.
  ///
  /// In en, this message translates to:
  /// **'An account already exists on this computer. Sign in instead.'**
  String get signUpAccountExists;

  /// UC-01 AF-04: the action that leaves sign-up for the login screen.
  ///
  /// In en, this message translates to:
  /// **'Go to sign in'**
  String get signUpGoToLogin;

  /// UC-02 AF-03: the action that leaves login for the sign-up screen, offered when the core holds no account.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get loginGoToSignUp;

  /// UC-02 AF-04: heading shown on the login screen when a session was discarded because the core rejected a call, rather than because the owner signed out.
  ///
  /// In en, this message translates to:
  /// **'You were signed out'**
  String get loginSessionEndedTitle;

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

  /// The operation would create something that already exists. Nothing the owner typed was wrong.
  ///
  /// In en, this message translates to:
  /// **'That already exists in Alexandria.'**
  String get failureConflict;

  /// The core refused because the caller is asking too often. Nothing the owner typed was wrong; the remedy is to wait.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a moment and try again.'**
  String get failureRateLimited;

  /// The core could not reach a dependency — outbound mail being the one that exists today. The catalog is unaffected.
  ///
  /// In en, this message translates to:
  /// **'Alexandria could not reach a service it needs, so that step did not happen.'**
  String get failureServiceUnavailable;

  /// Core rejection password_too_short. The bound comes from the core, which owns the policy.
  ///
  /// In en, this message translates to:
  /// **'Use at least {min} characters.'**
  String rejectionPasswordTooShort(String min);

  /// Core rejection password_too_long.
  ///
  /// In en, this message translates to:
  /// **'Use at most {max} characters.'**
  String rejectionPasswordTooLong(String max);

  /// Core rejection password_whitespace.
  ///
  /// In en, this message translates to:
  /// **'A password cannot be only spaces.'**
  String get rejectionPasswordWhitespace;

  /// Core rejection password_repeated_character.
  ///
  /// In en, this message translates to:
  /// **'A password cannot be one character repeated.'**
  String get rejectionPasswordRepeatedCharacter;

  /// Core rejection password_too_common.
  ///
  /// In en, this message translates to:
  /// **'That password is too common. Choose something less predictable.'**
  String get rejectionPasswordTooCommon;

  /// Core rejection password_contains_email, which covers both being the address and containing it.
  ///
  /// In en, this message translates to:
  /// **'A password cannot contain your e-mail address.'**
  String get rejectionPasswordContainsEmail;

  /// Core rejection email_untrimmed.
  ///
  /// In en, this message translates to:
  /// **'Remove the spaces around your e-mail address.'**
  String get rejectionEmailUntrimmed;

  /// A status code this version does not recognize. Keeps the mapping total so an unknown code still reads as a message rather than a raw number.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong in Alexandria.'**
  String get failureUnexpected;

  /// The declining action on every confirmation modal (UC-38 AF-05). Cancelling changes nothing.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Accessible label of the loading state every perceptible operation shows (FR-UX-08).
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// Accessible label of the persistent playback bar (FR-UX-01).
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get playbackBarLabel;

  /// The playback bar's idle state (FR-UX-01). The bar is present from the first frame, so it says what it is showing rather than sitting blank.
  ///
  /// In en, this message translates to:
  /// **'Nothing is playing'**
  String get playbackNothingPlaying;

  /// Navigation panel entry for the dashboard the application opens on (UC-14).
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get destinationHome;

  /// Navigation panel entry for audio files (FR-CT-01).
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get destinationMusic;

  /// Navigation panel entry for books and e-books (FR-CT-01).
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get destinationBooks;

  /// Navigation panel entry for comic book archives (FR-CT-01).
  ///
  /// In en, this message translates to:
  /// **'Comic books'**
  String get destinationComicBooks;

  /// Navigation panel entry for notes, Markdown, and plain text files (FR-CT-01).
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get destinationNotes;

  /// Navigation panel entry for saved HTML pages (FR-CT-01).
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get destinationPages;

  /// Navigation panel entry for still images (FR-CT-01).
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get destinationImages;

  /// Navigation panel entry for saved links, the one type holding no file on disk (FR-CT-01).
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get destinationBookmarks;

  /// Title of the preferences dialog (UC-39). Reachable with or without a session.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferencesTitle;

  /// Accessible label and tooltip of the control that opens the preferences dialog.
  ///
  /// In en, this message translates to:
  /// **'Open preferences'**
  String get preferencesOpen;

  /// Heading of the theme group in preferences (FR-UX-04).
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get preferencesThemeLabel;

  /// Theme option: follow the operating system's light or dark setting, and follow it when it changes (UC-39 AF-01).
  ///
  /// In en, this message translates to:
  /// **'Match the system'**
  String get preferencesThemeSystem;

  /// Theme option: always the light theme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get preferencesThemeLight;

  /// Theme option: always the dark theme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get preferencesThemeDark;

  /// Heading of the language group in preferences (FR-UX-05).
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get preferencesLanguageLabel;

  /// Language option: follow the operating system's language when it is one of the two supported, and English otherwise (UC-39 AF-03).
  ///
  /// In en, this message translates to:
  /// **'Match the system'**
  String get preferencesLanguageSystem;

  /// UC-39 AF-02: the settings store could not be written. The choice still applies for this session; what must not happen is the owner believing it was remembered.
  ///
  /// In en, this message translates to:
  /// **'Your choice is applied, but it could not be saved — it will not be remembered the next time Alexandria starts.'**
  String get preferencesUnsaved;

  /// The action that closes the preferences dialog. Nothing is applied on closing — every choice already took effect when it was made.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get preferencesClose;

  /// The action in preferences that opens the credential-change form (UC-04 main flow step 1). Offered only while a session is active.
  ///
  /// In en, this message translates to:
  /// **'Change your e-mail and password'**
  String get changeCredentialsOpen;

  /// Title of the credential-change dialog (UC-04).
  ///
  /// In en, this message translates to:
  /// **'Change credentials'**
  String get changeCredentialsTitle;

  /// Explains that the e-mail and password change as one, and that the session survives the change (UC-04 postconditions).
  ///
  /// In en, this message translates to:
  /// **'Both are replaced together. You stay signed in.'**
  String get changeCredentialsIntro;

  /// Label of the new e-mail field.
  ///
  /// In en, this message translates to:
  /// **'New e-mail'**
  String get changeCredentialsEmailLabel;

  /// Label of the new password field.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get changeCredentialsPasswordLabel;

  /// Label of the repeated-password field (FR-AU-10 requires it entered twice).
  ///
  /// In en, this message translates to:
  /// **'Repeat the new password'**
  String get changeCredentialsConfirmationLabel;

  /// The form's primary action.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeCredentialsSubmit;

  /// UC-04 main flow step 6: the core stored the new hash and the change is confirmed.
  ///
  /// In en, this message translates to:
  /// **'Your e-mail and password have been changed.'**
  String get changeCredentialsDone;

  /// UC-04 AF-03: the core refused the new credentials. Shown when the core names no more specific reason; the stored credentials are untouched.
  ///
  /// In en, this message translates to:
  /// **'The change was refused, and your e-mail and password are unchanged.'**
  String get changeCredentialsRejected;

  /// The action in preferences that opens the library-folders screen (UC-05).
  ///
  /// In en, this message translates to:
  /// **'Library folders'**
  String get librarySourcesOpen;

  /// Title of the library-folders screen (UC-05).
  ///
  /// In en, this message translates to:
  /// **'Library folders'**
  String get librarySourcesTitle;

  /// Heading of the first-run guidance shown whenever no folder is registered (FR-LB-11, UC-05 main flow step 1).
  ///
  /// In en, this message translates to:
  /// **'No library folders yet'**
  String get librarySourcesEmptyTitle;

  /// Body of the first-run guidance. Says plainly that registering a folder does not touch its contents (BR-06).
  ///
  /// In en, this message translates to:
  /// **'Add a folder from your disk and Alexandria will catalog what is inside it. Nothing is moved, copied, or changed.'**
  String get librarySourcesEmptyBody;

  /// The action that opens the platform's native folder picker (FR-LB-01).
  ///
  /// In en, this message translates to:
  /// **'Add a folder'**
  String get librarySourcesAdd;

  /// UC-05 AF-02: the chosen path does not exist.
  ///
  /// In en, this message translates to:
  /// **'There is no folder at {path}. Nothing was added.'**
  String librarySourcesMissing(String path);

  /// UC-05 AF-02: the folder exists but its contents cannot be listed.
  ///
  /// In en, this message translates to:
  /// **'The folder at {path} cannot be read. Nothing was added.'**
  String librarySourcesUnreadable(String path);

  /// UC-05 AF-03: the chosen folder is already registered. The existing entry is highlighted in the list.
  ///
  /// In en, this message translates to:
  /// **'That folder is already in your library.'**
  String get librarySourcesAlreadyRegistered;

  /// Title of the confirmation shown when the chosen folder contains, or sits inside, one already registered (UC-05 AF-04).
  ///
  /// In en, this message translates to:
  /// **'These folders overlap'**
  String get librarySourcesOverlapTitle;

  /// Body of the overlap confirmation. Names both folders and states the consequence the owner is agreeing to (UC-05 AF-04).
  ///
  /// In en, this message translates to:
  /// **'{path} overlaps {existing}, which is already in your library. Files inside both will be cataloged once for each folder.'**
  String librarySourcesOverlapBody(String path, String existing);

  /// The confirming action on the overlap warning (UC-05 AF-04).
  ///
  /// In en, this message translates to:
  /// **'Add it anyway'**
  String get librarySourcesOverlapConfirm;

  /// Dismisses an inline notice the owner has read. Distinct from closing a screen or cancelling an action.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// The action that starts a scan of a registered folder (UC-06 main flow step 1).
  ///
  /// In en, this message translates to:
  /// **'Index'**
  String get librarySourcesIndex;

  /// Shown while a run is in flight. The scan belongs to the core, so the rest of the application stays usable (FR-LB-07).
  ///
  /// In en, this message translates to:
  /// **'Scanning…'**
  String get librarySourcesIndexing;

  /// UC-06 main flow step 5: a finished run's tally. These are the core's own counts for an index run.
  ///
  /// In en, this message translates to:
  /// **'Scanned {scanned} files, cataloged {indexed}, skipped {skipped}.'**
  String librarySourcesRunComplete(int scanned, int indexed, int skipped);

  /// Appended to a run's outcome when the core reports files it failed on.
  ///
  /// In en, this message translates to:
  /// **'{failed} files could not be read.'**
  String librarySourcesRunFailedCount(int failed);

  /// UC-06: the core reports the run as failed.
  ///
  /// In en, this message translates to:
  /// **'The scan did not finish.'**
  String get librarySourcesRunFailed;

  /// UC-06 AF-05: the run was interrupted. Its outcome is read at the next launch rather than lost.
  ///
  /// In en, this message translates to:
  /// **'The scan did not finish, because Alexandria was closed while it was running.'**
  String get librarySourcesRunInterrupted;

  /// UC-06 AF-01: a second run is refused while one is in flight (FR-LB-09).
  ///
  /// In en, this message translates to:
  /// **'A scan of this folder is already running.'**
  String get librarySourcesRunRefused;

  /// UC-06 AF-02 and AF-03: the core refused to start the run. The reason from the core follows.
  ///
  /// In en, this message translates to:
  /// **'This folder could not be scanned.'**
  String get librarySourcesStartFailed;

  /// The action that unregisters a library folder (UC-08 main flow step 1).
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get librarySourcesUnregister;

  /// Title of the unregister confirmation (UC-08 main flow step 2).
  ///
  /// In en, this message translates to:
  /// **'Remove {label} from your library folders?'**
  String librarySourcesUnregisterTitle(String label);

  /// Body of the unregister confirmation. FR-LB-10 requires it state that catalog records and on-disk files are left untouched (BR-12).
  ///
  /// In en, this message translates to:
  /// **'Alexandria will stop scanning this folder. Everything already cataloged from it stays in your library, and nothing on disk is touched.'**
  String get librarySourcesUnregisterBody;

  /// The confirming action on the unregister confirmation.
  ///
  /// In en, this message translates to:
  /// **'Remove the folder'**
  String get librarySourcesUnregisterConfirm;

  /// UC-08 AF-02: a folder with a run in flight is refused until the run settles.
  ///
  /// In en, this message translates to:
  /// **'This folder is being scanned. It can be removed once the scan finishes.'**
  String get librarySourcesUnregisterRefused;

  /// The action that re-checks everything already cataloged, across every folder at once (UC-07 main flow step 1, FR-LB-06).
  ///
  /// In en, this message translates to:
  /// **'Refresh the catalog'**
  String get librarySourcesRefresh;

  /// Shown while a refresh is in flight (UC-07 main flow step 3).
  ///
  /// In en, this message translates to:
  /// **'Re-checking the catalog…'**
  String get librarySourcesRefreshing;

  /// UC-07 main flow step 4: a finished refresh's tally, in the core's own counts for a refresh run.
  ///
  /// In en, this message translates to:
  /// **'{refreshed} files updated, {unchanged} unchanged, {missing} now missing.'**
  String librarySourcesRefreshComplete(
    int refreshed,
    int unchanged,
    int missing,
  );

  /// UC-07 AF-01: a second refresh is refused while one is in flight.
  ///
  /// In en, this message translates to:
  /// **'The catalog is already being re-checked.'**
  String get librarySourcesRefreshRunning;

  /// UC-07 AF-02: the catalog is empty, so registering and indexing a folder is offered instead of a refresh (UC-05, UC-06).
  ///
  /// In en, this message translates to:
  /// **'There is nothing cataloged yet. Add a folder and index it first.'**
  String get librarySourcesRefreshEmpty;

  /// UC-07: the core refused to start the refresh.
  ///
  /// In en, this message translates to:
  /// **'The catalog could not be re-checked.'**
  String get librarySourcesRefreshFailed;

  /// UC-07 AF-03: the outcome reports how many files are now missing; the link to the missing-files review is UC-37, which is not built yet.
  ///
  /// In en, this message translates to:
  /// **'Reviewing missing files arrives with its own use case.'**
  String get librarySourcesMissingReviewPending;

  /// Navigation panel entry for video of every kind. One entry rather than separate movies and series, because the core classifies a file as `video` and carries no subtype — the distinction lives in watchlists (UC-29), not in the catalog.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get destinationVideos;

  /// UC-09 AF-01: the selected type has no items, but the catalog has others. Distinct from the loading and error states.
  ///
  /// In en, this message translates to:
  /// **'Nothing of this type yet'**
  String get catalogEmptyTitle;

  /// UC-09 AF-01: the whole catalog is empty, so registering and indexing a folder is what the owner needs (UC-05, UC-06).
  ///
  /// In en, this message translates to:
  /// **'Your library is empty. Add a folder and index it, and what is inside will appear here.'**
  String get catalogEmptyFirstRun;

  /// The action on the empty state that opens the library-folders screen (UC-05).
  ///
  /// In en, this message translates to:
  /// **'Library folders'**
  String get catalogEmptyAddFolder;

  /// Marks a file the last refresh could not find on disk. The record is still active; reviewing them is UC-37.
  ///
  /// In en, this message translates to:
  /// **'Missing from disk'**
  String get catalogFileMissing;

  /// The item count beside a type in the navigation panel (FR-CT-01).
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String catalogCount(int count);

  /// The plain list layout (FR-CT-03).
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get layoutList;

  /// The list layout with each file's details alongside (FR-CT-03).
  ///
  /// In en, this message translates to:
  /// **'List with details'**
  String get layoutDetailedList;

  /// The grid-of-tiles layout (FR-CT-03).
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get layoutGrid;

  /// Accessible label of the control that switches between the three layouts.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get layoutLabel;

  /// UC-10 AF-01: the chosen layout does not fit, so the closest one that does is drawn and the substitution is stated rather than columns being clipped.
  ///
  /// In en, this message translates to:
  /// **'The window is too narrow for that layout, so the list is shown instead.'**
  String get layoutSubstituted;

  /// UC-10 AF-02: the settings store could not be written. The layout still applies for this session.
  ///
  /// In en, this message translates to:
  /// **'The layout changed, but the choice could not be saved — it will not be remembered next time.'**
  String get layoutUnsaved;

  /// Label of the catalog-wide search field (UC-11 main flow step 1).
  ///
  /// In en, this message translates to:
  /// **'Search the library'**
  String get searchLabel;

  /// Accessible label of the control that clears the search and restores the previous listing (UC-11 AF-02).
  ///
  /// In en, this message translates to:
  /// **'Clear the search'**
  String get searchClear;

  /// UC-11 AF-01: no file matched. Names the term so the owner can see what was searched for. Distinct from loading and from error (FR-CT-09).
  ///
  /// In en, this message translates to:
  /// **'Nothing matches “{term}”.'**
  String searchNoResults(String term);

  /// UC-11 AF-03: at least one type could not be listed, so the results are a partial answer rather than the whole one.
  ///
  /// In en, this message translates to:
  /// **'Some of the library could not be read, so more results may exist.'**
  String get searchPartial;

  /// Heading above the grouped search results.
  ///
  /// In en, this message translates to:
  /// **'Results for “{term}”'**
  String searchResultsFor(String term);

  /// Accessible label of the control that opens the filter and sort choices (UC-12).
  ///
  /// In en, this message translates to:
  /// **'Filters and order'**
  String get filtersLabel;

  /// Heading of the lifecycle filter (FR-CT-07).
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get filterLifecycle;

  /// Lifecycle filter: only records the core calls active. What a listing opens on.
  ///
  /// In en, this message translates to:
  /// **'In the library'**
  String get filterLifecycleActive;

  /// Lifecycle filter: only soft-deleted records.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get filterLifecycleDeleted;

  /// Lifecycle filter: active and deleted records together.
  ///
  /// In en, this message translates to:
  /// **'Everything'**
  String get filterLifecycleAll;

  /// Heading of the sort choices (FR-CT-08).
  ///
  /// In en, this message translates to:
  /// **'Order by'**
  String get sortLabel;

  /// Sort the listing by file name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sortByName;

  /// Sort the listing by when the core last indexed the file.
  ///
  /// In en, this message translates to:
  /// **'Date added'**
  String get sortByIndexed;

  /// Sort direction: A to Z, oldest first.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get sortAscending;

  /// Sort direction: Z to A, newest first.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get sortDescending;

  /// The action that restores the unfiltered listing (UC-12 AF-02). The sort is left alone, because ordering hides nothing.
  ///
  /// In en, this message translates to:
  /// **'Clear the filters'**
  String get filtersClear;

  /// UC-12 AF-01: the filter combination matched nothing. Offers to clear them.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches the filters you have set.'**
  String get filtersEmpty;

  /// UC-12 AF-04: the core rejected the filter as invalid input, and the previous filters were restored.
  ///
  /// In en, this message translates to:
  /// **'That filter was refused, so the previous one is back.'**
  String get filtersRejected;

  /// Title of the file detail view (UC-13, FR-CT-05).
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsTitle;

  /// Heading above the file's on-disk path.
  ///
  /// In en, this message translates to:
  /// **'Where it is'**
  String get detailsPath;

  /// Heading above the file's type-specific metadata.
  ///
  /// In en, this message translates to:
  /// **'About it'**
  String get detailsMetadata;

  /// Heading above the file's lifecycle state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get detailsState;

  /// The file's record is active.
  ///
  /// In en, this message translates to:
  /// **'In the library'**
  String get detailsStateActive;

  /// UC-13 AF-02: the record is soft-deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get detailsStateDeleted;

  /// UC-13 AF-03: the record is active but the file was not where the catalog says it is.
  ///
  /// In en, this message translates to:
  /// **'Missing from disk'**
  String get detailsStateMissing;

  /// The action that hands the file to its viewer or player (FR-CT-12).
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get detailsOpen;

  /// UC-13 AF-04: no viewer is registered for the type. The other actions stay available.
  ///
  /// In en, this message translates to:
  /// **'Nothing can open this kind of file yet.'**
  String get detailsNoViewer;

  /// UC-13 AF-03: what a missing file means, and the re-scan offered for it (UC-07).
  ///
  /// In en, this message translates to:
  /// **'Alexandria could not find this file where the catalog says it is. Re-check the catalog to find out whether it has come back.'**
  String get detailsMissingHint;

  /// The action AF-03 offers, which is UC-07's refresh.
  ///
  /// In en, this message translates to:
  /// **'Re-check the catalog'**
  String get detailsRescan;

  /// UC-13 AF-02: the record is shown as deleted; restoring it is UC-34, which is not built yet.
  ///
  /// In en, this message translates to:
  /// **'This record is deleted. Restoring it arrives with its own use case.'**
  String get detailsDeletedHint;

  /// UC-13 AF-01: the core reports the file as not found, so the listing is refreshed and the owner returns to it.
  ///
  /// In en, this message translates to:
  /// **'That file is no longer in the catalog.'**
  String get detailsNotFound;

  /// Shown when the core answers no type-specific metadata — text and HTML files have none, and a file whose metadata has not been written yet has none either.
  ///
  /// In en, this message translates to:
  /// **'The core reports nothing else about this file.'**
  String get detailsMetadataNone;

  /// Label of an image's extracted pixel width.
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get detailsWidth;

  /// Label of an image's extracted pixel height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get detailsHeight;

  /// Label of a document's or comic's extracted page count.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get detailsPages;

  /// Label of a video's extracted duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get detailsDuration;

  /// Heading of the dashboard's recently added section (UC-14, FR-CT-11).
  ///
  /// In en, this message translates to:
  /// **'Recently added'**
  String get dashboardRecent;

  /// The recently added section has nothing to show.
  ///
  /// In en, this message translates to:
  /// **'Nothing has been added yet.'**
  String get dashboardRecentNone;

  /// Heading of the dashboard's in-progress section (UC-14, FR-CT-11).
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get dashboardInProgress;

  /// UC-14 AF-02: the section states that nothing is in progress rather than rendering empty. Watchlists and reading lists are M-09, so this is always the state today.
  ///
  /// In en, this message translates to:
  /// **'Nothing is in progress. Watchlists and reading lists arrive with their own use cases.'**
  String get dashboardInProgressNone;

  /// Heading of the dashboard's per-type counts (UC-14, FR-CT-11).
  ///
  /// In en, this message translates to:
  /// **'What is in the library'**
  String get dashboardCounts;

  /// Heading of the dashboard's most-recent-run section (UC-14, FR-CT-11).
  ///
  /// In en, this message translates to:
  /// **'The last scan'**
  String get dashboardLastRun;

  /// No index or refresh run has been observed since the application started.
  ///
  /// In en, this message translates to:
  /// **'Nothing has been scanned in this session.'**
  String get dashboardLastRunNone;

  /// UC-14 AF-04: a run is in flight, and the dashboard updates when it settles.
  ///
  /// In en, this message translates to:
  /// **'A scan is running now.'**
  String get dashboardLastRunRunning;

  /// The most recent run completed.
  ///
  /// In en, this message translates to:
  /// **'The last scan finished.'**
  String get dashboardLastRunComplete;

  /// The most recent run failed.
  ///
  /// In en, this message translates to:
  /// **'The last scan did not finish.'**
  String get dashboardLastRunFailed;

  /// The most recent run was interrupted rather than failing.
  ///
  /// In en, this message translates to:
  /// **'The last scan was interrupted when Alexandria closed.'**
  String get dashboardLastRunInterrupted;

  /// Opens the music metadata form from an audio file's detail view (UC-15 main flow step 1).
  ///
  /// In en, this message translates to:
  /// **'Edit metadata'**
  String get detailsEditMetadata;

  /// Title of the music metadata form (UC-15, FR-ME-01).
  ///
  /// In en, this message translates to:
  /// **'Music metadata'**
  String get musicMetadataTitle;

  /// Label of the track title field.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get musicMetadataFieldTitle;

  /// Label of the artist field.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get musicMetadataFieldArtist;

  /// Label of the album field.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get musicMetadataFieldAlbum;

  /// Label of the release year field.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get musicMetadataFieldYear;

  /// Label of the genre field.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get musicMetadataFieldGenre;

  /// Label of the track number field.
  ///
  /// In en, this message translates to:
  /// **'Track number'**
  String get musicMetadataFieldTrack;

  /// Sends the edited metadata to the core (UC-15 main flow step 5).
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get musicMetadataSave;

  /// Closes the metadata form without saving.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get musicMetadataCancel;

  /// UC-15 AF-01: a numeric field holds something that is not a number, so the core is not called.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number.'**
  String get musicMetadataErrorNotANumber;

  /// UC-15 AF-01: the year is earlier than any recording could carry, which is a typo rather than a year.
  ///
  /// In en, this message translates to:
  /// **'Enter a four-digit year.'**
  String get musicMetadataErrorYear;

  /// UC-15 AF-01: the track number is zero or negative.
  ///
  /// In en, this message translates to:
  /// **'A track number starts at 1.'**
  String get musicMetadataErrorTrack;

  /// UC-15 AF-01: a text field is longer than the core stores.
  ///
  /// In en, this message translates to:
  /// **'Keep this under {max} characters.'**
  String musicMetadataErrorTooLong(int max);

  /// UC-03 main flow step 1: ends the session without closing the application.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// UC-03 AF-01: the heading of the warning shown when an editor is holding changes that were never saved.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get signOutUnsavedTitle;

  /// UC-03 AF-01: names what signing out would lose, and says that cancelling is how to save it.
  ///
  /// In en, this message translates to:
  /// **'Signing out now discards the changes you have not saved. Cancel to go back and save them first.'**
  String get signOutUnsavedMessage;

  /// UC-03 AF-01: confirms the sign-out, unsaved changes and all.
  ///
  /// In en, this message translates to:
  /// **'Sign out and discard'**
  String get signOutUnsavedConfirm;

  /// UC-03 AF-02: the scan belongs to the core, so signing out neither stopped it nor lost its outcome.
  ///
  /// In en, this message translates to:
  /// **'You signed out while a scan was still running. It continues in the core, and how it ended is shown the next time you sign in.'**
  String get signOutIndexRunContinues;

  /// UC-16 main flow step 2: the heading of the video metadata form.
  ///
  /// In en, this message translates to:
  /// **'Edit video metadata'**
  String get videoMetadataTitle;

  /// UC-16: the video's title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get videoMetadataFieldTitle;

  /// UC-16: the year the video was released.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get videoMetadataFieldYear;

  /// UC-16: the video's resolution, as the core recorded or the owner corrects it.
  ///
  /// In en, this message translates to:
  /// **'Resolution'**
  String get videoMetadataFieldResolution;

  /// UC-16 / FR-ME-02: whether the video is a movie or a series.
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get videoMetadataFieldMediaKind;

  /// UC-16: the video is a standalone film, tracked as a single item.
  ///
  /// In en, this message translates to:
  /// **'Movie'**
  String get videoMetadataMovie;

  /// UC-16: the video belongs to a series, tracked per episode.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get videoMetadataSeries;

  /// UC-16 main flow step 4: sends the edited metadata to the core.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get videoMetadataSave;

  /// Closes the video metadata form without saving.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get videoMetadataCancel;

  /// UC-16 AF-03: what changing the marking from series to movie costs, asked before the core is called.
  ///
  /// In en, this message translates to:
  /// **'This video is tracked per episode. Marking it as a movie replaces that with progress for the item as a whole.'**
  String get videoMetadataMarkingWarning;

  /// UC-16 AF-03: confirms the marking change and sends it.
  ///
  /// In en, this message translates to:
  /// **'Mark as a movie'**
  String get videoMetadataMarkingConfirm;

  /// UC-16 AF-01: the year holds something that is not a number, so the core is not called.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number.'**
  String get videoMetadataErrorNotANumber;

  /// UC-16 AF-01: the year is earlier than any film could carry, which is a typo rather than a year.
  ///
  /// In en, this message translates to:
  /// **'Enter a four-digit year.'**
  String get videoMetadataErrorYear;

  /// UC-16 AF-01: a text field is longer than the core stores.
  ///
  /// In en, this message translates to:
  /// **'Keep this under {max} characters.'**
  String videoMetadataErrorTooLong(int max);

  /// UC-16 AF-03: declines the marking change, which is what keeps the per-episode progress. Named rather than "Cancel", because the form's own cancel sits beside it and means something else.
  ///
  /// In en, this message translates to:
  /// **'Keep it as a series'**
  String get videoMetadataMarkingCancel;

  /// UC-17 main flow step 1: opens the rename dialog from a file's detail view.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renameOpen;

  /// UC-17: the heading of the rename dialog.
  ///
  /// In en, this message translates to:
  /// **'Rename file'**
  String get renameTitle;

  /// UC-17: the field holding the new name, on disk and in the catalog.
  ///
  /// In en, this message translates to:
  /// **'File name'**
  String get renameFieldLabel;

  /// UC-17 main flow step 3: sends the new name to the core.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renameSubmit;

  /// UC-17 AF-02: what the core guarantees when the rename failed on disk.
  ///
  /// In en, this message translates to:
  /// **'Neither the catalog nor the file on disk was changed.'**
  String get renameNothingChanged;

  /// UC-17 AF-01: the name is empty, so the core is not called.
  ///
  /// In en, this message translates to:
  /// **'Enter a file name.'**
  String get renameErrorEmpty;

  /// UC-17 AF-01: the name holds a character the host operating system forbids.
  ///
  /// In en, this message translates to:
  /// **'This name uses a character the file system does not allow.'**
  String get renameErrorForbidden;

  /// UC-17 AF-01: Windows reserves a handful of device names, whatever extension follows them.
  ///
  /// In en, this message translates to:
  /// **'This name is reserved by the operating system.'**
  String get renameErrorReserved;

  /// UC-17 AF-01: Windows strips a trailing dot silently, which would leave the catalog and the disk disagreeing.
  ///
  /// In en, this message translates to:
  /// **'A file name cannot end in a dot.'**
  String get renameErrorTrailingDot;

  /// UC-17 AF-01: the name is longer than a single path component may be.
  ///
  /// In en, this message translates to:
  /// **'Keep the name under {max} characters.'**
  String renameErrorTooLong(int max);

  /// UC-18 main flow step 1: opens the text or Markdown editor from a file's detail view.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editorOpen;

  /// UC-18: leaves the editor, asking first when there are unsaved changes.
  ///
  /// In en, this message translates to:
  /// **'Close the editor'**
  String get editorClose;

  /// UC-18 main flow step 5: writes the edited content back through the core.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get editorSave;

  /// UC-18 / FR-ME-09: the content on screen is not what is on disk.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get editorUnsaved;

  /// UC-18: acknowledges a message and leaves the content alone.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get editorDismiss;

  /// UC-18 AF-02: leaves the editor without saving.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get editorDiscard;

  /// UC-18 AF-05: replaces what is on screen with what the file now holds.
  ///
  /// In en, this message translates to:
  /// **'Reload from disk'**
  String get editorReload;

  /// UC-18 AF-05: writes over the version that changed on disk.
  ///
  /// In en, this message translates to:
  /// **'Save anyway'**
  String get editorOverwrite;

  /// UC-18 AF-06: acknowledges that the session ended and the content could not be saved.
  ///
  /// In en, this message translates to:
  /// **'Sign in again'**
  String get editorSignInAgain;

  /// UC-18 AF-01: the editor holds exactly what was read, so the core was not called.
  ///
  /// In en, this message translates to:
  /// **'The content has not changed, so nothing was written.'**
  String get editorNothingToSave;

  /// UC-18 AF-02 / FR-ME-09: the warning before unsaved changes are discarded.
  ///
  /// In en, this message translates to:
  /// **'You have changes that are not saved. Save them, discard them, or stay in the editor.'**
  String get editorLeaveUnsaved;

  /// UC-18 AF-05: something else wrote the file between the read and the save.
  ///
  /// In en, this message translates to:
  /// **'This file changed on disk since you opened it. Reload to see the new version, or save anyway to replace it.'**
  String get editorChangedOnDisk;

  /// UC-18 AF-04: the record went while the editor was open, and nothing typed is discarded silently.
  ///
  /// In en, this message translates to:
  /// **'This file is no longer in the catalog. What you have written is still here, and is not saved.'**
  String get editorRecordGone;

  /// UC-18 AF-06: the core rejected the write, and the owner is warned before the session goes.
  ///
  /// In en, this message translates to:
  /// **'Your session ended, so this could not be saved. Signing in again will lose what is on screen.'**
  String get editorSessionRejected;

  /// UC-18: the content never loaded, so there is nothing to edit.
  ///
  /// In en, this message translates to:
  /// **'This file could not be read.'**
  String get editorCouldNotRead;

  /// UC-18 AF-02: writes the unsaved changes and then leaves the editor. Named apart from the editor's own save, which stays where it is.
  ///
  /// In en, this message translates to:
  /// **'Save and close'**
  String get editorSaveAndClose;

  /// UC-19 main flow step 1: opens the video player, and resumes it while playing.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get videoPlay;

  /// UC-19 main flow step 4 / FR-PL-02: pauses playback where it is.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get videoPause;

  /// UC-19 main flow step 7: stops playback and records where it stopped.
  ///
  /// In en, this message translates to:
  /// **'Close the player'**
  String get videoClose;

  /// UC-19 / FR-PL-02: seeks backward.
  ///
  /// In en, this message translates to:
  /// **'Back ten seconds'**
  String get videoSeekBackward;

  /// UC-19 / FR-PL-02: seeks forward.
  ///
  /// In en, this message translates to:
  /// **'Forward ten seconds'**
  String get videoSeekForward;

  /// UC-19 / FR-PL-02: fills the window with the video, or stops doing so.
  ///
  /// In en, this message translates to:
  /// **'Full screen'**
  String get videoFullScreen;

  /// UC-19 main flow step 5 / FR-PL-03: the subtitle tracks the file provides.
  ///
  /// In en, this message translates to:
  /// **'Subtitles'**
  String get videoSubtitles;

  /// UC-19 / FR-PL-03: turns subtitles off, which the requirement names as one of the choices.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get videoSubtitlesOff;

  /// UC-19 AF-03: the control says none is available rather than being silently absent.
  ///
  /// In en, this message translates to:
  /// **'This file carries no subtitles'**
  String get videoNoSubtitles;

  /// UC-19 main flow step 6 / FR-PL-04: the audio tracks the file provides.
  ///
  /// In en, this message translates to:
  /// **'Audio tracks'**
  String get videoAudioTracks;

  /// UC-19 AF-03: there is no alternative to choose, and the control says so.
  ///
  /// In en, this message translates to:
  /// **'This file carries one audio track'**
  String get videoNoAudioTracks;

  /// UC-19 AF-04: plays from where it stopped last time.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get videoResume;

  /// UC-19 AF-04: plays from the beginning, forgetting the resume point.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get videoStartOver;

  /// UC-19 AF-01: the record is there and the file on disk is not.
  ///
  /// In en, this message translates to:
  /// **'This file is not where the catalog says it is.'**
  String get videoFileMissing;

  /// UC-19 AF-02 / FR-PL-10: the engine could not decode the format, and the application carries on.
  ///
  /// In en, this message translates to:
  /// **'This file cannot be played.'**
  String get videoCannotDecode;

  /// UC-19 AF-04: the resume point, offered before anything is opened.
  ///
  /// In en, this message translates to:
  /// **'You stopped watching at {position}.'**
  String videoResumePrompt(String position);

  /// UC-19 / FR-PL-03, FR-PL-04: a track the file names neither by title nor by language.
  ///
  /// In en, this message translates to:
  /// **'Track {id}'**
  String videoTrackUnnamed(String id);

  /// UC-20 main flow step 1: plays this track on its own.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get audioPlay;

  /// UC-20 main flow steps 1 and 3: queues the album this track belongs to.
  ///
  /// In en, this message translates to:
  /// **'Play album'**
  String get audioPlayAlbum;

  /// UC-20 main flow steps 1 and 3: queues everything by this track's artist.
  ///
  /// In en, this message translates to:
  /// **'Play artist'**
  String get audioPlayArtist;

  /// UC-20 main flow step 6: pauses playback where it is.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get audioPause;

  /// UC-20 main flow step 6 / FR-PL-06: skips forward within the queue.
  ///
  /// In en, this message translates to:
  /// **'Next track'**
  String get audioNext;

  /// UC-20 main flow step 6 / FR-PL-06: skips back within the queue.
  ///
  /// In en, this message translates to:
  /// **'Previous track'**
  String get audioPrevious;

  /// UC-20 main flow step 7: stops playback and clears the queue.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get audioStop;

  /// UC-20 AF-03: every queued file failed, so the queue was cleared.
  ///
  /// In en, this message translates to:
  /// **'Nothing in this selection could be played.'**
  String get audioNothingPlayable;

  /// UC-20 AF-01 and AF-02: which file was skipped, named rather than counted, while the queue carries on.
  ///
  /// In en, this message translates to:
  /// **'Skipped {name} — it could not be played.'**
  String audioSkipped(String name);

  /// UC-20 AF-04: the resume point for a single track, offered before it starts.
  ///
  /// In en, this message translates to:
  /// **'You stopped this track at {position}.'**
  String audioResumePrompt(String position);

  /// UC-21: the full player's heading when nothing names an album or an artist.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get audioPlayer;

  /// UC-21 main flow step 2: opens the full player, where the album's medium is shown.
  ///
  /// In en, this message translates to:
  /// **'Open the player'**
  String get audioOpenPlayer;

  /// UC-21 / FR-PL-07: what the animation is, for a screen reader.
  ///
  /// In en, this message translates to:
  /// **'A record turning on a turntable'**
  String get albumMediumVinyl;

  /// UC-21 / FR-PL-07: what the animation is, for a screen reader.
  ///
  /// In en, this message translates to:
  /// **'A cassette turning in a tape deck'**
  String get albumMediumTape;

  /// UC-21 / FR-PL-07: what the animation is, for a screen reader.
  ///
  /// In en, this message translates to:
  /// **'A disc turning in a player'**
  String get albumMediumDisc;

  /// UC-22 main flow step 1: opens the viewer registered for this file's type.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get viewerOpen;

  /// UC-22 main flow step 6: leaves the viewer, retaining nothing.
  ///
  /// In en, this message translates to:
  /// **'Close the viewer'**
  String get viewerClose;

  /// UC-22 main flow step 5: moves on through an e-book.
  ///
  /// In en, this message translates to:
  /// **'Next chapter'**
  String get viewerNext;

  /// UC-22 main flow step 5: moves back through an e-book.
  ///
  /// In en, this message translates to:
  /// **'Previous chapter'**
  String get viewerPrevious;

  /// UC-22 AF-01: the record is there and the file on disk is not.
  ///
  /// In en, this message translates to:
  /// **'This file is not where the catalog says it is.'**
  String get viewerFileMissing;

  /// UC-22 AF-02: the bytes are not what the extension says they are.
  ///
  /// In en, this message translates to:
  /// **'This file could not be read. It may be damaged, or not the format its name claims.'**
  String get viewerUnreadable;

  /// UC-22 AF-03: an encrypted document, reported rather than prompted for.
  ///
  /// In en, this message translates to:
  /// **'This document is protected by a password, which this application does not ask for or store.'**
  String get viewerEncrypted;

  /// UC-22 AF-04 / FR-VW-08: no viewer is registered for the type.
  ///
  /// In en, this message translates to:
  /// **'There is no viewer for this kind of file yet. Its other actions are still available.'**
  String get viewerNone;

  /// UC-23 AF-03: the archive format has no bundled decoder; the file is named so the owner knows which one.
  ///
  /// In en, this message translates to:
  /// **'{name} is in a format no bundled decoder can open.'**
  String viewerUnsupportedFormat(String name);

  /// UC-22: where the owner is in an e-book.
  ///
  /// In en, this message translates to:
  /// **'Chapter {position} of {total}'**
  String viewerChapterOf(int position, int total);

  /// UC-23 main flow step 3 / FR-VW-03: the whole page, as large as it goes.
  ///
  /// In en, this message translates to:
  /// **'Fit the page'**
  String get comicFitPage;

  /// UC-23 main flow step 3 / FR-VW-03: the page's width, so the lettering is legible and the owner scrolls.
  ///
  /// In en, this message translates to:
  /// **'Fit the width'**
  String get comicFitWidth;

  /// UC-23 main flow step 3: turns the page.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get comicNextPage;

  /// UC-23 main flow step 3: turns back.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get comicPreviousPage;

  /// UC-23: where the owner is in the archive.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {total}'**
  String comicPageOf(int page, int total);

  /// UC-23 AF-04: the gaps are marked rather than silently jumped, and named so the owner knows what is wrong with their file.
  ///
  /// In en, this message translates to:
  /// **'These pages could not be read: {pages}'**
  String comicPagesSkipped(String pages);

  /// UC-24 main flow step 4 / FR-VW-04: returns a zoomed image to fitting the window.
  ///
  /// In en, this message translates to:
  /// **'Fit to the window'**
  String get imageFit;

  /// UC-24 main flow step 5: moves to the next image in the current listing.
  ///
  /// In en, this message translates to:
  /// **'Next image'**
  String get imageNext;

  /// UC-24 main flow step 5: moves to the previous one.
  ///
  /// In en, this message translates to:
  /// **'Previous image'**
  String get imagePrevious;

  /// UC-24: where the owner is in the listing they opened the image from.
  ///
  /// In en, this message translates to:
  /// **'{position} of {total}'**
  String imageOf(int position, int total);

  /// UC-25 AF-03: the renderer draws widgets and has no engine to run script in, and the owner is told rather than left wondering why the page's controls do nothing.
  ///
  /// In en, this message translates to:
  /// **'This page is shown as content. Any script it contains is not run.'**
  String get pageScriptsNotRun;

  /// UC-25 AF-04: what could be parsed is drawn, and the rest is admitted to.
  ///
  /// In en, this message translates to:
  /// **'This page\'s markup is incomplete, so some of it may be missing.'**
  String get pageMalformed;

  /// UC-25 AF-02: the page renders without them and names what could not be loaded.
  ///
  /// In en, this message translates to:
  /// **'These files the page refers to are not on disk: {assets}'**
  String pageMissingAssets(String assets);

  /// UC-28 main flow step 3: opens the form that creates one.
  ///
  /// In en, this message translates to:
  /// **'Add a bookmark'**
  String get bookmarkAdd;

  /// UC-28 main flow step 5: opens the form on an existing bookmark.
  ///
  /// In en, this message translates to:
  /// **'Edit this bookmark'**
  String get bookmarkEdit;

  /// UC-28 main flow step 4: sends the new bookmark to the core.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get bookmarkCreate;

  /// UC-28 main flow step 5: sends the changed bookmark to the core.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get bookmarkSave;

  /// UC-28: what the bookmark is called in the listing.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get bookmarkTitleLabel;

  /// UC-28: the address the bookmark opens.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get bookmarkUrlLabel;

  /// UC-28 main flow step 2: the listing is empty, which is a state and not a failure.
  ///
  /// In en, this message translates to:
  /// **'You have not saved any bookmarks yet.'**
  String get bookmarksNone;

  /// UC-28 AF-01 / FR-OG-12: a blank title or address, refused before the core is called.
  ///
  /// In en, this message translates to:
  /// **'This cannot be empty.'**
  String get bookmarkFieldEmpty;

  /// UC-28 AF-01 / FR-OG-12: the address does not parse.
  ///
  /// In en, this message translates to:
  /// **'This is not an address.'**
  String get bookmarkUrlMalformed;

  /// UC-28 AF-01: it parses, but not as something a browser could open.
  ///
  /// In en, this message translates to:
  /// **'Enter a web address starting with http:// or https://.'**
  String get bookmarkUrlUnopenable;

  /// UC-28 AF-04: the platform would not launch one.
  ///
  /// In en, this message translates to:
  /// **'No browser could be opened for this bookmark.'**
  String get bookmarkNoBrowser;

  /// UC-28 AF-04: the only useful thing left when no browser opens — the owner takes the address elsewhere.
  ///
  /// In en, this message translates to:
  /// **'Copy the address'**
  String get bookmarkCopyUrl;

  /// UC-29 main flow step 1: the watchlists screen's heading.
  ///
  /// In en, this message translates to:
  /// **'Watchlists'**
  String get watchlistsTitle;

  /// UC-29 main flow step 1: opens the watchlists screen from the videos area.
  ///
  /// In en, this message translates to:
  /// **'Watchlists'**
  String get watchlistsOpen;

  /// UC-29: there are no watchlists, which is a state and not a failure.
  ///
  /// In en, this message translates to:
  /// **'You have not made a watchlist yet.'**
  String get watchlistsNone;

  /// UC-29 main flow step 1: what the new watchlist is called.
  ///
  /// In en, this message translates to:
  /// **'Watchlist name'**
  String get watchlistNameLabel;

  /// UC-29 main flow step 2: sends the new watchlist to the core.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get watchlistCreate;

  /// UC-29 AF-01: the name is blank after trimming, so the core is not called.
  ///
  /// In en, this message translates to:
  /// **'Give the watchlist a name.'**
  String get watchlistNameEmpty;

  /// UC-29 main flow step 6: removes the tracking and keeps the videos.
  ///
  /// In en, this message translates to:
  /// **'Delete this watchlist'**
  String get watchlistDelete;

  /// UC-29: the watchlist holds no videos.
  ///
  /// In en, this message translates to:
  /// **'Nothing is tracked in this watchlist yet.'**
  String get watchlistEmpty;

  /// UC-29 main flow step 3: tracks this video in a watchlist.
  ///
  /// In en, this message translates to:
  /// **'Add to a watchlist'**
  String get watchlistAddTo;

  /// UC-29 main flow step 5: removes the video from this watchlist and leaves it in the catalog.
  ///
  /// In en, this message translates to:
  /// **'Stop tracking this video'**
  String get watchlistRemoveVideo;

  /// UC-29 AF-03: nothing is added, and the owner is told why.
  ///
  /// In en, this message translates to:
  /// **'That video is already in that watchlist.'**
  String get watchlistAlreadyTracked;

  /// UC-29 AF-04 / UC-30 AF-04: the core has no such record, so the screen is read again.
  ///
  /// In en, this message translates to:
  /// **'That watchlist or video is no longer there.'**
  String get watchlistNotFound;

  /// UC-30: the watch state the core calls pending.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get watchStatePending;

  /// UC-30: part way through.
  ///
  /// In en, this message translates to:
  /// **'Watching'**
  String get watchStateWatching;

  /// UC-30: finished.
  ///
  /// In en, this message translates to:
  /// **'Watched'**
  String get watchStateWatched;

  /// UC-29 main flow step 6 / BR-07: the confirmation names what goes and what does not.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}? The videos in it are kept — only the tracking is removed.'**
  String watchlistDeleteMessage(String name);

  /// UC-29 AF-03: a watchlist already tracking this video says so rather than disappearing from the menu.
  ///
  /// In en, this message translates to:
  /// **'{name} — already there'**
  String watchlistAlreadyIn(String name);

  /// UC-29: how many videos a watchlist tracks.
  ///
  /// In en, this message translates to:
  /// **'{count} tracked'**
  String watchlistItemCount(int count);

  /// UC-30 main flow step 5: sends the watch state and episode to the core.
  ///
  /// In en, this message translates to:
  /// **'Save progress'**
  String get watchProgressSave;

  /// UC-30 main flow step 4: which episode the owner is on.
  ///
  /// In en, this message translates to:
  /// **'Episode'**
  String get watchCurrentEpisodeLabel;

  /// UC-30 main flow step 4: how many episodes there are, when the owner knows.
  ///
  /// In en, this message translates to:
  /// **'of how many'**
  String get watchTotalEpisodesLabel;

  /// UC-30 AF-02: the episode field holds something that is not a number.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number.'**
  String get watchEpisodeNotANumber;

  /// UC-30 AF-02: the episode number is zero or negative.
  ///
  /// In en, this message translates to:
  /// **'Episodes are counted from 1.'**
  String get watchEpisodeNotPositive;

  /// UC-30 AF-02: the current episode exceeds the stated total.
  ///
  /// In en, this message translates to:
  /// **'That is past the total you gave.'**
  String get watchEpisodeBeyondTotal;

  /// UC-30 / FR-TR-07: where in a series the owner is, when they have not said how many there are.
  ///
  /// In en, this message translates to:
  /// **'episode {episode}'**
  String watchEpisode(int episode);

  /// UC-30 / FR-TR-07: where in a series the owner is.
  ///
  /// In en, this message translates to:
  /// **'episode {episode} of {total}'**
  String watchEpisodeOf(int episode, int total);

  /// UC-31 main flow step 1: the reading-lists screen heading.
  ///
  /// In en, this message translates to:
  /// **'Reading lists'**
  String get readingListsTitle;

  /// UC-31 main flow step 1: opens the reading-lists screen from the books and comics areas.
  ///
  /// In en, this message translates to:
  /// **'Reading lists'**
  String get readingListsOpen;

  /// UC-31: there are no reading lists, which is a state and not a failure.
  ///
  /// In en, this message translates to:
  /// **'You have not made a reading list yet.'**
  String get readingListsNone;

  /// UC-31 main flow step 1: what the new reading list is called.
  ///
  /// In en, this message translates to:
  /// **'Reading list name'**
  String get readingListNameLabel;

  /// UC-31 main flow step 2: sends the new reading list to the core.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get readingListCreate;

  /// UC-31 AF-01: the name is blank after trimming, so the core is not called.
  ///
  /// In en, this message translates to:
  /// **'Give the reading list a name.'**
  String get readingListNameEmpty;

  /// UC-31 main flow step 6: removes the tracking and keeps the books and comics.
  ///
  /// In en, this message translates to:
  /// **'Delete this reading list'**
  String get readingListDelete;

  /// UC-31: the reading list holds no items.
  ///
  /// In en, this message translates to:
  /// **'Nothing is tracked in this reading list yet.'**
  String get readingListEmpty;

  /// UC-31 main flow step 3: tracks this book or comic in a reading list.
  ///
  /// In en, this message translates to:
  /// **'Add to a reading list'**
  String get readingListAddTo;

  /// UC-31 main flow step 5: removes the item from this list and leaves it in the catalog.
  ///
  /// In en, this message translates to:
  /// **'Stop tracking this item'**
  String get readingListRemoveItem;

  /// UC-31 AF-03: nothing is added, and the owner is told why.
  ///
  /// In en, this message translates to:
  /// **'That item is already in that reading list.'**
  String get readingListAlreadyTracked;

  /// UC-31 AF-04 and UC-32 AF-04: the core has no such record, so the screen is read again.
  ///
  /// In en, this message translates to:
  /// **'That reading list or item is no longer there.'**
  String get readingListNotFound;

  /// UC-32: the read state the core calls pending.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get readStatePending;

  /// UC-32: part way through.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get readStateReading;

  /// UC-32: finished.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get readStateRead;

  /// UC-31 main flow step 6 and BR-07: the confirmation names what goes and what does not.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}? The books and comics in it are kept — only the tracking is removed.'**
  String readingListDeleteMessage(String name);

  /// UC-31 AF-03: a reading list already tracking this item says so rather than disappearing from the menu.
  ///
  /// In en, this message translates to:
  /// **'{name} — already there'**
  String readingListAlreadyIn(String name);

  /// UC-31: how many items a reading list tracks.
  ///
  /// In en, this message translates to:
  /// **'{count} tracked'**
  String readingListItemCount(int count);

  /// UC-32 main flow step 4: which issue of the series the owner is on.
  ///
  /// In en, this message translates to:
  /// **'Current issue'**
  String get readCurrentIssueLabel;

  /// UC-32 main flow step 4: how many issues there are, when the owner knows.
  ///
  /// In en, this message translates to:
  /// **'Total issues'**
  String get readTotalIssuesLabel;

  /// UC-32 AF-02: the issue field holds something that is not a number, so the core is not called.
  ///
  /// In en, this message translates to:
  /// **'Use a whole number.'**
  String get readIssueNotANumber;

  /// UC-32 AF-02: the issue number is zero or negative.
  ///
  /// In en, this message translates to:
  /// **'Issues are counted from one.'**
  String get readIssueNotPositive;

  /// UC-32 AF-02: the current issue exceeds the stated total.
  ///
  /// In en, this message translates to:
  /// **'That is past the total you gave.'**
  String get readIssueBeyondTotal;

  /// UC-32 main flow step 5: sends the read state and the issue to the core.
  ///
  /// In en, this message translates to:
  /// **'Save progress'**
  String get readProgressSave;

  /// UC-32: where in a series the owner is, with no total stated.
  ///
  /// In en, this message translates to:
  /// **'issue {current}'**
  String readIssue(int current);

  /// UC-32: where in a series the owner is, out of the total they gave.
  ///
  /// In en, this message translates to:
  /// **'issue {current} of {total}'**
  String readIssueOf(int current, int total);

  /// UC-33 main flow step 1: hides the file's record from the library.
  ///
  /// In en, this message translates to:
  /// **'Delete this file'**
  String get deleteFile;

  /// UC-33 main flow step 2 and FR-LC-01: the confirmation says so explicitly.
  ///
  /// In en, this message translates to:
  /// **'The file on disk is not affected.'**
  String get deleteFileOnDisk;

  /// UC-33 AF-04: a player, viewer, or editor has the file, and confirming lets it go.
  ///
  /// In en, this message translates to:
  /// **'It is playing or open right now — confirming stops it.'**
  String get deleteFileInUse;

  /// UC-33 main flow step 1: hides the bookmark's record.
  ///
  /// In en, this message translates to:
  /// **'Delete this bookmark'**
  String get deleteBookmark;

  /// UC-33 AF-02: the core holds it as deleted already, so the listing is read again.
  ///
  /// In en, this message translates to:
  /// **'That record was already deleted.'**
  String get deleteAlreadyDeleted;

  /// UC-33 AF-03: the core has no such record, so the listing is read again.
  ///
  /// In en, this message translates to:
  /// **'That record is no longer there.'**
  String get deleteNotFound;

  /// UC-33 main flow step 2: the confirmation names the file and says the record is restorable.
  ///
  /// In en, this message translates to:
  /// **'Hide {name} from the library? It stays restorable.'**
  String deleteFileMessage(String name);

  /// UC-33 main flow step 2: the same, for a bookmark, which has no file on disk.
  ///
  /// In en, this message translates to:
  /// **'Hide {title} from your bookmarks? It stays restorable.'**
  String deleteBookmarkMessage(String title);

  /// UC-34 main flow step 1: the deleted-items screen heading.
  ///
  /// In en, this message translates to:
  /// **'Deleted items'**
  String get deletedItemsTitle;

  /// UC-34 main flow step 1: opens the deleted-items view from the dashboard.
  ///
  /// In en, this message translates to:
  /// **'Deleted items'**
  String get deletedItemsOpen;

  /// UC-34 AF-01: there is nothing deleted, which is a state and not a failure.
  ///
  /// In en, this message translates to:
  /// **'Nothing has been deleted.'**
  String get deletedItemsNone;

  /// UC-34 main flow step 4: brings the record back into the default listings.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreRecord;

  /// UC-34 AF-03: the core has no such record, which is also how it answers one past its retention window.
  ///
  /// In en, this message translates to:
  /// **'That record cannot be restored — it is gone, or its window has passed.'**
  String get restoreNotFound;

  /// UC-34 AF-02: the retention window has run out, so purging is what is left.
  ///
  /// In en, this message translates to:
  /// **'No longer restorable — it can only be purged.'**
  String get retentionElapsed;

  /// UC-34: the core answered without a deletion timestamp, so there is no countdown to show.
  ///
  /// In en, this message translates to:
  /// **'Restorable'**
  String get retentionUnknown;

  /// UC-34 main flow step 3 and FR-LC-03: how long this record remains restorable.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Restorable for 1 more day} other{Restorable for {days} more days}}'**
  String retentionRemaining(num days);

  /// UC-35 main flow step 1: removes the record from the catalog for good.
  ///
  /// In en, this message translates to:
  /// **'Purge'**
  String get purgeRecord;

  /// UC-35 main flow step 2 and FR-LC-05: the confirmation says so explicitly.
  ///
  /// In en, this message translates to:
  /// **'The file on disk is not removed.'**
  String get purgeRecordOnDisk;

  /// UC-35 AF-03: the record is not soft-deleted, so the core is not called.
  ///
  /// In en, this message translates to:
  /// **'Delete that record first — only a deleted record can be purged.'**
  String get purgeNotDeleted;

  /// UC-35 AF-04 and UC-36 AF-04: the core has no such record, so the view is read again.
  ///
  /// In en, this message translates to:
  /// **'That record is no longer there.'**
  String get purgeNotFound;

  /// UC-36 AF-02: the core succeeded and there was nothing on disk to remove.
  ///
  /// In en, this message translates to:
  /// **'The record was removed, and no file was found on disk.'**
  String get purgeNothingOnDisk;

  /// UC-36 AF-03: the disk refused, and the core left both alone.
  ///
  /// In en, this message translates to:
  /// **'Nothing was removed — neither the file nor the record.'**
  String get purgeDiskFailed;

  /// UC-35 main flow step 2: the confirmation names the record and says the removal is permanent.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from the catalog permanently? This cannot be undone.'**
  String purgeRecordMessage(String name);

  /// UC-35 AF-02 and FR-LC-07: the core refused because the retention window has not elapsed, and this says when it will have.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{That record can be purged in 1 day.} other{That record can be purged in {days} days.}}'**
  String purgeTooSoon(num days);

  /// UC-36 main flow step 1: the folded-away section that deletes the file itself.
  ///
  /// In en, this message translates to:
  /// **'Remove from disk'**
  String get purgeOnDiskTitle;

  /// UC-36 main flow step 1: the action itself, which is never a default.
  ///
  /// In en, this message translates to:
  /// **'Delete the file from disk'**
  String get purgeOnDiskAction;

  /// UC-36 and FR-LC-06: why this action is presented apart from every other deletion.
  ///
  /// In en, this message translates to:
  /// **'This is the only action here that removes your data from disk. Everything else keeps the file and changes only the catalog.'**
  String get purgeOnDiskExplanation;

  /// UC-36 main flow step 2: the confirmation says the deletion is irreversible.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get purgeOnDiskIrreversible;

  /// UC-36 main flow step 2 and FR-LC-06: the confirmation names the exact file path.
  ///
  /// In en, this message translates to:
  /// **'Delete {path} from disk and remove its record?'**
  String purgeOnDiskMessage(String path);

  /// UC-37 main flow step 1: the missing-files review heading.
  ///
  /// In en, this message translates to:
  /// **'Missing files'**
  String get missingFilesTitle;

  /// UC-37 main flow step 1: opens the review from the dashboard, beside the last index run.
  ///
  /// In en, this message translates to:
  /// **'Missing files'**
  String get missingFilesOpen;

  /// UC-37 AF-01: nothing is missing, which is a state and the good outcome besides.
  ///
  /// In en, this message translates to:
  /// **'Every cataloged file was found on disk.'**
  String get missingFilesNone;

  /// UC-37 and BR-16: missing is never a reason to delete, and the review says so.
  ///
  /// In en, this message translates to:
  /// **'These records are still in the catalog — nothing is removed because a file is absent. Re-scan to check whether they came back, or open a record to decide what to do about it.'**
  String get missingFilesExplanation;

  /// UC-37 main flow step 4: starts a refresh over everything cataloged (UC-07).
  ///
  /// In en, this message translates to:
  /// **'Re-scan the library'**
  String get missingFilesRescan;

  /// UC-37 AF-02: opens the record's own detail view, where deleting it lives.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get missingFilesOpenDetails;

  /// UC-37 AF-03: the record came from a folder the owner has since unregistered.
  ///
  /// In en, this message translates to:
  /// **'From a folder that is no longer registered.'**
  String get missingFilesUnregisteredFolder;

  /// UC-40 main flow step 2: the heading of the screen shown once after sign-up.
  ///
  /// In en, this message translates to:
  /// **'Save your recovery codes'**
  String get recoveryCodesTitle;

  /// UC-40 main flow step 2 and FR-AU-12: says plainly that the codes are not retrievable and what they are for.
  ///
  /// In en, this message translates to:
  /// **'This is the only time these are shown. Each one replaces a forgotten password exactly once — without them, a forgotten password means a lost library.'**
  String get recoveryCodesExplanation;

  /// UC-40 AF-02: places the codes on the clipboard. Nothing is written to disk (FR-AU-13).
  ///
  /// In en, this message translates to:
  /// **'Copy the codes'**
  String get recoveryCodesCopy;

  /// UC-40 AF-02: confirms the copy happened.
  ///
  /// In en, this message translates to:
  /// **'Copied to the clipboard.'**
  String get recoveryCodesCopied;

  /// UC-40 main flow step 4: the only way past this screen (AF-01). Confirming opens the library.
  ///
  /// In en, this message translates to:
  /// **'I have stored them'**
  String get recoveryCodesAcknowledge;

  /// UC-40 AF-03: the core issued no codes, which is said plainly rather than shown as an empty list.
  ///
  /// In en, this message translates to:
  /// **'Your account was created, but no recovery codes came with it. Generate a set from preferences before you need one.'**
  String get recoveryCodesNone;
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
