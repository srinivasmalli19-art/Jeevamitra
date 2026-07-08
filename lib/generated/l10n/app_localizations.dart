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
