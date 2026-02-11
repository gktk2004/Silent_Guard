import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tflite_flutter_plus/tflite_flutter_plus.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui';
import '../utils/alert_helper.dart';

// Global instances to prevent GC
AudioRecorder? _audioRecorder;
Interpreter? _interpreter;
StreamSubscription? _audioSubscription;
ServiceInstance? _service;

// Entry point for the background service
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  _service = service;
  // Ensure plugins are initialized in this isolate
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  await AlertHelper.initialize();
  await _refreshConfig(); // Initial config load
  
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  try {
    // 1. Initialize Local Notifications (for persistent notification)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'silent_guard_service',
      'Silent Guard Service',
      icon: '@mipmap/ic_launcher',
      ongoing: true,
    );

    Future<void> updateNotification(String status) async {
        try {
          await flutterLocalNotificationsPlugin.show(
            id: 888,
            title: 'Silent Guard',
            body: status,
            notificationDetails: const NotificationDetails(android: androidNotificationDetails),
          );
        } catch (e) {
          print("Notification Error: $e");
        }
    }

    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(
      const AndroidNotificationChannel(
        'silent_guard_service',
        'Silent Guard Service',
        description: 'Running in background',
        importance: Importance.low,
      ),
    );

    await updateNotification('Service Started. Initializing...');

    // 2. Initialize TFLite Interpreter
    try {
      // Note: Interpreter.fromAsset prepends 'assets/' automatically
      // However, explicit path 'assets/yamnet.tflite' sometimes works better depending on version
      _interpreter = await Interpreter.fromAsset('yamnet.tflite');
      print("!!! TFLite Interpreter initialized successfully !!!");
      await updateNotification('AI Model Loaded.');
    } catch (e) {
      if (e.toString().contains("libtensorflowlite_c.so")) {
          print("!!! CRITICAL: TFLite Native Library Missing. Run 'flutter clean' and rebuild. !!!");
      }
      print('!!! CRITICAL ERROR initializing TFLite Interpreter: $e !!!');
      print('Stack trace: ${StackTrace.current}');
      await updateNotification('Error loading AI Model: TFLite Lib Missing');
      if (_service != null) {
        _service!.invoke('status_update', {'message': 'AI Model Error: Native Library Missing'});
      }
    }

    // 3. Setup Audio Recorder
    _audioRecorder = AudioRecorder();
    
    await updateNotification('Service Running. Checking Mic...');
    
    print('Starting audio stream...');
    Stream<Uint8List>? stream;
    
    try {
      print('Attempting to start stream directly...');
      // Assume permission is granted by UI check
      stream = await _audioRecorder!.startStream(
          const RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: 16000,
            numChannels: 1,
            // default config is usually safest
          ),
        );
      print('Audio stream started successfully! Stream object: $stream');
      await updateNotification('Monitoring Active 🎤 - Listening...');

    } catch (streamError, stackTrace) {
      print('CRITICAL ERROR starting audio stream: $streamError');
      print(stackTrace);
      await updateNotification('Stream Error: $streamError');
      // Attempt clean up but keep service alive
      try { await _audioRecorder!.dispose(); } catch(_) {}
      // service.stopSelf(); 
      return;
    }

    // Audio buffer for inference
    List<int> audioBuffer = [];
    // YAMNet input size (example: 15600 samples for ~0.975s)
    const int inputSize = 15600; 

    if (stream != null) {
        bool firstPacket = true;
        _audioSubscription = stream.listen((data) async {
          if (firstPacket) {
             print("First audio packet received! Size: ${data.length}");
             await updateNotification('Monitoring Active 🎤 - Receiving Audio...');
             firstPacket = false;
          }
          
          // Assuming data is 16-bit PCM, execute logic
          
          // Simplified: Just accumulate raw bytes until we have enough
          // print('Packet received: ${data.length} bytes'); // High verbosity log
          audioBuffer.addAll(data);
          
          if (audioBuffer.length % 3200 == 0) { // Log occasionally
               print('Buffer filling: ${audioBuffer.length} / ${inputSize * 2}');
          }

          if (audioBuffer.length >= inputSize * 2) { // *2 because 16-bit = 2 bytes per sample

            print("--------------------------------------------------");
            print("Buffer Full ($inputSize * 2). Running Inference...");
            // Process buffer
            await runInference(_interpreter, audioBuffer.sublist(0, inputSize * 2));
            
            // Remove processed chunk
            audioBuffer.removeRange(0, inputSize * 2);
          }
        }, onError: (e) async {
            print("Audio Stream Error: $e");
            await updateNotification('Stream Error: $e');
            // service.stopSelf();
        });
    }

    // Listen for stop command
    service.on('stopService').listen((event) async {
      await _audioSubscription?.cancel();
      await _audioRecorder?.dispose();
      service.stopSelf();
    });
  } catch (e, stackTrace) {
    print("Top-level Service Error: $e");
    print(stackTrace);
    // ... error notification ...
    service.stopSelf();
  }
}

