// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'JeevaMitra';

  @override
  String get tagline => 'Your Farming Companion';

  @override
  String get continueBtn => 'Continue';

  @override
  String get skipBtn => 'Skip';

  @override
  String get backBtn => 'Back';

  @override
  String get saveBtn => 'Save';

  @override
  String get cancelBtn => 'Cancel';

  @override
  String get confirmBtn => 'Confirm';

  @override
  String get deleteBtn => 'Delete';

  @override
  String get editBtn => 'Edit';

  @override
  String get retryBtn => 'Try Again';

  @override
  String get closeBtn => 'Close';

  @override
  String get doneBtn => 'Done';

  @override
  String get nextBtn => 'Next';

  @override
  String get yesBtn => 'Yes';

  @override
  String get noBtn => 'No';

  @override
  String get searchHint => 'Search...';

  @override
  String get loadingMsg => 'Loading...';

  @override
  String get noInternetMsg => 'No internet connection';

  @override
  String get errorMsg => 'Something went wrong';

  @override
  String get noDataMsg => 'No data found';

  @override
  String get selectLanguage => 'Choose Language';

  @override
  String get languageHint => 'Select your preferred language';

  @override
  String get onboardTitle1 => 'List Your Farm Land';

  @override
  String get onboardBody1 =>
      'Farmers can register their land and make it available for shepherds to graze.';

  @override
  String get onboardTitle2 => 'Find Grazing Land Nearby';

  @override
  String get onboardBody2 =>
      'Search available grazing land near you and book directly with the farmer.';

  @override
  String get onboardTitle3 => 'Vets Near You';

  @override
  String get onboardBody3 =>
      'Find nearby veterinarians for emergencies with a single tap.';

  @override
  String get mobileNumber => 'Mobile Number';

  @override
  String get mobileNumberHint => 'Enter 10-digit mobile number';

  @override
  String get sendOtp => 'Send OTP';

  @override
  String get enterOtp => 'Enter OTP';

  @override
  String get otpHint => '6-digit OTP';

  @override
  String get verifyOtp => 'Verify OTP';

  @override
  String get resendOtp => 'Resend OTP';

  @override
  String resendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String otpSentTo(String phone) {
    return 'OTP sent to $phone';
  }

  @override
  String get selectRole => 'I am a...';

  @override
  String get roleFarmer => 'Farmer';

  @override
  String get roleFarmerDesc => 'I have land and want to offer it for grazing';

  @override
  String get roleShepherd => 'Shepherd';

  @override
  String get roleShepherdDesc => 'I have animals and need grazing land';

  @override
  String get yourName => 'Your Name';

  @override
  String get yourVillage => 'Village / Town';

  @override
  String get yourDistrict => 'District';

  @override
  String get completeProfile => 'Complete Profile';

  @override
  String get farmerDashboard => 'Dashboard';

  @override
  String get myLands => 'My Lands';

  @override
  String get bookings => 'Bookings';

  @override
  String get explore => 'Explore';

  @override
  String get profile => 'Profile';

  @override
  String get shepherdDashboard => 'Dashboard';

  @override
  String get discover => 'Discover';

  @override
  String get vets => 'Vets';

  @override
  String get addLand => 'Add Land';

  @override
  String get landTitle => 'Land Title';

  @override
  String get landArea => 'Land Area';

  @override
  String get pricePerDay => 'Price per Day / Animal';

  @override
  String get fodderTypes => 'Fodder Available';

  @override
  String get amenities => 'Amenities';

  @override
  String get water => 'Water';

  @override
  String get shade => 'Shade';

  @override
  String get fencing => 'Fencing';

  @override
  String get vetNearby => 'Vet Nearby';

  @override
  String get bookNow => 'Book Now';

  @override
  String get checkIn => 'Check In';

  @override
  String get checkOut => 'Check Out';

  @override
  String get animalCount => 'Number of Animals';

  @override
  String get totalAmount => 'Total Amount';

  @override
  String get advanceAmount => 'Advance';

  @override
  String get bookingPending => 'Pending';

  @override
  String get bookingConfirmed => 'Confirmed';

  @override
  String get bookingActive => 'Active';

  @override
  String get bookingCompleted => 'Completed';

  @override
  String get bookingCancelled => 'Cancelled';

  @override
  String get nearbyVets => 'Vets Nearby';

  @override
  String get govtVet => 'Govt. Vet';

  @override
  String get available24x7 => '24×7 Available';

  @override
  String get consultationFee => 'Consultation Fee';

  @override
  String get free => 'Free';

  @override
  String get callVet => 'Call Vet';

  @override
  String get whatsappVet => 'WhatsApp';

  @override
  String get emergency => 'Emergency';

  @override
  String get emergencyCallVet => 'Call Nearest Vet';

  @override
  String get emergencyHelpline => 'Helpline 1962';

  @override
  String get voiceInputHint => 'Tap mic to speak';

  @override
  String get listeningMsg => 'Listening...';

  @override
  String get voiceNotSupported => 'Voice not supported on this device';

  @override
  String get rateExperience => 'Rate your experience';

  @override
  String get writeReview => 'Write a review';

  @override
  String get submitReview => 'Submit Review';

  @override
  String get notifications => 'Notifications';

  @override
  String get noNotifications => 'No notifications yet';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirm => 'Are you sure you want to logout?';

  @override
  String distanceKm(String km) {
    return '$km km away';
  }

  @override
  String perDayPerAnimal(String price) {
    return '₹$price/day/animal';
  }

  @override
  String get availableNow => 'Available';

  @override
  String get notAvailable => 'Not Available';

  @override
  String acres(String area) {
    return '$area Acres';
  }
}
