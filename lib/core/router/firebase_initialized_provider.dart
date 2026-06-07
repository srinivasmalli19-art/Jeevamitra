import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Overridden in main() after Firebase.initializeApp() attempt.
/// Prevents the app from crashing when google-services.json is missing.
final firebaseInitializedProvider = Provider<bool>((_) => false);
