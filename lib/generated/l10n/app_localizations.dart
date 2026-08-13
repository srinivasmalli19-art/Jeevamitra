import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_te.dart';

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
    Locale('hi'),
    Locale('te')
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'JeevaMitra'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Your Farming Companion'**
  String get tagline;

  /// No description provided for @continueBtn.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueBtn;

  /// No description provided for @skipBtn.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipBtn;

  /// No description provided for @backBtn.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backBtn;

  /// No description provided for @saveBtn.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveBtn;

  /// No description provided for @cancelBtn.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelBtn;

  /// No description provided for @confirmBtn.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmBtn;

  /// No description provided for @deleteBtn.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteBtn;

  /// No description provided for @editBtn.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editBtn;

  /// No description provided for @retryBtn.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get retryBtn;

  /// No description provided for @closeBtn.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeBtn;

  /// No description provided for @doneBtn.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneBtn;

  /// No description provided for @nextBtn.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextBtn;

  /// No description provided for @yesBtn.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yesBtn;

  /// No description provided for @noBtn.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get noBtn;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchHint;

  /// No description provided for @loadingMsg.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingMsg;

  /// No description provided for @noInternetMsg.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternetMsg;

  /// No description provided for @errorMsg.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorMsg;

  /// No description provided for @noDataMsg.
  ///
  /// In en, this message translates to:
  /// **'No data found'**
  String get noDataMsg;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get selectLanguage;

  /// No description provided for @languageHint.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language'**
  String get languageHint;

  /// No description provided for @onboardTitle1.
  ///
  /// In en, this message translates to:
  /// **'List Your Farm Land'**
  String get onboardTitle1;

  /// No description provided for @onboardBody1.
  ///
  /// In en, this message translates to:
  /// **'Farmers can register their land and make it available for shepherds to graze.'**
  String get onboardBody1;

  /// No description provided for @onboardTitle2.
  ///
  /// In en, this message translates to:
  /// **'Find Grazing Land Nearby'**
  String get onboardTitle2;

  /// No description provided for @onboardBody2.
  ///
  /// In en, this message translates to:
  /// **'Search available grazing land near you and book directly with the farmer.'**
  String get onboardBody2;

  /// No description provided for @onboardTitle3.
  ///
  /// In en, this message translates to:
  /// **'Vets Near You'**
  String get onboardTitle3;

  /// No description provided for @onboardBody3.
  ///
  /// In en, this message translates to:
  /// **'Find nearby veterinarians for emergencies with a single tap.'**
  String get onboardBody3;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobileNumber;

  /// No description provided for @mobileNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Enter 10-digit mobile number'**
  String get mobileNumberHint;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @enterOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP'**
  String get enterOtp;

  /// No description provided for @otpHint.
  ///
  /// In en, this message translates to:
  /// **'6-digit OTP'**
  String get otpHint;

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOtp;

  /// No description provided for @resendOtp.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOtp;

  /// No description provided for @resendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String resendIn(int seconds);

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'OTP sent to {phone}'**
  String otpSentTo(String phone);

  /// No description provided for @selectRole.
  ///
  /// In en, this message translates to:
  /// **'I am a...'**
  String get selectRole;

  /// No description provided for @roleFarmer.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get roleFarmer;

  /// No description provided for @roleFarmerDesc.
  ///
  /// In en, this message translates to:
  /// **'I have land and want to offer it for grazing'**
  String get roleFarmerDesc;

  /// No description provided for @roleShepherd.
  ///
  /// In en, this message translates to:
  /// **'Shepherd'**
  String get roleShepherd;

  /// No description provided for @roleShepherdDesc.
  ///
  /// In en, this message translates to:
  /// **'I have animals and need grazing land'**
  String get roleShepherdDesc;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your Name'**
  String get yourName;

  /// No description provided for @yourVillage.
  ///
  /// In en, this message translates to:
  /// **'Village / Town'**
  String get yourVillage;

  /// No description provided for @yourDistrict.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get yourDistrict;

  /// No description provided for @completeProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete Profile'**
  String get completeProfile;

  /// No description provided for @farmerDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get farmerDashboard;

  /// No description provided for @myLands.
  ///
  /// In en, this message translates to:
  /// **'My Lands'**
  String get myLands;

  /// No description provided for @bookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get bookings;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @shepherdDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get shepherdDashboard;

  /// No description provided for @discover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discover;

  /// No description provided for @vets.
  ///
  /// In en, this message translates to:
  /// **'Vets'**
  String get vets;

  /// No description provided for @addLand.
  ///
  /// In en, this message translates to:
  /// **'Add Land'**
  String get addLand;

  /// No description provided for @landTitle.
  ///
  /// In en, this message translates to:
  /// **'Land Title'**
  String get landTitle;

  /// No description provided for @landArea.
  ///
  /// In en, this message translates to:
  /// **'Land Area'**
  String get landArea;

  /// No description provided for @pricePerDay.
  ///
  /// In en, this message translates to:
  /// **'Price per Day / Animal'**
  String get pricePerDay;

  /// No description provided for @fodderTypes.
  ///
  /// In en, this message translates to:
  /// **'Fodder Available'**
  String get fodderTypes;

  /// No description provided for @amenities.
  ///
  /// In en, this message translates to:
  /// **'Amenities'**
  String get amenities;

  /// No description provided for @water.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get water;

  /// No description provided for @shade.
  ///
  /// In en, this message translates to:
  /// **'Shade'**
  String get shade;

  /// No description provided for @fencing.
  ///
  /// In en, this message translates to:
  /// **'Fencing'**
  String get fencing;

  /// No description provided for @vetNearby.
  ///
  /// In en, this message translates to:
  /// **'Vet Nearby'**
  String get vetNearby;

  /// No description provided for @bookNow.
  ///
  /// In en, this message translates to:
  /// **'Book Now'**
  String get bookNow;

  /// No description provided for @checkIn.
  ///
  /// In en, this message translates to:
  /// **'Check In'**
  String get checkIn;

  /// No description provided for @checkOut.
  ///
  /// In en, this message translates to:
  /// **'Check Out'**
  String get checkOut;

  /// No description provided for @animalCount.
  ///
  /// In en, this message translates to:
  /// **'Number of Animals'**
  String get animalCount;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmount;

  /// No description provided for @advanceAmount.
  ///
  /// In en, this message translates to:
  /// **'Advance'**
  String get advanceAmount;

  /// No description provided for @bookingPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get bookingPending;

  /// No description provided for @bookingConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get bookingConfirmed;

  /// No description provided for @bookingActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get bookingActive;

  /// No description provided for @bookingCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get bookingCompleted;

  /// No description provided for @bookingCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get bookingCancelled;

  /// No description provided for @nearbyVets.
  ///
  /// In en, this message translates to:
  /// **'Vets Nearby'**
  String get nearbyVets;

  /// No description provided for @govtVet.
  ///
  /// In en, this message translates to:
  /// **'Govt. Vet'**
  String get govtVet;

  /// No description provided for @available24x7.
  ///
  /// In en, this message translates to:
  /// **'24×7 Available'**
  String get available24x7;

  /// No description provided for @consultationFee.
  ///
  /// In en, this message translates to:
  /// **'Consultation Fee'**
  String get consultationFee;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @callVet.
  ///
  /// In en, this message translates to:
  /// **'Call Vet'**
  String get callVet;

  /// No description provided for @whatsappVet.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsappVet;

  /// No description provided for @emergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get emergency;

  /// No description provided for @emergencyCallVet.
  ///
  /// In en, this message translates to:
  /// **'Call Nearest Vet'**
  String get emergencyCallVet;

  /// No description provided for @emergencyHelpline.
  ///
  /// In en, this message translates to:
  /// **'Helpline 1962'**
  String get emergencyHelpline;

  /// No description provided for @voiceInputHint.
  ///
  /// In en, this message translates to:
  /// **'Tap mic to speak'**
  String get voiceInputHint;

  /// No description provided for @listeningMsg.
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get listeningMsg;

  /// No description provided for @voiceNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Voice not supported on this device'**
  String get voiceNotSupported;

  /// No description provided for @rateExperience.
  ///
  /// In en, this message translates to:
  /// **'Rate your experience'**
  String get rateExperience;

  /// No description provided for @writeReview.
  ///
  /// In en, this message translates to:
  /// **'Write a review'**
  String get writeReview;

  /// No description provided for @submitReview.
  ///
  /// In en, this message translates to:
  /// **'Submit Review'**
  String get submitReview;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirm;

  /// No description provided for @distanceKm.
  ///
  /// In en, this message translates to:
  /// **'{km} km away'**
  String distanceKm(String km);

  /// No description provided for @distanceMetersAway.
  ///
  /// In en, this message translates to:
  /// **'{m} m away'**
  String distanceMetersAway(int m);

  /// No description provided for @perDayPerAnimal.
  ///
  /// In en, this message translates to:
  /// **'₹{price}/day/animal'**
  String perDayPerAnimal(String price);

  /// No description provided for @availableNow.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get availableNow;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not Available'**
  String get notAvailable;

  /// No description provided for @acres.
  ///
  /// In en, this message translates to:
  /// **'{area} Acres'**
  String acres(String area);

  /// No description provided for @mobileNumberSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number to receive OTP'**
  String get mobileNumberSubtitle;

  /// No description provided for @termsAgreement.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our Terms & Privacy Policy'**
  String get termsAgreement;

  /// No description provided for @otpNotReceivedMsg.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive OTP?'**
  String get otpNotReceivedMsg;

  /// No description provided for @selectRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Who are you?'**
  String get selectRoleTitle;

  /// No description provided for @genericErrorRetryMsg.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get genericErrorRetryMsg;

  /// No description provided for @invalidOtpMsg.
  ///
  /// In en, this message translates to:
  /// **'Invalid OTP. Please try again.'**
  String get invalidOtpMsg;

  /// No description provided for @genericSaveFailedMsg.
  ///
  /// In en, this message translates to:
  /// **'Failed to save. Please try again.'**
  String get genericSaveFailedMsg;

  /// No description provided for @completeProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile to get started'**
  String get completeProfileSubtitle;

  /// No description provided for @yourNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get yourNameHint;

  /// No description provided for @yourVillageHint.
  ///
  /// In en, this message translates to:
  /// **'Your village or town name'**
  String get yourVillageHint;

  /// No description provided for @saveContinueBtn.
  ///
  /// In en, this message translates to:
  /// **'Save & Continue'**
  String get saveContinueBtn;

  /// No description provided for @saveProfileFailedMsg.
  ///
  /// In en, this message translates to:
  /// **'Could not save your profile. Please try again.'**
  String get saveProfileFailedMsg;

  /// No description provided for @getStartedBtn.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStartedBtn;

  /// No description provided for @homeTab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTab;

  /// No description provided for @greetingName.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}!'**
  String greetingName(String name);

  /// No description provided for @voiceAssistantTooltip.
  ///
  /// In en, this message translates to:
  /// **'Voice Assistant'**
  String get voiceAssistantTooltip;

  /// No description provided for @alertsLabel.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alertsLabel;

  /// No description provided for @overviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overviewLabel;

  /// No description provided for @earningsLabel.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earningsLabel;

  /// No description provided for @recentBookingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Recent Bookings'**
  String get recentBookingsLabel;

  /// No description provided for @viewAllBtn.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAllBtn;

  /// No description provided for @noBookingsYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No bookings yet'**
  String get noBookingsYetTitle;

  /// No description provided for @noBookingsYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bookings from shepherds will appear here'**
  String get noBookingsYetSubtitle;

  /// No description provided for @pendingApprovalMsg.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 booking awaiting your approval} other{{count} bookings awaiting your approval}}'**
  String pendingApprovalMsg(int count);

  /// No description provided for @tapToReviewMsg.
  ///
  /// In en, this message translates to:
  /// **'Tap to review and accept'**
  String get tapToReviewMsg;

  /// No description provided for @bookingSummaryMsg.
  ///
  /// In en, this message translates to:
  /// **'{count} animals · {date} · ₹{amount}'**
  String bookingSummaryMsg(int count, String date, String amount);

  /// No description provided for @upcomingLabel.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcomingLabel;

  /// No description provided for @tripsDoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Trips Done'**
  String get tripsDoneLabel;

  /// No description provided for @spentLabel.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get spentLabel;

  /// No description provided for @findLandLabel.
  ///
  /// In en, this message translates to:
  /// **'Find Land'**
  String get findLandLabel;

  /// No description provided for @findVetLabel.
  ///
  /// In en, this message translates to:
  /// **'Find Vet'**
  String get findVetLabel;

  /// No description provided for @myTripsLabel.
  ///
  /// In en, this message translates to:
  /// **'My Trips'**
  String get myTripsLabel;

  /// No description provided for @noTripsYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No trips yet'**
  String get noTripsYetTitle;

  /// No description provided for @noTripsYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Book a land to start your first trip'**
  String get noTripsYetSubtitle;

  /// No description provided for @discoverLandsBtn.
  ///
  /// In en, this message translates to:
  /// **'Discover Lands'**
  String get discoverLandsBtn;

  /// No description provided for @activeTripMsg.
  ///
  /// In en, this message translates to:
  /// **'Active trip: {title}'**
  String activeTripMsg(String title);

  /// No description provided for @tripEndsMsg.
  ///
  /// In en, this message translates to:
  /// **'{count} animals · ends {date}'**
  String tripEndsMsg(int count, String date);

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileTitle;

  /// No description provided for @profileInfoLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile Info'**
  String get profileInfoLabel;

  /// No description provided for @accountLabel.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountLabel;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete your account and all your data. This cannot be undone.'**
  String get deleteAccountBody;

  /// No description provided for @deleteAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently removes all your data'**
  String get deleteAccountSubtitle;

  /// No description provided for @landsLabel.
  ///
  /// In en, this message translates to:
  /// **'Lands'**
  String get landsLabel;

  /// No description provided for @totalTripsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Trips'**
  String get totalTripsLabel;

  /// No description provided for @phoneRequiredMsg.
  ///
  /// In en, this message translates to:
  /// **'Phone number required'**
  String get phoneRequiredMsg;

  /// No description provided for @phoneInvalidMsg.
  ///
  /// In en, this message translates to:
  /// **'Enter valid 10-digit mobile number'**
  String get phoneInvalidMsg;

  /// No description provided for @nameRequiredMsg.
  ///
  /// In en, this message translates to:
  /// **'Name required'**
  String get nameRequiredMsg;

  /// No description provided for @nameTooShortMsg.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get nameTooShortMsg;

  /// No description provided for @nameTooLongMsg.
  ///
  /// In en, this message translates to:
  /// **'Name too long'**
  String get nameTooLongMsg;

  /// No description provided for @villageRequiredMsg.
  ///
  /// In en, this message translates to:
  /// **'Village/town required'**
  String get villageRequiredMsg;

  /// No description provided for @villageInvalidMsg.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid location'**
  String get villageInvalidMsg;

  /// No description provided for @otpRequiredMsg.
  ///
  /// In en, this message translates to:
  /// **'OTP required'**
  String get otpRequiredMsg;

  /// No description provided for @otpInvalidMsg.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit OTP'**
  String get otpInvalidMsg;

  /// No description provided for @districtRequiredMsg.
  ///
  /// In en, this message translates to:
  /// **'District required'**
  String get districtRequiredMsg;

  /// No description provided for @clearBtn.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearBtn;

  /// No description provided for @filtersLabel.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filtersLabel;

  /// No description provided for @resetBtn.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetBtn;

  /// No description provided for @applyFiltersBtn.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFiltersBtn;

  /// No description provided for @anyLabel.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get anyLabel;

  /// No description provided for @villageFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Village'**
  String get villageFieldLabel;

  /// No description provided for @locationRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Location Required'**
  String get locationRequiredTitle;

  /// No description provided for @locationErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Location Error'**
  String get locationErrorTitle;

  /// No description provided for @couldNotGetLocationMsg.
  ///
  /// In en, this message translates to:
  /// **'Could not get your location.'**
  String get couldNotGetLocationMsg;

  /// No description provided for @enableLocationBtn.
  ///
  /// In en, this message translates to:
  /// **'Enable Location'**
  String get enableLocationBtn;

  /// No description provided for @couldNotOpenMapsMsg.
  ///
  /// In en, this message translates to:
  /// **'Could not open maps'**
  String get couldNotOpenMapsMsg;

  /// No description provided for @couldNotOpenDialerMsg.
  ///
  /// In en, this message translates to:
  /// **'Could not open dialer'**
  String get couldNotOpenDialerMsg;

  /// No description provided for @couldNotOpenLinkMsg.
  ///
  /// In en, this message translates to:
  /// **'Could not open this link'**
  String get couldNotOpenLinkMsg;

  /// No description provided for @whatsappNotInstalledMsg.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp not installed'**
  String get whatsappNotInstalledMsg;

  /// No description provided for @navigateBtn.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get navigateBtn;

  /// No description provided for @callBtn.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get callBtn;

  /// No description provided for @bookBtn.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get bookBtn;

  /// No description provided for @viewProfileBtn.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get viewProfileBtn;

  /// No description provided for @justNowMsg.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNowMsg;

  /// No description provided for @shareTooltip.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareTooltip;

  /// No description provided for @searchEverythingTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search Everything'**
  String get searchEverythingTooltip;

  /// No description provided for @mapViewTooltip.
  ///
  /// In en, this message translates to:
  /// **'Map View'**
  String get mapViewTooltip;

  /// No description provided for @availableTodayLabel.
  ///
  /// In en, this message translates to:
  /// **'Available Today'**
  String get availableTodayLabel;

  /// No description provided for @sortClosestLabel.
  ///
  /// In en, this message translates to:
  /// **'Closest'**
  String get sortClosestLabel;

  /// No description provided for @sortNewestLabel.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get sortNewestLabel;

  /// No description provided for @clearFiltersBtn.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFiltersBtn;

  /// No description provided for @tryFewerFiltersMsg.
  ///
  /// In en, this message translates to:
  /// **'Try removing some filters or increasing the radius.'**
  String get tryFewerFiltersMsg;

  /// No description provided for @noLandsFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'No Lands Found'**
  String get noLandsFoundTitle;

  /// No description provided for @locationNeededLandsMsg.
  ///
  /// In en, this message translates to:
  /// **'JeevaMitra needs your location to show nearby grazing lands.'**
  String get locationNeededLandsMsg;

  /// No description provided for @showUnavailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Show unavailable lands too'**
  String get showUnavailableLabel;

  /// No description provided for @waterAvailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Water Available'**
  String get waterAvailableLabel;

  /// No description provided for @shadeTreesLabel.
  ///
  /// In en, this message translates to:
  /// **'Shade / Trees'**
  String get shadeTreesLabel;

  /// No description provided for @fodderTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Fodder Type'**
  String get fodderTypeLabel;

  /// No description provided for @maxPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Max Price / Day / Animal'**
  String get maxPriceLabel;

  /// No description provided for @viewDetailsBtn.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetailsBtn;

  /// No description provided for @landDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Land Details'**
  String get landDetailsTitle;

  /// No description provided for @landNoLongerAvailableMsg.
  ///
  /// In en, this message translates to:
  /// **'This land is no longer available.'**
  String get landNoLongerAvailableMsg;

  /// No description provided for @farmerLabel.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get farmerLabel;

  /// No description provided for @areaLabel.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get areaLabel;

  /// No description provided for @maxAnimalsLabel.
  ///
  /// In en, this message translates to:
  /// **'Max Animals'**
  String get maxAnimalsLabel;

  /// No description provided for @perDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Per Day'**
  String get perDayLabel;

  /// No description provided for @aboutLandTitle.
  ///
  /// In en, this message translates to:
  /// **'About the Land'**
  String get aboutLandTitle;

  /// No description provided for @finalAmountNoteMsg.
  ///
  /// In en, this message translates to:
  /// **'Final amount depends on herd size and number of days.'**
  String get finalAmountNoteMsg;

  /// No description provided for @bookThisLandBtn.
  ///
  /// In en, this message translates to:
  /// **'Book This Land'**
  String get bookThisLandBtn;

  /// No description provided for @notAvailableForBookingMsg.
  ///
  /// In en, this message translates to:
  /// **'Not Available for Booking'**
  String get notAvailableForBookingMsg;

  /// No description provided for @sortTopRatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Top Rated'**
  String get sortTopRatedLabel;

  /// No description provided for @sortExperiencedLabel.
  ///
  /// In en, this message translates to:
  /// **'Experienced'**
  String get sortExperiencedLabel;

  /// No description provided for @noVetsFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'No Vets Found'**
  String get noVetsFoundTitle;

  /// No description provided for @locationNeededVetsMsg.
  ///
  /// In en, this message translates to:
  /// **'Enable location to find veterinarians near your herd.'**
  String get locationNeededVetsMsg;

  /// No description provided for @filterVetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter Vets'**
  String get filterVetsTitle;

  /// No description provided for @govtVetsOnlyLabel.
  ///
  /// In en, this message translates to:
  /// **'Government Vets Only'**
  String get govtVetsOnlyLabel;

  /// No description provided for @govtVetsOnlySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Subsidised / free services'**
  String get govtVetsOnlySubtitle;

  /// No description provided for @freeConsultationLabel.
  ///
  /// In en, this message translates to:
  /// **'Free Consultation'**
  String get freeConsultationLabel;

  /// No description provided for @minimumRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Minimum Rating'**
  String get minimumRatingLabel;

  /// No description provided for @specializationLabel.
  ///
  /// In en, this message translates to:
  /// **'Specialization'**
  String get specializationLabel;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @vetDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Vet Details'**
  String get vetDetailsTitle;

  /// No description provided for @vetProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Vet Profile'**
  String get vetProfileTitle;

  /// No description provided for @veterinarianNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Veterinarian Not Found'**
  String get veterinarianNotFoundTitle;

  /// No description provided for @profileRemovedMsg.
  ///
  /// In en, this message translates to:
  /// **'This profile may have been removed.'**
  String get profileRemovedMsg;

  /// No description provided for @verifiedVeterinarianMsg.
  ///
  /// In en, this message translates to:
  /// **'Verified Veterinarian'**
  String get verifiedVeterinarianMsg;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// No description provided for @languagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get languagesTitle;

  /// No description provided for @servicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get servicesTitle;

  /// No description provided for @galleryTitle.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get galleryTitle;

  /// No description provided for @contactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contactTitle;

  /// No description provided for @phoneCopiedMsg.
  ///
  /// In en, this message translates to:
  /// **'Phone number copied'**
  String get phoneCopiedMsg;

  /// No description provided for @vetContactCopiedMsg.
  ///
  /// In en, this message translates to:
  /// **'Vet contact copied to clipboard'**
  String get vetContactCopiedMsg;

  /// No description provided for @exploreMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Explore Map'**
  String get exploreMapTitle;

  /// No description provided for @locationNeededMapMsg.
  ///
  /// In en, this message translates to:
  /// **'Enable location to explore lands and vets on the map.'**
  String get locationNeededMapMsg;

  /// No description provided for @searchMapHint.
  ///
  /// In en, this message translates to:
  /// **'Search village, district, land or vet...'**
  String get searchMapHint;

  /// No description provided for @landsChipLabel.
  ///
  /// In en, this message translates to:
  /// **'Lands'**
  String get landsChipLabel;

  /// No description provided for @nothingFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing Found'**
  String get nothingFoundTitle;

  /// No description provided for @tryDifferentSearchMsg.
  ///
  /// In en, this message translates to:
  /// **'Try a different search, radius, or filter.'**
  String get tryDifferentSearchMsg;

  /// No description provided for @resultsWithinRadiusMsg.
  ///
  /// In en, this message translates to:
  /// **'{count} results within {radius} km'**
  String resultsWithinRadiusMsg(int count, int radius);

  /// No description provided for @alertsMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Alerts Map'**
  String get alertsMapTitle;

  /// No description provided for @locationNeededAlertsMapMsg.
  ///
  /// In en, this message translates to:
  /// **'Enable location to see disease alerts on the map.'**
  String get locationNeededAlertsMapMsg;

  /// No description provided for @noActiveAlertsRadiusMsg.
  ///
  /// In en, this message translates to:
  /// **'No active disease alerts within {radius} km'**
  String noActiveAlertsRadiusMsg(int radius);

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// No description provided for @searchEverythingHint.
  ///
  /// In en, this message translates to:
  /// **'Search lands, vets, alerts, villages, districts...'**
  String get searchEverythingHint;

  /// No description provided for @searchEverythingTitle.
  ///
  /// In en, this message translates to:
  /// **'Search Everything'**
  String get searchEverythingTitle;

  /// No description provided for @searchEverythingDesc.
  ///
  /// In en, this message translates to:
  /// **'Find nearby lands, vets, disease alerts, villages, and districts — all in one place.'**
  String get searchEverythingDesc;

  /// No description provided for @locationNeededSearchMsg.
  ///
  /// In en, this message translates to:
  /// **'Enable location to search nearby lands, vets, and alerts.'**
  String get locationNeededSearchMsg;

  /// No description provided for @noResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No Results'**
  String get noResultsTitle;

  /// No description provided for @noResultsMsg.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches \"{query}\". Try a different search.'**
  String noResultsMsg(String query);

  /// No description provided for @categoryLandLabel.
  ///
  /// In en, this message translates to:
  /// **'Land'**
  String get categoryLandLabel;

  /// No description provided for @categoryVetLabel.
  ///
  /// In en, this message translates to:
  /// **'Vet'**
  String get categoryVetLabel;

  /// No description provided for @categoryAlertLabel.
  ///
  /// In en, this message translates to:
  /// **'Alert'**
  String get categoryAlertLabel;

  /// No description provided for @categoryVillageLabel.
  ///
  /// In en, this message translates to:
  /// **'Village'**
  String get categoryVillageLabel;

  /// No description provided for @categoryDistrictLabel.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get categoryDistrictLabel;

  /// No description provided for @diseaseAlertsTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Disease Alerts'**
  String get diseaseAlertsTabLabel;

  /// No description provided for @advisoryTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Advisory'**
  String get advisoryTabLabel;

  /// No description provided for @reportBtn.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportBtn;

  /// No description provided for @exploreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Disease alerts, advisory & farming tips'**
  String get exploreSubtitle;

  /// No description provided for @searchAdvisoryHint.
  ///
  /// In en, this message translates to:
  /// **'Search advisory tips...'**
  String get searchAdvisoryHint;

  /// No description provided for @allCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allCategoryLabel;

  /// No description provided for @noTipsYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No Tips Yet'**
  String get noTipsYetTitle;

  /// No description provided for @noTipsYetMsg.
  ///
  /// In en, this message translates to:
  /// **'Advisory tips for this category are coming soon.'**
  String get noTipsYetMsg;

  /// No description provided for @categoryHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get categoryHealth;

  /// No description provided for @categoryNutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get categoryNutrition;

  /// No description provided for @categoryFodder.
  ///
  /// In en, this message translates to:
  /// **'Fodder'**
  String get categoryFodder;

  /// No description provided for @categoryGrazing.
  ///
  /// In en, this message translates to:
  /// **'Grazing'**
  String get categoryGrazing;

  /// No description provided for @categoryFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get categoryFinance;

  /// No description provided for @categoryWeather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get categoryWeather;

  /// No description provided for @searchDiseaseAlertsHint.
  ///
  /// In en, this message translates to:
  /// **'Search disease alerts...'**
  String get searchDiseaseAlertsHint;

  /// No description provided for @noActiveAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'No Active Alerts'**
  String get noActiveAlertsTitle;

  /// No description provided for @noActiveAlertsMsg.
  ///
  /// In en, this message translates to:
  /// **'No disease alerts reported in your area. Stay vigilant!'**
  String get noActiveAlertsMsg;

  /// No description provided for @noMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'No Matches'**
  String get noMatchesTitle;

  /// No description provided for @noMatchesMsg.
  ///
  /// In en, this message translates to:
  /// **'No alerts match \"{query}\". Try a different search.'**
  String noMatchesMsg(String query);

  /// No description provided for @locationNeededAlertsMsg.
  ///
  /// In en, this message translates to:
  /// **'Enable location to see disease alerts near you.'**
  String get locationNeededAlertsMsg;

  /// No description provided for @searchAlertDashboardHint.
  ///
  /// In en, this message translates to:
  /// **'Search disease, title, village...'**
  String get searchAlertDashboardHint;

  /// No description provided for @noDistrictYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No District Yet'**
  String get noDistrictYetTitle;

  /// No description provided for @noDistrictYetMsg.
  ///
  /// In en, this message translates to:
  /// **'Set a district in Filters, or wait for nearby alerts to suggest one.'**
  String get noDistrictYetMsg;

  /// No description provided for @noUrgentAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'No Urgent Alerts'**
  String get noUrgentAlertsTitle;

  /// No description provided for @noAlertsFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'No Alerts Found'**
  String get noAlertsFoundTitle;

  /// No description provided for @tryRemovingFiltersMsg.
  ///
  /// In en, this message translates to:
  /// **'Try removing some filters or the search text.'**
  String get tryRemovingFiltersMsg;

  /// No description provided for @noActiveAlertsInDistrictMsg.
  ///
  /// In en, this message translates to:
  /// **'No active alerts reported in {district}.'**
  String noActiveAlertsInDistrictMsg(String district);

  /// No description provided for @tabNearbyLabel.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get tabNearbyLabel;

  /// No description provided for @tabDistrictLabel.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get tabDistrictLabel;

  /// No description provided for @tabActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get tabActiveLabel;

  /// No description provided for @tabRecentLabel.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get tabRecentLabel;

  /// No description provided for @severityCriticalLabel.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get severityCriticalLabel;

  /// No description provided for @severityHighLabel.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get severityHighLabel;

  /// No description provided for @severityMediumLabel.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get severityMediumLabel;

  /// No description provided for @severityLowLabel.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get severityLowLabel;

  /// No description provided for @speciesSheepLabel.
  ///
  /// In en, this message translates to:
  /// **'Sheep'**
  String get speciesSheepLabel;

  /// No description provided for @speciesGoatLabel.
  ///
  /// In en, this message translates to:
  /// **'Goat'**
  String get speciesGoatLabel;

  /// No description provided for @speciesCattleLabel.
  ///
  /// In en, this message translates to:
  /// **'Cattle'**
  String get speciesCattleLabel;

  /// No description provided for @speciesAllAnimalsLabel.
  ///
  /// In en, this message translates to:
  /// **'All Animals'**
  String get speciesAllAnimalsLabel;

  /// No description provided for @radiusLabel.
  ///
  /// In en, this message translates to:
  /// **'Radius'**
  String get radiusLabel;

  /// No description provided for @severityLabel.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get severityLabel;

  /// No description provided for @affectedAnimalsLabel.
  ///
  /// In en, this message translates to:
  /// **'Affected Animals'**
  String get affectedAnimalsLabel;

  /// No description provided for @issuedDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Issued Date'**
  String get issuedDateLabel;

  /// No description provided for @issuedFromBtn.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get issuedFromBtn;

  /// No description provided for @issuedUntilBtn.
  ///
  /// In en, this message translates to:
  /// **'Until'**
  String get issuedUntilBtn;

  /// No description provided for @issuedFromHelp.
  ///
  /// In en, this message translates to:
  /// **'Issued from'**
  String get issuedFromHelp;

  /// No description provided for @issuedUntilHelp.
  ///
  /// In en, this message translates to:
  /// **'Issued until'**
  String get issuedUntilHelp;

  /// No description provided for @alertDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Alert Details'**
  String get alertDetailsTitle;

  /// No description provided for @alertNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Alert Not Found'**
  String get alertNotFoundTitle;

  /// No description provided for @alertRemovedMsg.
  ///
  /// In en, this message translates to:
  /// **'This alert may have expired or been removed.'**
  String get alertRemovedMsg;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @symptomsLabel.
  ///
  /// In en, this message translates to:
  /// **'Symptoms'**
  String get symptomsLabel;

  /// No description provided for @treatmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Treatment'**
  String get treatmentLabel;

  /// No description provided for @preventionLabel.
  ///
  /// In en, this message translates to:
  /// **'Prevention'**
  String get preventionLabel;

  /// No description provided for @govtAdvisoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Government Advisory / Source'**
  String get govtAdvisoryLabel;

  /// No description provided for @nearbyVeterinarianTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby Veterinarian'**
  String get nearbyVeterinarianTitle;

  /// No description provided for @reportSimilarCaseBtn.
  ///
  /// In en, this message translates to:
  /// **'Report Similar Case'**
  String get reportSimilarCaseBtn;

  /// No description provided for @noVetsNearAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'No Vets Found Nearby'**
  String get noVetsNearAlertTitle;

  /// No description provided for @noVetsNearAlertMsg.
  ///
  /// In en, this message translates to:
  /// **'No registered veterinarians within 50 km of this alert.'**
  String get noVetsNearAlertMsg;

  /// No description provided for @sharedViaAppMsg.
  ///
  /// In en, this message translates to:
  /// **'Shared via JeevaMitra'**
  String get sharedViaAppMsg;

  /// No description provided for @reportAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'Report Disease Alert'**
  String get reportAlertTitle;

  /// No description provided for @diseaseInfoSection.
  ///
  /// In en, this message translates to:
  /// **'Disease Information'**
  String get diseaseInfoSection;

  /// No description provided for @alertLocationSection.
  ///
  /// In en, this message translates to:
  /// **'Alert Location'**
  String get alertLocationSection;

  /// No description provided for @alertDetailsSection.
  ///
  /// In en, this message translates to:
  /// **'Alert Details'**
  String get alertDetailsSection;

  /// No description provided for @sourceValiditySection.
  ///
  /// In en, this message translates to:
  /// **'Source & Validity'**
  String get sourceValiditySection;

  /// No description provided for @diseaseNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Disease Name *'**
  String get diseaseNameLabel;

  /// No description provided for @diseaseNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Foot & Mouth Disease'**
  String get diseaseNameHint;

  /// No description provided for @diseaseNameFieldName.
  ///
  /// In en, this message translates to:
  /// **'Disease name'**
  String get diseaseNameFieldName;

  /// No description provided for @alertTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Alert Title *'**
  String get alertTitleLabel;

  /// No description provided for @alertTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. FMD Alert in Guntur'**
  String get alertTitleHint;

  /// No description provided for @titleFieldName.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleFieldName;

  /// No description provided for @districtFieldName.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get districtFieldName;

  /// No description provided for @stateLabel.
  ///
  /// In en, this message translates to:
  /// **'State *'**
  String get stateLabel;

  /// No description provided for @descriptionFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Description *'**
  String get descriptionFieldLabel;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the symptoms and spread pattern…'**
  String get descriptionHint;

  /// No description provided for @descriptionFieldName.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionFieldName;

  /// No description provided for @preventionTipsLabel.
  ///
  /// In en, this message translates to:
  /// **'Prevention Tips (optional)'**
  String get preventionTipsLabel;

  /// No description provided for @preventionHint.
  ///
  /// In en, this message translates to:
  /// **'What farmers can do to protect their animals…'**
  String get preventionHint;

  /// No description provided for @treatmentFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Treatment (optional)'**
  String get treatmentFieldLabel;

  /// No description provided for @treatmentHint.
  ///
  /// In en, this message translates to:
  /// **'Recommended treatment or medication…'**
  String get treatmentHint;

  /// No description provided for @vetContactLabel.
  ///
  /// In en, this message translates to:
  /// **'Vet Contact Number (optional)'**
  String get vetContactLabel;

  /// No description provided for @vetContactHint.
  ///
  /// In en, this message translates to:
  /// **'+91 98765 43210'**
  String get vetContactHint;

  /// No description provided for @sourceAuthorityLabel.
  ///
  /// In en, this message translates to:
  /// **'Source Authority *'**
  String get sourceAuthorityLabel;

  /// No description provided for @sourceAuthorityHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Animal Husbandry Dept., Farmer Community'**
  String get sourceAuthorityHint;

  /// No description provided for @sourceAuthorityFieldName.
  ///
  /// In en, this message translates to:
  /// **'Source authority'**
  String get sourceAuthorityFieldName;

  /// No description provided for @alertValidUntilLabel.
  ///
  /// In en, this message translates to:
  /// **'Alert Valid Until'**
  String get alertValidUntilLabel;

  /// No description provided for @alertValidUntilHelp.
  ///
  /// In en, this message translates to:
  /// **'Alert valid until'**
  String get alertValidUntilHelp;

  /// No description provided for @defaultValidityMsg.
  ///
  /// In en, this message translates to:
  /// **'30 days from today (default)'**
  String get defaultValidityMsg;

  /// No description provided for @submitAlertBtn.
  ///
  /// In en, this message translates to:
  /// **'Submit Alert'**
  String get submitAlertBtn;

  /// No description provided for @setLocationMsg.
  ///
  /// In en, this message translates to:
  /// **'Please set the alert location'**
  String get setLocationMsg;

  /// No description provided for @alertReportedMsg.
  ///
  /// In en, this message translates to:
  /// **'Alert reported. Thank you!'**
  String get alertReportedMsg;

  /// No description provided for @submitFailedMsg.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit. Please try again.'**
  String get submitFailedMsg;

  /// No description provided for @noLocationSetMsg.
  ///
  /// In en, this message translates to:
  /// **'No location set'**
  String get noLocationSetMsg;

  /// No description provided for @updateBtn.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateBtn;

  /// No description provided for @detectBtn.
  ///
  /// In en, this message translates to:
  /// **'Detect'**
  String get detectBtn;

  /// No description provided for @adjustOnMapBtn.
  ///
  /// In en, this message translates to:
  /// **'Adjust on Map'**
  String get adjustOnMapBtn;

  /// No description provided for @pickOnMapBtn.
  ///
  /// In en, this message translates to:
  /// **'Pick on Map'**
  String get pickOnMapBtn;

  /// No description provided for @daysAgoMsg.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String daysAgoMsg(int count);

  /// No description provided for @hoursAgoMsg.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String hoursAgoMsg(int count);

  /// No description provided for @minutesAgoMsg.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String minutesAgoMsg(int count);

  /// No description provided for @readMoreBtn.
  ///
  /// In en, this message translates to:
  /// **'Read More'**
  String get readMoreBtn;

  /// No description provided for @perDayAnimalSuffix.
  ///
  /// In en, this message translates to:
  /// **' /day/animal'**
  String get perDayAnimalSuffix;

  /// No description provided for @yearsExpMsg.
  ///
  /// In en, this message translates to:
  /// **'{count} yrs exp'**
  String yearsExpMsg(int count);

  /// No description provided for @ratingCountMsg.
  ///
  /// In en, this message translates to:
  /// **'{rating} ({count})'**
  String ratingCountMsg(String rating, int count);

  /// No description provided for @sortByLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort: {mode}'**
  String sortByLabel(String mode);

  /// No description provided for @areaAcresLabel.
  ///
  /// In en, this message translates to:
  /// **'Area (acres)'**
  String get areaAcresLabel;

  /// No description provided for @kmChipLabel.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String kmChipLabel(int km);

  /// No description provided for @noAvailableLandRadiusMsg.
  ///
  /// In en, this message translates to:
  /// **'No available grazing land within {radius} km.'**
  String noAvailableLandRadiusMsg(int radius);

  /// No description provided for @noVetsFoundRadiusMsg.
  ///
  /// In en, this message translates to:
  /// **'No veterinarians found within {radius} km.'**
  String noVetsFoundRadiusMsg(int radius);

  /// No description provided for @perAnimalPerDaySuffix.
  ///
  /// In en, this message translates to:
  /// **' per animal per day. '**
  String get perAnimalPerDaySuffix;

  /// No description provided for @minimumExperienceLabel.
  ///
  /// In en, this message translates to:
  /// **'Minimum Experience (years)'**
  String get minimumExperienceLabel;

  /// No description provided for @ratingStarsLabel.
  ///
  /// In en, this message translates to:
  /// **'{rating} ★'**
  String ratingStarsLabel(String rating);

  /// No description provided for @yearsShortLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} yrs'**
  String yearsShortLabel(int count);

  /// No description provided for @feeSuffix.
  ///
  /// In en, this message translates to:
  /// **' Fee'**
  String get feeSuffix;

  /// No description provided for @ratingStarCountMsg.
  ///
  /// In en, this message translates to:
  /// **'{rating} ★ ({count})'**
  String ratingStarCountMsg(String rating, int count);

  /// No description provided for @resultsHereMsg.
  ///
  /// In en, this message translates to:
  /// **'{count} results here'**
  String resultsHereMsg(int count);

  /// No description provided for @diseaseAlertFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Disease Alert'**
  String get diseaseAlertFallbackTitle;

  /// No description provided for @alertsHereMsg.
  ///
  /// In en, this message translates to:
  /// **'{count} alerts here'**
  String alertsHereMsg(int count);

  /// No description provided for @issuedDateMsg.
  ///
  /// In en, this message translates to:
  /// **'Issued {date}'**
  String issuedDateMsg(String date);

  /// No description provided for @validUntilDateMsg.
  ///
  /// In en, this message translates to:
  /// **'Valid until {date}'**
  String validUntilDateMsg(String date);

  /// No description provided for @severitySuffixMsg.
  ///
  /// In en, this message translates to:
  /// **'{severity} severity'**
  String severitySuffixMsg(String severity);

  /// No description provided for @locationLineMsg.
  ///
  /// In en, this message translates to:
  /// **'Location: {where}'**
  String locationLineMsg(String where);

  /// No description provided for @symptomsFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Symptoms (optional)'**
  String get symptomsFieldLabel;

  /// No description provided for @symptomsHint.
  ///
  /// In en, this message translates to:
  /// **'What signs to look for in affected animals…'**
  String get symptomsHint;

  /// No description provided for @stateFieldName.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get stateFieldName;
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
      <String>['en', 'hi', 'te'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