// Standard YAMNet Class Map (Partial)
const Map<int, String> _yamnetLabels = {
  0: 'Speech',
  1: 'Child speech, kid speech',
  20: 'Baby cry, infant cry',
  21: 'Baby cry, infant cry', 
  22: 'Baby cry, infant cry', // Baby laughter (grouped for safety)
  39: 'Baby cry, infant cry', // Screaming
  40: 'Baby cry, infant cry', // Whimper
  41: 'Baby cry, infant cry', // Crying, sobbing
  72: 'Dog',
  73: 'Dog', 
  350: 'Doorbell',
  351: 'Doorbell', 
  352: 'Doorbell', // Chime
  349: 'Doorbell', // Bell
  355: 'Doorbell', // Buzzer
  353: 'Knock',
  354: 'Knock', 
  393: 'Siren',
  394: 'Siren', 
  395: 'Fire alarm',
  396: 'Fire alarm', 
  423: 'Glass breaking',
  424: 'Glass breaking',
  425: 'Glass breaking',
  435: 'Glass breaking', // Added based on user feedback
};

// Global configuration cache
List<String> _cachedSelectedSounds = [];

Future<void> _refreshConfig() async {
  _cachedSelectedSounds = await AlertHelper.getSelectedSoundsList();
}

Future<void> runInference(Interpreter? interpreter, List<int> rawBytes) async {
  if (interpreter == null) {
      print("Interpreter is NULL! Attempting to reload...");
      try {
        interpreter = await Interpreter.fromAsset('yamnet.tflite');
      } catch (e) {
         print("Failed to load model: $e");
         return;
      }
      _interpreter = interpreter;
  }

  try {
      // Refresh watchlist every time to ensure we are responsive to UI changes
      await _refreshConfig();

      // 1. Preprocessing
      final Float32List inputFloats = Float32List(rawBytes.length ~/ 2);
      for (int i = 0; i < inputFloats.length; i++) {
        int byte1 = rawBytes[2 * i];
        int byte2 = rawBytes[2 * i + 1];
        int s16 = (byte2 << 8) | byte1;
        if (s16 >= 32768) s16 -= 65536;
        inputFloats[i] = s16 / 32768.0;
      }

      var input = inputFloats.reshape([1, 15600]);
      var output = List.filled(521, 0.0).reshape([1, 521]);
      
      interpreter.run(input, output);
      
      // 2. Post-processing: Watchlist-First detection
      List<double> scores = output[0];
      
      // Identify the strongest watchlisted sound (if any)
      String bestWatchlistedLabel = "";
      double bestWatchlistedScore = 0.0;
      for (var entry in _yamnetLabels.entries) {
        if (_cachedSelectedSounds.contains(entry.value)) {
          if (scores[entry.key] > bestWatchlistedScore) {
            bestWatchlistedScore = scores[entry.key];
            bestWatchlistedLabel = entry.value;
          }
        }
      }

      // Identify absolute top general sound for baseline/debug
      double maxGeneralScore = -1.0;
      int maxGeneralIndex = -1;
      for (int i = 0; i < scores.length; i++) {
        if (scores[i] > maxGeneralScore) {
          maxGeneralScore = scores[i];
          maxGeneralIndex = i;
        }
      }
      String topGeneralLabel = _yamnetLabels[maxGeneralIndex] ?? 'Background ($maxGeneralIndex)';

      // 3. Selection Logic: Prioritize Alerts
      String finalLabel = topGeneralLabel;
      double finalScore = maxGeneralScore;
      bool isSecureAlert = false;

      // If a watchlisted sound is heard with SIGNIFICANT confidence, we prioritize it
      // even if something else (like background speech) is technically louder.
      if (bestWatchlistedLabel.isNotEmpty && bestWatchlistedScore > 0.25) {
          finalLabel = bestWatchlistedLabel;
          finalScore = bestWatchlistedScore;
          
          // Alert decision
          double alertThreshold = 0.35; 
          if (finalLabel == 'Fire alarm' || finalLabel == 'Siren' || finalLabel == 'Baby cry, infant cry' || finalLabel == 'Glass breaking' || finalLabel == 'Doorbell') {
             alertThreshold = 0.25; // High sensitivity for safety-critical sounds
          }
          
          if (finalScore >= alertThreshold) {
            isSecureAlert = true;
          }
      }

      if (finalScore < 0.15) return;

      print('DETECTION: $finalLabel (${(finalScore * 100).toStringAsFixed(1)}%) [TopGeneral: $topGeneralLabel]');

      // 4. Reporting
      if (_service != null) {
        _service!.invoke('sound_detected', {
          'label': finalLabel,
          'confidence': finalScore,
          'is_alert': isSecureAlert,
        });
      }
      
      if (isSecureAlert) {
          print('>>> STRIKE: Triggering Emergency SMS for $finalLabel <<<');
          await AlertHelper.triggerAlert(finalLabel);
      } 
  } catch (e, stackTrace) {
      print("Inference error: $e");
      print(stackTrace);
  }
}



Future<void> initializeService({bool startNow = false}) async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      foregroundServiceNotificationId: 888,
      notificationChannelId: 'silent_guard_service', // must match createNotificationChannel
      initialNotificationTitle: 'Silent Guard',
      initialNotificationContent: 'Initializing...',
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: (ServiceInstance service) {
          // iOS background processing is limited
          return true;
      },
    ),
  );
  
  if (startNow) {
    // Small delay to ensure configuration is complete
    await Future.delayed(const Duration(milliseconds: 500));
    await service.startService();
  }

}

