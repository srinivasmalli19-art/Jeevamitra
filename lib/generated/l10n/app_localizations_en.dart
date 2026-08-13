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
  String get historyLabel => 'History';

  @override
  String get rejectBtn => 'Reject';

  @override
  String get acceptBtn => 'Accept';

  @override
  String animalsCountLabel(int count) {
    return '$count animals';
  }

  @override
  String get noPendingRequestsTitle => 'No Pending Requests';

  @override
  String get noPendingRequestsSubtitle =>
      'New booking requests from shepherds will appear here';

  @override
  String get noActiveBookingsTitle => 'No Active Bookings';

  @override
  String get noActiveBookingsSubtitle =>
      'Confirmed and ongoing bookings will appear here';

  @override
  String get noHistoryYetTitle => 'No History Yet';

  @override
  String get noHistoryYetSubtitle =>
      'Completed and cancelled bookings will appear here';

  @override
  String get bookLandToSeeBookingsMsg =>
      'Book a grazing land from Discover to see your bookings here';

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
  String get noNotificationsSubtitle =>
      'Booking updates and alerts will appear here';

  @override
  String get markAllReadBtn => 'Mark all as read';

  @override
  String get todayLabel => 'Today';

  @override
  String get yesterdayLabel => 'Yesterday';

  @override
  String get thisWeekLabel => 'This week';

  @override
  String get earlierLabel => 'Earlier';

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
  String distanceMetersAway(int m) {
    return '$m m away';
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

  @override
  String get mobileNumberSubtitle => 'Enter your mobile number to receive OTP';

  @override
  String get termsAgreement =>
      'By continuing, you agree to our Terms & Privacy Policy';

  @override
  String get otpNotReceivedMsg => 'Didn\'t receive OTP?';

  @override
  String get selectRoleTitle => 'Who are you?';

  @override
  String get genericErrorRetryMsg => 'Something went wrong. Please try again.';

  @override
  String get invalidOtpMsg => 'Invalid OTP. Please try again.';

  @override
  String get genericSaveFailedMsg => 'Failed to save. Please try again.';

  @override
  String get completeProfileSubtitle => 'Complete your profile to get started';

  @override
  String get yourNameHint => 'Enter your full name';

  @override
  String get yourVillageHint => 'Your village or town name';

  @override
  String get saveContinueBtn => 'Save & Continue';

  @override
  String get saveProfileFailedMsg =>
      'Could not save your profile. Please try again.';

  @override
  String get getStartedBtn => 'Get Started';

  @override
  String get homeTab => 'Home';

  @override
  String greetingName(String name) {
    return 'Hello, $name!';
  }

  @override
  String get voiceAssistantTooltip => 'Voice Assistant';

  @override
  String get alertsLabel => 'Alerts';

  @override
  String get overviewLabel => 'Overview';

  @override
  String get earningsLabel => 'Earnings';

  @override
  String get recentBookingsLabel => 'Recent Bookings';

  @override
  String get viewAllBtn => 'View all';

  @override
  String get noBookingsYetTitle => 'No bookings yet';

  @override
  String get noBookingsYetSubtitle =>
      'Bookings from shepherds will appear here';

  @override
  String pendingApprovalMsg(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bookings awaiting your approval',
      one: '1 booking awaiting your approval',
    );
    return '$_temp0';
  }

  @override
  String get tapToReviewMsg => 'Tap to review and accept';

  @override
  String bookingSummaryMsg(int count, String date, String amount) {
    return '$count animals · $date · ₹$amount';
  }

  @override
  String get upcomingLabel => 'Upcoming';

  @override
  String get tripsDoneLabel => 'Trips Done';

  @override
  String get spentLabel => 'Spent';

  @override
  String get findLandLabel => 'Find Land';

  @override
  String get findVetLabel => 'Find Vet';

  @override
  String get myTripsLabel => 'My Trips';

  @override
  String get noTripsYetTitle => 'No trips yet';

  @override
  String get noTripsYetSubtitle => 'Book a land to start your first trip';

  @override
  String get discoverLandsBtn => 'Discover Lands';

  @override
  String activeTripMsg(String title) {
    return 'Active trip: $title';
  }

  @override
  String tripEndsMsg(int count, String date) {
    return '$count animals · ends $date';
  }

  @override
  String get editProfileTitle => 'Edit Profile';

  @override
  String get profileInfoLabel => 'Profile Info';

  @override
  String get accountLabel => 'Account';

  @override
  String get deleteAccountTitle => 'Delete Account';

  @override
  String get deleteAccountBody =>
      'This will permanently delete your account and all your data. This cannot be undone.';

  @override
  String get deleteAccountSubtitle => 'Permanently removes all your data';

  @override
  String get landsLabel => 'Lands';

  @override
  String get totalTripsLabel => 'Total Trips';

  @override
  String get phoneRequiredMsg => 'Phone number required';

  @override
  String get phoneInvalidMsg => 'Enter valid 10-digit mobile number';

  @override
  String get nameRequiredMsg => 'Name required';

  @override
  String get nameTooShortMsg => 'Name must be at least 2 characters';

  @override
  String get nameTooLongMsg => 'Name too long';

  @override
  String get villageRequiredMsg => 'Village/town required';

  @override
  String get villageInvalidMsg => 'Enter a valid location';

  @override
  String get otpRequiredMsg => 'OTP required';

  @override
  String get otpInvalidMsg => 'Enter 6-digit OTP';

  @override
  String get districtRequiredMsg => 'District required';

  @override
  String get clearBtn => 'Clear';

  @override
  String get filtersLabel => 'Filters';

  @override
  String get resetBtn => 'Reset';

  @override
  String get applyFiltersBtn => 'Apply Filters';

  @override
  String get anyLabel => 'Any';

  @override
  String get villageFieldLabel => 'Village';

  @override
  String get locationRequiredTitle => 'Location Required';

  @override
  String get locationErrorTitle => 'Location Error';

  @override
  String get couldNotGetLocationMsg => 'Could not get your location.';

  @override
  String get enableLocationBtn => 'Enable Location';

  @override
  String get couldNotOpenMapsMsg => 'Could not open maps';

  @override
  String get couldNotOpenDialerMsg => 'Could not open dialer';

  @override
  String get couldNotOpenLinkMsg => 'Could not open this link';

  @override
  String get whatsappNotInstalledMsg => 'WhatsApp not installed';

  @override
  String get navigateBtn => 'Navigate';

  @override
  String get callBtn => 'Call';

  @override
  String get bookBtn => 'Book';

  @override
  String get viewProfileBtn => 'View Profile';

  @override
  String get justNowMsg => 'Just now';

  @override
  String get shareTooltip => 'Share';

  @override
  String get searchEverythingTooltip => 'Search Everything';

  @override
  String get mapViewTooltip => 'Map View';

  @override
  String get availableTodayLabel => 'Available Today';

  @override
  String get sortClosestLabel => 'Closest';

  @override
  String get sortNewestLabel => 'Newest';

  @override
  String get clearFiltersBtn => 'Clear Filters';

  @override
  String get tryFewerFiltersMsg =>
      'Try removing some filters or increasing the radius.';

  @override
  String get noLandsFoundTitle => 'No Lands Found';

  @override
  String get noLandsYetTitle => 'No lands yet';

  @override
  String get noLandsYetSubtitle =>
      'Add your farmland to start receiving bookings from shepherds';

  @override
  String get locationNeededLandsMsg =>
      'JeevaMitra needs your location to show nearby grazing lands.';

  @override
  String get showUnavailableLabel => 'Show unavailable lands too';

  @override
  String get waterAvailableLabel => 'Water Available';

  @override
  String get shadeTreesLabel => 'Shade / Trees';

  @override
  String get fodderTypeLabel => 'Fodder Type';

  @override
  String get maxPriceLabel => 'Max Price / Day / Animal';

  @override
  String get viewDetailsBtn => 'View Details';

  @override
  String get landDetailsTitle => 'Land Details';

  @override
  String get landNoLongerAvailableMsg => 'This land is no longer available.';

  @override
  String get farmerLabel => 'Farmer';

  @override
  String get areaLabel => 'Area';

  @override
  String get maxAnimalsLabel => 'Max Animals';

  @override
  String get perDayLabel => 'Per Day';

  @override
  String get aboutLandTitle => 'About the Land';

  @override
  String get finalAmountNoteMsg =>
      'Final amount depends on herd size and number of days.';

  @override
  String get bookThisLandBtn => 'Book This Land';

  @override
  String get notAvailableForBookingMsg => 'Not Available for Booking';

  @override
  String get sortTopRatedLabel => 'Top Rated';

  @override
  String get sortExperiencedLabel => 'Experienced';

  @override
  String get noVetsFoundTitle => 'No Vets Found';

  @override
  String get locationNeededVetsMsg =>
      'Enable location to find veterinarians near your herd.';

  @override
  String get filterVetsTitle => 'Filter Vets';

  @override
  String get govtVetsOnlyLabel => 'Government Vets Only';

  @override
  String get govtVetsOnlySubtitle => 'Subsidised / free services';

  @override
  String get freeConsultationLabel => 'Free Consultation';

  @override
  String get minimumRatingLabel => 'Minimum Rating';

  @override
  String get specializationLabel => 'Specialization';

  @override
  String get languageLabel => 'Language';

  @override
  String get vetDetailsTitle => 'Vet Details';

  @override
  String get vetProfileTitle => 'Vet Profile';

  @override
  String get veterinarianNotFoundTitle => 'Veterinarian Not Found';

  @override
  String get profileRemovedMsg => 'This profile may have been removed.';

  @override
  String get verifiedVeterinarianMsg => 'Verified Veterinarian';

  @override
  String get locationLabel => 'Location';

  @override
  String get languagesTitle => 'Languages';

  @override
  String get servicesTitle => 'Services';

  @override
  String get galleryTitle => 'Gallery';

  @override
  String get contactTitle => 'Contact';

  @override
  String get phoneCopiedMsg => 'Phone number copied';

  @override
  String get vetContactCopiedMsg => 'Vet contact copied to clipboard';

  @override
  String get exploreMapTitle => 'Explore Map';

  @override
  String get locationNeededMapMsg =>
      'Enable location to explore lands and vets on the map.';

  @override
  String get searchMapHint => 'Search village, district, land or vet...';

  @override
  String get landsChipLabel => 'Lands';

  @override
  String get nothingFoundTitle => 'Nothing Found';

  @override
  String get tryDifferentSearchMsg =>
      'Try a different search, radius, or filter.';

  @override
  String resultsWithinRadiusMsg(int count, int radius) {
    return '$count results within $radius km';
  }

  @override
  String get alertsMapTitle => 'Alerts Map';

  @override
  String get locationNeededAlertsMapMsg =>
      'Enable location to see disease alerts on the map.';

  @override
  String noActiveAlertsRadiusMsg(int radius) {
    return 'No active disease alerts within $radius km';
  }

  @override
  String get searchTitle => 'Search';

  @override
  String get searchEverythingHint =>
      'Search lands, vets, alerts, villages, districts...';

  @override
  String get searchEverythingTitle => 'Search Everything';

  @override
  String get searchEverythingDesc =>
      'Find nearby lands, vets, disease alerts, villages, and districts — all in one place.';

  @override
  String get locationNeededSearchMsg =>
      'Enable location to search nearby lands, vets, and alerts.';

  @override
  String get noResultsTitle => 'No Results';

  @override
  String noResultsMsg(String query) {
    return 'Nothing matches \"$query\". Try a different search.';
  }

  @override
  String get categoryLandLabel => 'Land';

  @override
  String get categoryVetLabel => 'Vet';

  @override
  String get categoryAlertLabel => 'Alert';

  @override
  String get categoryVillageLabel => 'Village';

  @override
  String get categoryDistrictLabel => 'District';

  @override
  String get diseaseAlertsTabLabel => 'Disease Alerts';

  @override
  String get advisoryTabLabel => 'Advisory';

  @override
  String get reportBtn => 'Report';

  @override
  String get exploreSubtitle => 'Disease alerts, advisory & farming tips';

  @override
  String get searchAdvisoryHint => 'Search advisory tips...';

  @override
  String get allCategoryLabel => 'All';

  @override
  String get noTipsYetTitle => 'No Tips Yet';

  @override
  String get noTipsYetMsg => 'Advisory tips for this category are coming soon.';

  @override
  String get categoryHealth => 'Health';

  @override
  String get categoryNutrition => 'Nutrition';

  @override
  String get categoryFodder => 'Fodder';

  @override
  String get categoryGrazing => 'Grazing';

  @override
  String get categoryFinance => 'Finance';

  @override
  String get categoryWeather => 'Weather';

  @override
  String get searchDiseaseAlertsHint => 'Search disease alerts...';

  @override
  String get noActiveAlertsTitle => 'No Active Alerts';

  @override
  String get noActiveAlertsMsg =>
      'No disease alerts reported in your area. Stay vigilant!';

  @override
  String get noMatchesTitle => 'No Matches';

  @override
  String noMatchesMsg(String query) {
    return 'No alerts match \"$query\". Try a different search.';
  }

  @override
  String get locationNeededAlertsMsg =>
      'Enable location to see disease alerts near you.';

  @override
  String get searchAlertDashboardHint => 'Search disease, title, village...';

  @override
  String get noDistrictYetTitle => 'No District Yet';

  @override
  String get noDistrictYetMsg =>
      'Set a district in Filters, or wait for nearby alerts to suggest one.';

  @override
  String get noUrgentAlertsTitle => 'No Urgent Alerts';

  @override
  String get noAlertsFoundTitle => 'No Alerts Found';

  @override
  String get tryRemovingFiltersMsg =>
      'Try removing some filters or the search text.';

  @override
  String noActiveAlertsInDistrictMsg(String district) {
    return 'No active alerts reported in $district.';
  }

  @override
  String get tabNearbyLabel => 'Nearby';

  @override
  String get tabDistrictLabel => 'District';

  @override
  String get tabActiveLabel => 'Active';

  @override
  String get tabRecentLabel => 'Recent';

  @override
  String get severityCriticalLabel => 'Critical';

  @override
  String get severityHighLabel => 'High';

  @override
  String get severityMediumLabel => 'Medium';

  @override
  String get severityLowLabel => 'Low';

  @override
  String get speciesSheepLabel => 'Sheep';

  @override
  String get speciesGoatLabel => 'Goat';

  @override
  String get speciesCattleLabel => 'Cattle';

  @override
  String get speciesAllAnimalsLabel => 'All Animals';

  @override
  String get radiusLabel => 'Radius';

  @override
  String get severityLabel => 'Severity';

  @override
  String get affectedAnimalsLabel => 'Affected Animals';

  @override
  String get issuedDateLabel => 'Issued Date';

  @override
  String get issuedFromBtn => 'From';

  @override
  String get issuedUntilBtn => 'Until';

  @override
  String get issuedFromHelp => 'Issued from';

  @override
  String get issuedUntilHelp => 'Issued until';

  @override
  String get alertDetailsTitle => 'Alert Details';

  @override
  String get alertNotFoundTitle => 'Alert Not Found';

  @override
  String get alertRemovedMsg => 'This alert may have expired or been removed.';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get symptomsLabel => 'Symptoms';

  @override
  String get treatmentLabel => 'Treatment';

  @override
  String get preventionLabel => 'Prevention';

  @override
  String get govtAdvisoryLabel => 'Government Advisory / Source';

  @override
  String get nearbyVeterinarianTitle => 'Nearby Veterinarian';

  @override
  String get reportSimilarCaseBtn => 'Report Similar Case';

  @override
  String get noVetsNearAlertTitle => 'No Vets Found Nearby';

  @override
  String get noVetsNearAlertMsg =>
      'No registered veterinarians within 50 km of this alert.';

  @override
  String get sharedViaAppMsg => 'Shared via JeevaMitra';

  @override
  String get reportAlertTitle => 'Report Disease Alert';

  @override
  String get diseaseInfoSection => 'Disease Information';

  @override
  String get alertLocationSection => 'Alert Location';

  @override
  String get alertDetailsSection => 'Alert Details';

  @override
  String get sourceValiditySection => 'Source & Validity';

  @override
  String get diseaseNameLabel => 'Disease Name *';

  @override
  String get diseaseNameHint => 'e.g. Foot & Mouth Disease';

  @override
  String get diseaseNameFieldName => 'Disease name';

  @override
  String get alertTitleLabel => 'Alert Title *';

  @override
  String get alertTitleHint => 'e.g. FMD Alert in Guntur';

  @override
  String get titleFieldName => 'Title';

  @override
  String get districtFieldName => 'District';

  @override
  String get stateLabel => 'State *';

  @override
  String get descriptionFieldLabel => 'Description *';

  @override
  String get descriptionHint => 'Describe the symptoms and spread pattern…';

  @override
  String get descriptionFieldName => 'Description';

  @override
  String get preventionTipsLabel => 'Prevention Tips (optional)';

  @override
  String get preventionHint => 'What farmers can do to protect their animals…';

  @override
  String get treatmentFieldLabel => 'Treatment (optional)';

  @override
  String get treatmentHint => 'Recommended treatment or medication…';

  @override
  String get vetContactLabel => 'Vet Contact Number (optional)';

  @override
  String get vetContactHint => '+91 98765 43210';

  @override
  String get sourceAuthorityLabel => 'Source Authority *';

  @override
  String get sourceAuthorityHint =>
      'e.g. Animal Husbandry Dept., Farmer Community';

  @override
  String get sourceAuthorityFieldName => 'Source authority';

  @override
  String get alertValidUntilLabel => 'Alert Valid Until';

  @override
  String get alertValidUntilHelp => 'Alert valid until';

  @override
  String get defaultValidityMsg => '30 days from today (default)';

  @override
  String get submitAlertBtn => 'Submit Alert';

  @override
  String get setLocationMsg => 'Please set the alert location';

  @override
  String get alertReportedMsg => 'Alert reported. Thank you!';

  @override
  String get submitFailedMsg => 'Failed to submit. Please try again.';

  @override
  String get noLocationSetMsg => 'No location set';

  @override
  String get updateBtn => 'Update';

  @override
  String get detectBtn => 'Detect';

  @override
  String get adjustOnMapBtn => 'Adjust on Map';

  @override
  String get pickOnMapBtn => 'Pick on Map';

  @override
  String daysAgoMsg(int count) {
    return '${count}d ago';
  }

  @override
  String hoursAgoMsg(int count) {
    return '${count}h ago';
  }

  @override
  String minutesAgoMsg(int count) {
    return '${count}m ago';
  }

  @override
  String get readMoreBtn => 'Read More';

  @override
  String get perDayAnimalSuffix => ' /day/animal';

  @override
  String yearsExpMsg(int count) {
    return '$count yrs exp';
  }

  @override
  String ratingCountMsg(String rating, int count) {
    return '$rating ($count)';
  }

  @override
  String sortByLabel(String mode) {
    return 'Sort: $mode';
  }

  @override
  String get areaAcresLabel => 'Area (acres)';

  @override
  String kmChipLabel(int km) {
    return '$km km';
  }

  @override
  String noAvailableLandRadiusMsg(int radius) {
    return 'No available grazing land within $radius km.';
  }

  @override
  String noVetsFoundRadiusMsg(int radius) {
    return 'No veterinarians found within $radius km.';
  }

  @override
  String get perAnimalPerDaySuffix => ' per animal per day. ';

  @override
  String get minimumExperienceLabel => 'Minimum Experience (years)';

  @override
  String ratingStarsLabel(String rating) {
    return '$rating ★';
  }

  @override
  String yearsShortLabel(int count) {
    return '$count yrs';
  }

  @override
  String get feeSuffix => ' Fee';

  @override
  String ratingStarCountMsg(String rating, int count) {
    return '$rating ★ ($count)';
  }

  @override
  String resultsHereMsg(int count) {
    return '$count results here';
  }

  @override
  String get diseaseAlertFallbackTitle => 'Disease Alert';

  @override
  String alertsHereMsg(int count) {
    return '$count alerts here';
  }

  @override
  String issuedDateMsg(String date) {
    return 'Issued $date';
  }

  @override
  String validUntilDateMsg(String date) {
    return 'Valid until $date';
  }

  @override
  String severitySuffixMsg(String severity) {
    return '$severity severity';
  }

  @override
  String locationLineMsg(String where) {
    return 'Location: $where';
  }

  @override
  String get symptomsFieldLabel => 'Symptoms (optional)';

  @override
  String get symptomsHint => 'What signs to look for in affected animals…';

  @override
  String get stateFieldName => 'State';
}
