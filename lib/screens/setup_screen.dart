import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/preferences_helper.dart';
import '../theme/app_colors.dart';
import '../theme/background_widget.dart';
import '../theme/luna_widgets.dart';
import 'otp_verification_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExistingNumber();
  }

  Future<void> _loadExistingNumber() async {
    final phone = await PreferencesHelper.getEmergencyNumber();
    if (phone != null && phone.isNotEmpty) {
      _phoneController.text = phone;
    }
  }

  Future<void> _saveAndContinue() async {
    final phoneNumber = _phoneController.text.trim();
    
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter your phone number',
            style: GoogleFonts.montserrat()),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!phoneNumber.startsWith('+')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Phone number must start with country code (e.g., +91)',
            style: GoogleFonts.montserrat()),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => OTPVerificationScreen(
            phoneNumber: phoneNumber,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: BackgroundWidget(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60),
          child: Column(
            children: [
              // Logo and branding section
              Column(
                children: [
                  const SizedBox(height: 60),
                  // Silent Guard Logo
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/logo.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Silent Guard',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                      height: 1.1,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'AI-POWERED SOUND SAFETY',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      color: AppColors.goldAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Monitoring your environment for critical sounds to keep you safe.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 60),
              
              // Phone input card
              LunaCard(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GET STARTED',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 24),
                    LunaInputField(
                      controller: _phoneController,
                      labelText: 'Phone Number',
                      hintText: '+91 98765 43210',
                      prefixIcon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'We will send a verification code to this number for secure alerts.',
                      style: GoogleFonts.montserrat(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 32),
                    LunaButton(
                      text: 'CONTINUE',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: _saveAndContinue,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
