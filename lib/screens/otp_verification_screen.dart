import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/otp_service.dart';
import '../utils/preferences_helper.dart';
import '../theme/app_colors.dart';
import '../theme/background_widget.dart';
import '../theme/luna_widgets.dart';
import 'dashboard_screen.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final bool isFromProfile;

  const OTPVerificationScreen({
    super.key,
    required this.phoneNumber,
    this.isFromProfile = false,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  final OTPService _otpService = OTPService();
  bool _isLoading = false;
  bool _isVerifying = false;
  String? _errorMessage;
  int _resendCountdown = 60;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _sendOTP();
  }

  void _startResendTimer() {
    setState(() {
      _resendCountdown = 60;
      _canResend = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_resendCountdown > 0) {
            _resendCountdown--;
          } else {
            _canResend = true;
            timer.cancel();
          }
        });
      }
    });
  }

  Future<void> _sendOTP() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _otpService.sendOTP(
      phoneNumber: widget.phoneNumber,
      fromNumber: '8921742141',
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        _startResendTimer();
        
        final debugOTP = _otpService.getCurrentOTP();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              debugOTP != null 
                ? 'OTP sent! Debug code: $debugOTP'
                : 'Verification code sent successfully!',
              style: GoogleFonts.montserrat(),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
            duration: Duration(seconds: debugOTP != null ? 10 : 3),
          ),
        );
      } else {
        setState(() {
          _errorMessage = result['message'];
        });
      }
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.length != 6) {
      setState(() {
        _errorMessage = 'Please enter a 6-digit OTP';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    final result = _otpService.verifyOTP(_otpController.text, widget.phoneNumber);

    if (mounted) {
      setState(() {
        _isVerifying = false;
      });

      if (result['success']) {
        await _handleVerificationSuccess();
      } else {
        setState(() {
          _errorMessage = result['message'];
        });
      }
    }
  }

  Future<void> _handleVerificationSuccess() async {
    await PreferencesHelper.saveEmergencyNumber(widget.phoneNumber);
    await PreferencesHelper.savePhoneVerificationStatus(true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Phone number verified successfully!',
            style: GoogleFonts.montserrat()),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );

      if (widget.isFromProfile) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Luna-styled OTP boxes
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 64,
      textStyle: GoogleFonts.montserrat(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      decoration: BoxDecoration(
        color: AppColors.goldAccent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: AppColors.goldAccent, width: 2),
        color: AppColors.goldAccent.withOpacity(0.1),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: AppColors.goldAccent.withOpacity(0.15),
        border: Border.all(color: AppColors.goldAccent),
      ),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Verification',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
          )),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BackgroundWidget(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(
                color: AppColors.primary,
              ))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 120),
                    // Luna icon
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.goldAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.goldAccent.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        size: 50,
                        color: AppColors.goldAccent,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Column(
                      children: [
                        Text(
                          'Enter the code',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: GoogleFonts.montserrat(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                              height: 1.5,
                            ),
                            children: [
                              const TextSpan(text: 'We sent a verification code to\n'),
                              TextSpan(
                                text: widget.phoneNumber,
                                style: GoogleFonts.montserrat(
                                  color: AppColors.goldAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                    Pinput(
                      controller: _otpController,
                      length: 6,
                      defaultPinTheme: defaultPinTheme,
                      focusedPinTheme: focusedPinTheme,
                      submittedPinTheme: submittedPinTheme,
                      autofocus: true,
                      onCompleted: (pin) => _verifyOTP(),
                    ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.montserrat(
                            color: AppColors.error,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    const SizedBox(height: 50),
                    LunaButton(
                      text: 'VERIFY NOW',
                      onPressed: _isVerifying ? null : _verifyOTP,
                      isLoading: _isVerifying,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Didn't receive code? ",
                          style: GoogleFonts.montserrat(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        if (_canResend)
                          TextButton(
                            onPressed: _sendOTP,
                            child: Text(
                              'Resend',
                              style: GoogleFonts.montserrat(
                                color: AppColors.goldAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          )
                        else
                          Text(
                            'Resend in ${_resendCountdown}s',
                            style: GoogleFonts.montserrat(
                              color: AppColors.goldAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
