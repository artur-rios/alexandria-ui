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

  /// FR-AU-12 / BR-25: heading of the state that stands in place of the catalog while the account's e-mail is unconfirmed. The prompt itself is UC-40.
  ///
  /// In en, this message translates to:
  /// **'Confirm your e-mail address'**
  String get catalogLockedTitle;

  /// FR-AU-12: explains why the catalog is not reachable. The address is named so the owner knows where to look.
  ///
  /// In en, this message translates to:
  /// **'Alexandria stays locked until the address {email} is confirmed.'**
  String catalogLockedBody(String email);

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

  /// UC-01 AF-06: the account was created and the session is open, but the core reported that the confirmation message was not sent. Stated plainly so the owner does not wait for a message that is never coming.
  ///
  /// In en, this message translates to:
  /// **'The confirmation message could not be sent, so it is not on its way. Alexandria cannot deliver e-mail yet.'**
  String get catalogLockedUndeliverable;

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

  /// Placeholder in the shell's content area (UC-38). Each destination's listing arrives with its own use case; until then the area states that it is empty rather than rendering a spinner that never resolves.
  ///
  /// In en, this message translates to:
  /// **'Nothing to show here yet.'**
  String get shellAreaPending;

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

  /// Navigation panel entry for standalone films (FR-CT-01).
  ///
  /// In en, this message translates to:
  /// **'Movies'**
  String get destinationMovies;

  /// Navigation panel entry for episodic video (FR-CT-01).
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get destinationSeries;

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
