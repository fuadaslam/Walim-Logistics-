import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('ar'),
    Locale('en'),
    Locale('hi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Walim Logistics'**
  String get appTitle;

  /// No description provided for @subtitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Walim Logistics'**
  String get subtitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @controlOperations.
  ///
  /// In en, this message translates to:
  /// **'Control your operations with precision'**
  String get controlOperations;

  /// No description provided for @checkIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get checkIn;

  /// No description provided for @checkOut.
  ///
  /// In en, this message translates to:
  /// **'Check-out'**
  String get checkOut;

  /// No description provided for @riderDashboard.
  ///
  /// In en, this message translates to:
  /// **'Rider Dashboard'**
  String get riderDashboard;

  /// No description provided for @leaderPortal.
  ///
  /// In en, this message translates to:
  /// **'Leader Portal'**
  String get leaderPortal;

  /// No description provided for @performanceHub.
  ///
  /// In en, this message translates to:
  /// **'Performance Hub'**
  String get performanceHub;

  /// No description provided for @vehicleInspection.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Inspection'**
  String get vehicleInspection;

  /// No description provided for @safetyGear.
  ///
  /// In en, this message translates to:
  /// **'Safety Gear'**
  String get safetyGear;

  /// No description provided for @myAssets.
  ///
  /// In en, this message translates to:
  /// **'My Assets'**
  String get myAssets;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @documentVault.
  ///
  /// In en, this message translates to:
  /// **'Document Vault'**
  String get documentVault;

  /// No description provided for @shiftManagement.
  ///
  /// In en, this message translates to:
  /// **'Shift Management'**
  String get shiftManagement;

  /// No description provided for @inventoryHandover.
  ///
  /// In en, this message translates to:
  /// **'Inventory Handover'**
  String get inventoryHandover;

  /// No description provided for @liveTracking.
  ///
  /// In en, this message translates to:
  /// **'Live Tracking'**
  String get liveTracking;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirm;

  /// No description provided for @fleetOperations.
  ///
  /// In en, this message translates to:
  /// **'Fleet Operations'**
  String get fleetOperations;

  /// No description provided for @signInPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter your credentials to sign in'**
  String get signInPrompt;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @opsControl.
  ///
  /// In en, this message translates to:
  /// **'Operations Control'**
  String get opsControl;

  /// No description provided for @opsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Real-time fleet intelligence and strategic allocation'**
  String get opsSubtitle;

  /// No description provided for @corePerformanceMetrics.
  ///
  /// In en, this message translates to:
  /// **'Core Performance Metrics'**
  String get corePerformanceMetrics;

  /// No description provided for @managementConsole.
  ///
  /// In en, this message translates to:
  /// **'Management Console'**
  String get managementConsole;

  /// No description provided for @liveActivity.
  ///
  /// In en, this message translates to:
  /// **'Live Activity'**
  String get liveActivity;

  /// No description provided for @activeRiders.
  ///
  /// In en, this message translates to:
  /// **'Active Riders'**
  String get activeRiders;

  /// No description provided for @ridersOnLeave.
  ///
  /// In en, this message translates to:
  /// **'Riders on Leave'**
  String get ridersOnLeave;

  /// No description provided for @activeIncidents.
  ///
  /// In en, this message translates to:
  /// **'Active Incidents'**
  String get activeIncidents;

  /// No description provided for @supervisors.
  ///
  /// In en, this message translates to:
  /// **'Supervisors'**
  String get supervisors;

  /// No description provided for @sos.
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get sos;

  /// No description provided for @eos.
  ///
  /// In en, this message translates to:
  /// **'EOS'**
  String get eos;

  /// No description provided for @vehicleAllocation.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Allocation'**
  String get vehicleAllocation;

  /// No description provided for @liveRiderTracking.
  ///
  /// In en, this message translates to:
  /// **'Live Rider Tracking'**
  String get liveRiderTracking;

  /// No description provided for @capacityPlanning.
  ///
  /// In en, this message translates to:
  /// **'Capacity Planning'**
  String get capacityPlanning;

  /// No description provided for @groupManagement.
  ///
  /// In en, this message translates to:
  /// **'Group Management'**
  String get groupManagement;

  /// No description provided for @shiftPlanner.
  ///
  /// In en, this message translates to:
  /// **'Shift Planner'**
  String get shiftPlanner;

  /// No description provided for @supervisorSchedule.
  ///
  /// In en, this message translates to:
  /// **'Supervisor Schedule'**
  String get supervisorSchedule;

  /// No description provided for @matchingDataCenter.
  ///
  /// In en, this message translates to:
  /// **'Matching Data Center'**
  String get matchingDataCenter;

  /// No description provided for @globalAssetView.
  ///
  /// In en, this message translates to:
  /// **'Global Asset View'**
  String get globalAssetView;

  /// No description provided for @staffMonitoring.
  ///
  /// In en, this message translates to:
  /// **'Staff Monitoring'**
  String get staffMonitoring;

  /// No description provided for @safetyInspections.
  ///
  /// In en, this message translates to:
  /// **'Safety & Inspections'**
  String get safetyInspections;

  /// No description provided for @performanceManagement.
  ///
  /// In en, this message translates to:
  /// **'Performance Management'**
  String get performanceManagement;

  /// No description provided for @leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// No description provided for @sosEosMonitoring.
  ///
  /// In en, this message translates to:
  /// **'SOS/EOS Monitoring'**
  String get sosEosMonitoring;

  /// No description provided for @controlTower.
  ///
  /// In en, this message translates to:
  /// **'Control Tower'**
  String get controlTower;

  /// No description provided for @opsStrategy.
  ///
  /// In en, this message translates to:
  /// **'Operations Strategy'**
  String get opsStrategy;

  /// No description provided for @liveGPS.
  ///
  /// In en, this message translates to:
  /// **'Live GPS'**
  String get liveGPS;

  /// No description provided for @hrManagement.
  ///
  /// In en, this message translates to:
  /// **'HR Management'**
  String get hrManagement;

  /// No description provided for @assetManagement.
  ///
  /// In en, this message translates to:
  /// **'Asset Management'**
  String get assetManagement;

  /// No description provided for @financialManagement.
  ///
  /// In en, this message translates to:
  /// **'Financial Management'**
  String get financialManagement;

  /// No description provided for @fleetPerformanceHub.
  ///
  /// In en, this message translates to:
  /// **'Fleet Performance Hub'**
  String get fleetPerformanceHub;

  /// No description provided for @myRequests.
  ///
  /// In en, this message translates to:
  /// **'My Requests'**
  String get myRequests;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @myDashboard.
  ///
  /// In en, this message translates to:
  /// **'My Dashboard'**
  String get myDashboard;

  /// No description provided for @itDevelopment.
  ///
  /// In en, this message translates to:
  /// **'IT & Development'**
  String get itDevelopment;

  /// No description provided for @teamLeadership.
  ///
  /// In en, this message translates to:
  /// **'Team Leadership'**
  String get teamLeadership;

  /// No description provided for @businessGrowth.
  ///
  /// In en, this message translates to:
  /// **'Business Growth'**
  String get businessGrowth;

  /// No description provided for @opsStrategySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fleet allocation, SLA monitoring, and planning'**
  String get opsStrategySubtitle;

  /// No description provided for @controlTowerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Real-time metrics across all zones and platforms'**
  String get controlTowerSubtitle;

  /// No description provided for @hrManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage staff, government regulations, housing, and assets'**
  String get hrManagementSubtitle;

  /// No description provided for @financialManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Payroll, vendor invoicing, and expenses'**
  String get financialManagementSubtitle;

  /// No description provided for @supervisorDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Oversee operations and resolve blockers'**
  String get supervisorDashboardSubtitle;

  /// No description provided for @itDevDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'System health and API monitoring'**
  String get itDevDashboardSubtitle;

  /// No description provided for @teamLeadershipSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your team and performance'**
  String get teamLeadershipSubtitle;

  /// No description provided for @riderDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your daily stats and tasks'**
  String get riderDashboardSubtitle;

  /// No description provided for @bizDevDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sales and partnership metrics'**
  String get bizDevDashboardSubtitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @gps.
  ///
  /// In en, this message translates to:
  /// **'GPS'**
  String get gps;

  /// No description provided for @riders.
  ///
  /// In en, this message translates to:
  /// **'Riders'**
  String get riders;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @performance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get performance;

  /// No description provided for @commandCenter.
  ///
  /// In en, this message translates to:
  /// **'Command Center'**
  String get commandCenter;
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
      <String>['ar', 'en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
