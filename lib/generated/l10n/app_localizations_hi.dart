// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'जीवमित्र';

  @override
  String get tagline => 'आपका कृषि मित्र';

  @override
  String get continueBtn => 'जारी रखें';

  @override
  String get skipBtn => 'छोड़ें';

  @override
  String get backBtn => 'वापस';

  @override
  String get saveBtn => 'सहेजें';

  @override
  String get cancelBtn => 'रद्द करें';

  @override
  String get confirmBtn => 'पुष्टि करें';

  @override
  String get deleteBtn => 'हटाएं';

  @override
  String get editBtn => 'संपादित करें';

  @override
  String get retryBtn => 'पुनः प्रयास करें';

  @override
  String get closeBtn => 'बंद करें';

  @override
  String get doneBtn => 'हो गया';

  @override
  String get nextBtn => 'अगला';

  @override
  String get yesBtn => 'हाँ';

  @override
  String get noBtn => 'नहीं';

  @override
  String get searchHint => 'खोजें...';

  @override
  String get loadingMsg => 'लोड हो रहा है...';

  @override
  String get noInternetMsg => 'इंटरनेट कनेक्शन नहीं है';

  @override
  String get errorMsg => 'कुछ गलत हो गया';

  @override
  String get noDataMsg => 'कोई डेटा नहीं मिला';

  @override
  String get selectLanguage => 'भाषा चुनें';

  @override
  String get languageHint => 'अपनी पसंदीदा भाषा चुनें';

  @override
  String get onboardTitle1 => 'अपनी भूमि सूचीबद्ध करें';

  @override
  String get onboardBody1 =>
      'किसान अपनी जमीन पंजीकृत कर चरवाहों के लिए उपलब्ध करा सकते हैं।';

  @override
  String get onboardTitle2 => 'पास में चराई भूमि खोजें';

  @override
  String get onboardBody2 =>
      'आस-पास उपलब्ध चराई भूमि खोजें और किसान से सीधे बुक करें।';

  @override
  String get onboardTitle3 => 'पास में पशु चिकित्सक';

  @override
  String get onboardBody3 =>
      'आपात स्थिति में एक क्लिक से पास के पशु चिकित्सक को खोजें।';

  @override
  String get mobileNumber => 'मोबाइल नंबर';

  @override
  String get mobileNumberHint => '10 अंकों का मोबाइल नंबर दर्ज करें';

  @override
  String get sendOtp => 'OTP भेजें';

  @override
  String get enterOtp => 'OTP दर्ज करें';

  @override
  String get otpHint => '6 अंकों का OTP';

  @override
  String get verifyOtp => 'OTP सत्यापित करें';

  @override
  String get resendOtp => 'OTP फिर से भेजें';

  @override
  String resendIn(int seconds) {
    return '$seconds सेकंड में फिर भेजें';
  }

  @override
  String otpSentTo(String phone) {
    return '$phone पर OTP भेजा गया';
  }

  @override
  String get selectRole => 'मैं एक हूँ...';

  @override
  String get roleFarmer => 'किसान';

  @override
  String get roleFarmerDesc => 'मेरे पास जमीन है और चराई के लिए देना चाहता हूँ';

  @override
  String get roleShepherd => 'चरवाहा';

  @override
  String get roleShepherdDesc => 'मेरे पास जानवर हैं और चराई भूमि चाहिए';

  @override
  String get yourName => 'आपका नाम';

  @override
  String get yourVillage => 'गाँव / शहर';

  @override
  String get yourDistrict => 'जिला';

  @override
  String get completeProfile => 'प्रोफ़ाइल पूरी करें';

  @override
  String get farmerDashboard => 'डैशबोर्ड';

  @override
  String get myLands => 'मेरी भूमि';

  @override
  String get bookings => 'बुकिंग';

  @override
  String get explore => 'खोजें';

  @override
  String get profile => 'प्रोफ़ाइल';

  @override
  String get shepherdDashboard => 'डैशबोर्ड';

  @override
  String get discover => 'खोजें';

  @override
  String get vets => 'पशु चिकित्सक';

  @override
  String get addLand => 'भूमि जोड़ें';

  @override
  String get landTitle => 'भूमि का नाम';

  @override
  String get landArea => 'भूमि क्षेत्रफल';

  @override
  String get pricePerDay => 'प्रति दिन / प्रति जानवर कीमत';

  @override
  String get fodderTypes => 'उपलब्ध चारा';

  @override
  String get amenities => 'सुविधाएं';

  @override
  String get water => 'पानी';

  @override
  String get shade => 'छाया';

  @override
  String get fencing => 'बाड़';

  @override
  String get vetNearby => 'पास में पशु चिकित्सक';

  @override
  String get bookNow => 'अभी बुक करें';

  @override
  String get checkIn => 'चेक-इन';

  @override
  String get checkOut => 'चेक-आउट';

  @override
  String get animalCount => 'जानवरों की संख्या';

  @override
  String get totalAmount => 'कुल राशि';

  @override
  String get advanceAmount => 'अग्रिम';

  @override
  String get bookingPending => 'लंबित';

  @override
  String get bookingConfirmed => 'पुष्टि हुई';

  @override
  String get bookingActive => 'सक्रिय';

  @override
  String get bookingCompleted => 'पूर्ण';

  @override
  String get bookingCancelled => 'रद्द';

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
  String get nearbyVets => 'पास के पशु चिकित्सक';

  @override
  String get govtVet => 'सरकारी पशु चिकित्सक';

  @override
  String get available24x7 => '24×7 उपलब्ध';

  @override
  String get consultationFee => 'परामर्श शुल्क';

  @override
  String get free => 'निःशुल्क';

  @override
  String get callVet => 'पशु चिकित्सक को बुलाएं';

  @override
  String get whatsappVet => 'WhatsApp';

  @override
  String get emergency => 'आपातकाल';

  @override
  String get emergencyCallVet => 'निकटतम पशु चिकित्सक को बुलाएं';

  @override
  String get emergencyHelpline => 'हेल्पलाइन 1962';

  @override
  String get voiceInputHint => 'बोलने के लिए माइक दबाएं';

  @override
  String get listeningMsg => 'सुन रहा हूँ...';

  @override
  String get voiceNotSupported => 'इस डिवाइस पर वॉइस समर्थित नहीं है';

  @override
  String get rateExperience => 'अपना अनुभव रेट करें';

  @override
  String get writeReview => 'समीक्षा लिखें';

  @override
  String get submitReview => 'समीक्षा जमा करें';

  @override
  String get notifications => 'सूचनाएं';

  @override
  String get noNotifications => 'अभी तक कोई सूचना नहीं';

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
  String get settings => 'सेटिंग्स';

  @override
  String get language => 'भाषा';

  @override
  String get logout => 'लॉग आउट';

  @override
  String get logoutConfirm => 'क्या आप वाकई लॉग आउट करना चाहते हैं?';

  @override
  String distanceKm(String km) {
    return '$km किमी दूर';
  }

  @override
  String distanceMetersAway(int m) {
    return '$m m away';
  }

  @override
  String perDayPerAnimal(String price) {
    return '₹$price/दिन/जानवर';
  }

  @override
  String get availableNow => 'उपलब्ध';

  @override
  String get notAvailable => 'उपलब्ध नहीं';

  @override
  String acres(String area) {
    return '$area एकड़';
  }

  @override
  String get mobileNumberSubtitle =>
      'OTP प्राप्त करने के लिए अपना मोबाइल नंबर दर्ज करें';

  @override
  String get termsAgreement =>
      'जारी रखकर, आप हमारी शर्तों और गोपनीयता नीति से सहमत होते हैं';

  @override
  String get otpNotReceivedMsg => 'OTP प्राप्त नहीं हुआ?';

  @override
  String get selectRoleTitle => 'आप कौन हैं?';

  @override
  String get genericErrorRetryMsg => 'कुछ गलत हो गया। कृपया पुनः प्रयास करें।';

  @override
  String get invalidOtpMsg => 'अमान्य OTP। कृपया पुनः प्रयास करें।';

  @override
  String get genericSaveFailedMsg => 'सहेजने में विफल। कृपया पुनः प्रयास करें।';

  @override
  String get completeProfileSubtitle =>
      'शुरू करने के लिए अपनी प्रोफ़ाइल पूरी करें';

  @override
  String get yourNameHint => 'अपना पूरा नाम दर्ज करें';

  @override
  String get yourVillageHint => 'आपके गाँव या शहर का नाम';

  @override
  String get saveContinueBtn => 'सहेजें और जारी रखें';

  @override
  String get saveProfileFailedMsg =>
      'आपकी प्रोफ़ाइल सहेजी नहीं जा सकी। कृपया पुनः प्रयास करें।';

  @override
  String get getStartedBtn => 'शुरू करें';

  @override
  String get homeTab => 'होम';

  @override
  String greetingName(String name) {
    return 'नमस्ते, $name!';
  }

  @override
  String get voiceAssistantTooltip => 'वॉइस असिस्टेंट';

  @override
  String get alertsLabel => 'अलर्ट';

  @override
  String get overviewLabel => 'अवलोकन';

  @override
  String get earningsLabel => 'कमाई';

  @override
  String get recentBookingsLabel => 'हाल की बुकिंग';

  @override
  String get viewAllBtn => 'सभी देखें';

  @override
  String get noBookingsYetTitle => 'अभी तक कोई बुकिंग नहीं';

  @override
  String get noBookingsYetSubtitle => 'चरवाहों की बुकिंग यहाँ दिखाई देंगी';

  @override
  String pendingApprovalMsg(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count बुकिंग आपकी स्वीकृति की प्रतीक्षा में हैं',
      one: '1 बुकिंग आपकी स्वीकृति की प्रतीक्षा में है',
    );
    return '$_temp0';
  }

  @override
  String get tapToReviewMsg => 'समीक्षा करने और स्वीकार करने के लिए टैप करें';

  @override
  String bookingSummaryMsg(int count, String date, String amount) {
    return '$count जानवर · $date · ₹$amount';
  }

  @override
  String get upcomingLabel => 'आगामी';

  @override
  String get tripsDoneLabel => 'पूरी यात्राएं';

  @override
  String get spentLabel => 'खर्च';

  @override
  String get findLandLabel => 'भूमि खोजें';

  @override
  String get findVetLabel => 'पशु चिकित्सक खोजें';

  @override
  String get myTripsLabel => 'मेरी यात्राएं';

  @override
  String get noTripsYetTitle => 'अभी तक कोई यात्रा नहीं';

  @override
  String get noTripsYetSubtitle =>
      'अपनी पहली यात्रा शुरू करने के लिए भूमि बुक करें';

  @override
  String get discoverLandsBtn => 'भूमि खोजें';

  @override
  String activeTripMsg(String title) {
    return 'सक्रिय यात्रा: $title';
  }

  @override
  String tripEndsMsg(int count, String date) {
    return '$count जानवर · $date को समाप्त';
  }

  @override
  String get editProfileTitle => 'प्रोफ़ाइल संपादित करें';

  @override
  String get profileInfoLabel => 'प्रोफ़ाइल जानकारी';

  @override
  String get accountLabel => 'खाता';

  @override
  String get deleteAccountTitle => 'खाता हटाएं';

  @override
  String get deleteAccountBody =>
      'इससे आपका खाता और आपका सारा डेटा स्थायी रूप से हट जाएगा। इसे वापस नहीं लाया जा सकता।';

  @override
  String get deleteAccountSubtitle =>
      'आपका सारा डेटा स्थायी रूप से हटा देता है';

  @override
  String get landsLabel => 'भूमियाँ';

  @override
  String get totalTripsLabel => 'कुल यात्राएं';

  @override
  String get phoneRequiredMsg => 'फ़ोन नंबर आवश्यक है';

  @override
  String get phoneInvalidMsg => 'मान्य 10 अंकों का मोबाइल नंबर दर्ज करें';

  @override
  String get nameRequiredMsg => 'नाम आवश्यक है';

  @override
  String get nameTooShortMsg => 'नाम कम से कम 2 अक्षर का होना चाहिए';

  @override
  String get nameTooLongMsg => 'नाम बहुत लंबा है';

  @override
  String get villageRequiredMsg => 'गाँव/शहर आवश्यक है';

  @override
  String get villageInvalidMsg => 'मान्य स्थान दर्ज करें';

  @override
  String get otpRequiredMsg => 'OTP आवश्यक है';

  @override
  String get otpInvalidMsg => '6 अंकों का OTP दर्ज करें';

  @override
  String get districtRequiredMsg => 'जिला आवश्यक है';

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
