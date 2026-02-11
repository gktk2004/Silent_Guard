import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:background_sms/background_sms.dart';
import 'package:permission_handler/permission_handler.dart';

class OTPService {
  String? _currentOTP;
  String? _verifiedPhoneNumber;
  DateTime? _otpSentTime;

  /// Request SMS permission if not granted
  Future<bool> requestSMSPermission() async {
    var status = await Permission.sms.status;
    if (status.isGranted) {
      return true;
    }
    
    // Request permission
    status = await Permission.sms.request();
    return status.isGranted;
  }
  
  /// Generate a random 6-digit OTP
  String _generateOTP() {
    final random = Random.secure();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// Send OTP via SMS to the given phone number
  Future<Map<String, dynamic>> sendOTP({
    required String phoneNumber,
    String fromNumber = '8921742141',
  }) async {

    try {
      // Check for SMS permission first
      bool hasPermission = await requestSMSPermission();
      if (!hasPermission) {
        return {
          'success': false,
          'message': 'SMS permission is required to send the verification code. Please enable it in settings.',
        };
      }

      // Generate new OTP
      _currentOTP = _generateOTP();
      _otpSentTime = DateTime.now();
      
      final message = 'Your Silent Guard verification code is: $_currentOTP\n\nThis code will expire in 5 minutes.';
      
      // Send SMS using background_sms
      if (kDebugMode) {
        print('Sending SMS from $fromNumber to $phoneNumber');
      }
      var result = await BackgroundSms.sendMessage(
        phoneNumber: phoneNumber,
        message: message,
      );

      
      if (result == SmsStatus.sent) {
        if (kDebugMode) {
          print('OTP sent successfully to $phoneNumber: $_currentOTP');
        }
        return {
          'success': true,
          'message': 'Verification code sent successfully!',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to send SMS. Please check phone number and SMS permissions.',
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending OTP: $e');
      }
      return {
        'success': false,
        'message': 'Error sending verification code: $e',
      };
    }
  }

  /// Verify the OTP code entered by user
  Map<String, dynamic> verifyOTP(String otpCode, String phoneNumber) {
    if (_currentOTP == null) {
      return {
        'success': false,
        'message': 'No OTP found. Please request a new code.',
      };
    }

    // Check if OTP is expired (5 minutes)
    if (_otpSentTime != null) {
      final difference = DateTime.now().difference(_otpSentTime!);
      if (difference.inMinutes > 5) {
        _currentOTP = null; // Clear expired OTP
        return {
          'success': false,
          'message': 'OTP has expired. Please request a new code.',
        };
      }
    }

    // Verify the OTP
    if (otpCode == _currentOTP) {
      _verifiedPhoneNumber = phoneNumber;
      _currentOTP = null; // Clear OTP after successful verification
      return {
        'success': true,
        'message': 'Phone number verified successfully!',
        'phoneNumber': phoneNumber,
      };
    } else {
      return {
        'success': false,
        'message': 'Invalid verification code. Please try again.',
      };
    }
  }

  /// Check if a phone number is verified
  bool isPhoneVerified(String phoneNumber) {
    return _verifiedPhoneNumber == phoneNumber;
  }

  /// Get the current OTP (for debugging only - remove in production)
  String? getCurrentOTP() {
    return kDebugMode ? _currentOTP : null;
  }

  /// Clear verification data
  void clearVerification() {
    _currentOTP = null;
    _verifiedPhoneNumber = null;
    _otpSentTime = null;
  }
}
