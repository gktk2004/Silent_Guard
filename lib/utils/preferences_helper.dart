import 'package:shared_preferences/shared_preferences.dart';

class PreferencesHelper {
  static const String keySelectedSounds = 'selected_sounds';
  static const String keyEmergencyNumber = 'emergency_number';
  static const String keyPhoneVerified = 'phone_verified';
  static const String keyVerificationTimestamp = 'verification_timestamp';

  static Future<void> saveSelectedSounds(List<String> sounds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(keySelectedSounds, sounds);
  }

  static Future<List<String>> getSelectedSounds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(keySelectedSounds) ?? [];
  }

  static Future<void> saveEmergencyNumber(String number) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyEmergencyNumber, number);
  }

  static Future<String?> getEmergencyNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyEmergencyNumber);
  }

  static Future<void> savePhoneVerificationStatus(bool verified) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyPhoneVerified, verified);
    if (verified) {
      await prefs.setInt(keyVerificationTimestamp, DateTime.now().millisecondsSinceEpoch);
    }
  }

  static Future<bool> getPhoneVerificationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyPhoneVerified) ?? false;
  }

  static Future<DateTime?> getVerificationTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(keyVerificationTimestamp);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }
}
