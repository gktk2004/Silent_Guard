import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/preferences_helper.dart';
import '../utils/alert_helper.dart';
import '../services/background_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/background_widget.dart';
import '../theme/luna_widgets.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  String? _detectedLabel;
  double _confidence = 0.0;
  bool _isAlert = false;
  bool _isServiceRunning = false;
  List<String> _selectedSounds = [];
  
  final List<String> _allSounds = [
    'Speech',
    'Baby cry, infant cry',
    'Doorbell',
    'Knock',
    'Fire alarm',
    'Glass breaking',
    'Dog',
    'Siren',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkServiceStatus();
    _setupServiceListener();
  }

  final Map<String, IconData> _soundIcons = {
    'Speech': Icons.record_voice_over_rounded,
    'Baby cry, infant cry': Icons.child_care_rounded,
    'Doorbell': Icons.notifications_active_rounded,
    'Knock': Icons.meeting_room_rounded,
    'Fire alarm': Icons.notification_important_rounded,
    'Glass breaking': Icons.warning_amber_rounded,
    'Dog': Icons.pets_rounded,
    'Siren': Icons.campaign_rounded,
  };

  List<Map<String, dynamic>> _detectionHistory = [];

  void _setupServiceListener() {
    final service = FlutterBackgroundService();
    
    service.on('sound_detected').listen((event) {
      if (event != null && mounted) {
        final label = event['label'];
        final score = event['confidence'] ?? 0.0;
        final isAlert = event['is_alert'] ?? false;

        print('UI Received sound: $label ($score)');
        setState(() {
          _detectedLabel = label;
          _confidence = score;
          _isAlert = isAlert;

          // Add to history if it's a significant detection
          if (score > 0.4) {
            _detectionHistory.insert(0, {
              'label': label,
              'time': DateTime.now(),
              'isAlert': isAlert,
            });
            if (_detectionHistory.length > 5) _detectionHistory.removeLast();
          }
        });
      }
    });

    service.on('status_update').listen((event) {
      if (event != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(event['message']),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  Future<void> _loadSettings() async {
    final sounds = await PreferencesHelper.getSelectedSounds();
    if (mounted) {
      setState(() {
        _selectedSounds = sounds;
      });
    }
  }

  Future<void> _checkServiceStatus() async {
    final service = FlutterBackgroundService();
    var isRunning = await service.isRunning();
    if (mounted) {
      setState(() {
        _isServiceRunning = isRunning;
      });
    }
  }

  Future<void> _toggleSound(String sound) async {
    setState(() {
      if (_selectedSounds.contains(sound)) {
        _selectedSounds.remove(sound);
      } else {
        _selectedSounds.add(sound);
      }
    });
    await PreferencesHelper.saveSelectedSounds(_selectedSounds);
  }

  Future<void> _toggleService() async {
    final service = FlutterBackgroundService();
    var isRunning = await service.isRunning();

    if (isRunning) {
      service.invoke("stopService");
      setState(() {
        _isServiceRunning = false;
        _detectedLabel = null;
        _confidence = 0.0;
        _isAlert = false;
      });
    } else {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.microphone,
        Permission.sms,
        Permission.notification,
      ].request();

      if (statuses.values.any((s) => s.isDenied || s.isPermanentlyDenied)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All permissions are required to start monitoring.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      await initializeService(startNow: true);
      await Future.delayed(const Duration(seconds: 2));
      var nowRunning = await service.isRunning();
      
      if (mounted) {
        setState(() {
          _isServiceRunning = nowRunning;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Silent Guard Hub',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          )),
        centerTitle: false,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.goldAccent.withOpacity(0.1),
              child: const Icon(Icons.person_rounded, size: 20, color: AppColors.goldAccent),
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: BackgroundWidget(
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildStatusHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetectionVisualizer(),
                    const SizedBox(height: 32),
                    _buildSectionHeader('ACTIVE WATCHLIST', Icons.radar_rounded),
                    const SizedBox(height: 16),
                    _buildSoundGrid(),
                    const SizedBox(height: 32),
                    if (_detectionHistory.isNotEmpty) ...[
                      _buildSectionHeader('RECENT ACTIVITY', Icons.history_rounded),
                      const SizedBox(height: 16),
                      _buildActivityLog(),
                    ],
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildMonitoringToggle(),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return LunaSectionHeader(title: title, icon: icon);
  }

  Widget _buildActivityLog() {
    return LunaCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: _detectionHistory.map((item) {
          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (item['isAlert'] ? AppColors.error : AppColors.success).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                item['isAlert'] ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                size: 16,
                color: item['isAlert'] ? AppColors.error : AppColors.success,
              ),
            ),
            title: Text(item['label'], 
              style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w500)),
            trailing: Text(
              '${item['time'].hour}:${item['time'].minute.toString().padLeft(2, '0')}',
              style: GoogleFonts.montserrat(color: AppColors.textMuted, fontSize: 12),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: LunaCard(
        padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              _buildPulseIndicator(),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isServiceRunning 
                        ? (_isAlert ? 'DANGER DETECTED' : 'SYSTEM ACTIVE') 
                        : 'SYSTEM STANDBY',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1,
                        color: _isServiceRunning 
                          ? (_isAlert ? AppColors.error : AppColors.success)
                          : AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      _isServiceRunning 
                        ? 'Monitoring environment...' 
                        : 'Ready to start guard',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isServiceRunning)
                _buildQuickAction(
                  icon: Icons.sms_outlined,
                  onPressed: () async {
                    await AlertHelper.sendTestSMS();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Test SMS sent!', style: GoogleFonts.montserrat()),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPulseIndicator() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: (_isServiceRunning 
          ? (_isAlert ? AppColors.error : AppColors.success)
          : AppColors.textMuted).withOpacity(0.1),
        border: Border.all(
          color: (_isServiceRunning 
            ? (_isAlert ? AppColors.error : AppColors.success)
            : AppColors.textMuted).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isServiceRunning 
              ? (_isAlert ? AppColors.error : AppColors.success)
              : AppColors.textMuted,
            boxShadow: [
              BoxShadow(
                color: (_isServiceRunning 
                  ? (_isAlert ? AppColors.error : AppColors.success)
                  : AppColors.textMuted).withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 5,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetectionVisualizer() {
    return LunaCard(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _isAlert 
                      ? [AppColors.error.withOpacity(0.15), AppColors.error.withOpacity(0.3)]
                      : [AppColors.goldAccent.withOpacity(0.15), AppColors.goldAccent.withOpacity(0.3)],
                  ),
                ),
                child: Icon(
                  _isAlert ? Icons.warning_rounded : (_detectedLabel != null ? Icons.hearing_rounded : Icons.mic_rounded),
                  size: 64,
                  color: _isAlert ? AppColors.error : AppColors.goldAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Text(
            _isServiceRunning 
              ? (_detectedLabel ?? 'LISTENING...') 
              : 'IDLE',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: AppColors.textPrimary,
            ),
          ),
          if (_isServiceRunning && _detectedLabel != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: (_isAlert ? AppColors.error : AppColors.success).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isAlert ? AppColors.error : AppColors.success,
                ),
              ),
              child: Text(
                'Confidence: ${(_confidence * 100).toStringAsFixed(1)}%',
                style: GoogleFonts.montserrat(
                  color: _isAlert ? AppColors.error : AppColors.success,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSoundGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: _allSounds.length,
      itemBuilder: (context, index) {
        final sound = _allSounds[index];
        final isSelected = _selectedSounds.contains(sound);
        final icon = _soundIcons[sound] ?? Icons.audiotrack_rounded;
        
        return LunaSelectionBox(
          label: sound,
          icon: icon,
          isSelected: isSelected,
          onTap: () => _toggleSound(sound),
        );
      },
    );
  }

  Widget _buildMonitoringToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: LunaButton(
        text: _isServiceRunning ? 'STOP MONITORING' : 'START MONITORING',
        icon: _isServiceRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
        onPressed: _selectedSounds.isEmpty ? null : _toggleService,
        backgroundColor: _isServiceRunning ? AppColors.error.withOpacity(0.8) : AppColors.primary,
      ),
    );
  }

  Widget _buildQuickAction({required IconData icon, required VoidCallback onPressed}) {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.goldAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.goldAccent.withOpacity(0.2)),
        ),
        child: Icon(icon, size: 20, color: AppColors.goldAccent),
      ),
      onPressed: onPressed,
    );
  }
}
