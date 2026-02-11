import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/preferences_helper.dart';
import '../theme/app_colors.dart';
import '../theme/background_widget.dart';
import '../theme/luna_widgets.dart';
import 'otp_verification_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _emergencyNumber;
  bool _isVerified = false;
  DateTime? _verificationDate;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final number = await PreferencesHelper.getEmergencyNumber();
    final verified = await PreferencesHelper.getPhoneVerificationStatus();
    final timestamp = await PreferencesHelper.getVerificationTimestamp();

    if (mounted) {
      setState(() {
        _emergencyNumber = number;
        _isVerified = verified;
        _verificationDate = timestamp;
        _isLoading = false;
      });
    }
  }

  Future<void> _editPhoneNumber() async {
    final TextEditingController phoneController = TextEditingController(
      text: _emergencyNumber ?? '',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text('Edit Phone Number', 
          style: GoogleFonts.playfairDisplay(
            color: AppColors.textPrimary, 
            fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LunaInputField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              labelText: 'Phone Number',
              hintText: '+91 98765 43210',
              prefixIcon: Icons.phone_rounded,
            ),
            const SizedBox(height: 16),
            Text(
              'Note: You will need to verify the new number via OTP to activate the guard.',
              style: GoogleFonts.montserrat(
                fontSize: 12, 
                color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: GoogleFonts.montserrat(
              color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              if (phoneController.text.isNotEmpty) {
                Navigator.pop(context, phoneController.text);
              }
            },
            child: Text('CONTINUE', style: GoogleFonts.montserrat(
              color: AppColors.goldAccent,
              fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result != null && result != _emergencyNumber) {
      final verified = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OTPVerificationScreen(
            phoneNumber: result,
            isFromProfile: true,
          ),
        ),
      );

      if (verified == true) {
        _loadProfileData();
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Account & Security',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
          )),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BackgroundWidget(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(
              color: AppColors.primary,
            ))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 120, 24, 40),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 32),
                  _buildVerificationCard(),
                  const SizedBox(height: 32),
                  _buildSettingsSection(),
                  const SizedBox(height: 32),
                  _buildPermissionsSection(),
                  const SizedBox(height: 48),
                  _buildAppInfo(),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.goldAccent, width: 2),
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.goldAccent.withOpacity(0.1),
            child: const Icon(Icons.person_rounded, size: 50, color: AppColors.goldAccent),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'EMERGENCY CONTACT',
          style: GoogleFonts.montserrat(
            fontSize: 11, 
            color: AppColors.textMuted, 
            fontWeight: FontWeight.bold, 
            letterSpacing: 2),
        ),
        const SizedBox(height: 8),
        Text(
          _emergencyNumber ?? 'No number set',
          style: GoogleFonts.playfairDisplay(
            fontSize: 26, 
            fontWeight: FontWeight.bold, 
            letterSpacing: 1,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: (_isVerified ? AppColors.success : AppColors.error).withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (_isVerified ? AppColors.success : AppColors.error).withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (_isVerified ? AppColors.success : AppColors.error).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isVerified ? Icons.verified_user_rounded : Icons.security_rounded,
              color: _isVerified ? AppColors.success : AppColors.error,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isVerified ? 'Shield Active' : 'Shield Incomplete',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _isVerified ? AppColors.success : AppColors.error,
                  ),
                ),
                Text(
                  _isVerified 
                    ? 'Verified on ${_verificationDate != null ? _formatDate(_verificationDate!) : 'unknown'}' 
                    : 'Verification required for SMS alerts',
                  style: GoogleFonts.montserrat(
                    fontSize: 12, 
                    color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('SETTINGS'),
        const SizedBox(height: 16),
        _buildActionItem(
          icon: Icons.phone_android_rounded,
          title: 'Change Emergency Contact',
          onTap: _editPhoneNumber,
        ),
        const SizedBox(height: 12),
        _buildActionItem(
          icon: Icons.verified_rounded,
          title: 'Verify Device Link',
          onTap: _isVerified ? null : () {
             if (_emergencyNumber != null) {
               Navigator.push(context, MaterialPageRoute(builder: (context) => OTPVerificationScreen(phoneNumber: _emergencyNumber!)));
             }
          },
          subtitle: _isVerified ? 'Device fully authenticated' : 'Tap to start verification',
        ),
      ],
    );
  }

  Widget _buildPermissionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('PERMISSIONS'),
        const SizedBox(height: 16),
        _buildPermissionItem(
          icon: Icons.mic_rounded,
          title: 'Microphone Access',
          onTap: () => openAppSettings(),
        ),
        const SizedBox(height: 12),
        _buildPermissionItem(
          icon: Icons.notifications_active_rounded,
          title: 'Reliable Notifications',
          onTap: () => openAppSettings(),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        title,
        style: GoogleFonts.montserrat(
          fontSize: 11, 
          fontWeight: FontWeight.bold, 
          letterSpacing: 2, 
          color: AppColors.textMuted),
      ),
    );
  }

  Widget _buildActionItem({required IconData icon, required String title, String? subtitle, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: LunaCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.goldAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.goldAccent, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600, fontSize: 15)),
                  if (subtitle != null)
                    Text(subtitle, style: GoogleFonts.montserrat(
                      fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionItem({required IconData icon, required String title, VoidCallback? onTap}) {
    return _buildActionItem(icon: icon, title: title, subtitle: 'System control managed', onTap: onTap);
  }

  Widget _buildAppInfo() {
    return Column(
      children: [
        Text(
          'Silent Guard v1.0.2-std',
          style: GoogleFonts.montserrat(
            color: AppColors.textMuted, 
            fontSize: 13, 
            fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          'Protecting you everywhere.',
          style: GoogleFonts.montserrat(
            color: AppColors.textMuted, 
            fontSize: 11),
        ),
      ],
    );
  }
}
