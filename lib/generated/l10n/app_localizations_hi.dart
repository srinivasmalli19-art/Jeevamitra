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
}
