import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum SensoryFeedbackType {
  // Button interactions
  buttonTap,
  buttonHold,
  buttonRelease,

  // Navigation
  pageSwipe,
  tabSwitch,
  drawerOpen,

  // Success/Achievement
  contestEntered,
  achievementUnlocked,
  levelUp,
  streakBroken,
  bigWin,

  // UI Feedback
  cardFlip,
  itemSelect,
  filterChange,
  refresh,
  swipeComplete,

  // Alerts
  warning,
  error,
  notification,
  celebration,
}

class SensoryFeedbackService {
  factory SensoryFeedbackService() => _instance;
  SensoryFeedbackService._internal();
  static final SensoryFeedbackService _instance =
      SensoryFeedbackService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _hapticsEnabled = true;
  bool _soundsEnabled = true;
  double _soundVolume = 0.7;

  // Initialize the service
  Future<void> initialize() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.stop);
    await _audioPlayer.setVolume(_soundVolume);
  }

  // Main method to trigger sensory feedback
  Future<void> trigger(
    SensoryFeedbackType type, {
    BuildContext? context,
  }) async {
    // Haptic feedback
    if (_hapticsEnabled) {
      _triggerHaptics(type);
    }

    // Sound feedback
    if (_soundsEnabled) {
      _triggerSound(type);
    }

    // Visual feedback (if context provided)
    if (context != null) {
      _triggerVisualFeedback(type, context);
    }
  }

  // Haptic patterns for different interactions
  void _triggerHaptics(SensoryFeedbackType type) {
    switch (type) {
      case SensoryFeedbackType.buttonTap:
      case SensoryFeedbackType.itemSelect:
      case SensoryFeedbackType.filterChange:
        HapticFeedback.lightImpact();
        break;

      case SensoryFeedbackType.buttonHold:
      case SensoryFeedbackType.cardFlip:
      case SensoryFeedbackType.tabSwitch:
        HapticFeedback.mediumImpact();
        break;

      case SensoryFeedbackType.contestEntered:
      case SensoryFeedbackType.swipeComplete:
      case SensoryFeedbackType.buttonRelease:
        HapticFeedback.heavyImpact();
        break;

      case SensoryFeedbackType.achievementUnlocked:
      case SensoryFeedbackType.levelUp:
      case SensoryFeedbackType.bigWin:
        // Complex celebration pattern
        _celebrationHaptics();
        break;

      case SensoryFeedbackType.pageSwipe:
      case SensoryFeedbackType.drawerOpen:
        HapticFeedback.selectionClick();
        break;

      case SensoryFeedbackType.refresh:
        // Double tap pattern
        HapticFeedback.lightImpact();
        Future.delayed(
            const Duration(milliseconds: 100), HapticFeedback.lightImpact);
        break;

      case SensoryFeedbackType.warning:
        HapticFeedback.mediumImpact();
        break;

      case SensoryFeedbackType.error:
      case SensoryFeedbackType.streakBroken:
        // Error pattern - heavy then light
        HapticFeedback.heavyImpact();
        Future.delayed(
            const Duration(milliseconds: 150), HapticFeedback.lightImpact);
        break;

      case SensoryFeedbackType.notification:
      case SensoryFeedbackType.celebration:
        HapticFeedback.mediumImpact();
        break;
    }
  }

  // Complex haptic patterns
  Future<void> _celebrationHaptics() async {
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    HapticFeedback.lightImpact();
  }

  // Sound effects for different interactions
  void _triggerSound(SensoryFeedbackType type) {
    // Note: In a real app, you would load actual sound files from assets
    // For demo purposes, we'll use system sounds and simulate with different durations

    switch (type) {
      case SensoryFeedbackType.buttonTap:
      case SensoryFeedbackType.itemSelect:
        SystemSound.play(SystemSoundType.click);
        break;

      case SensoryFeedbackType.contestEntered:
      case SensoryFeedbackType.swipeComplete:
        // Would play success chime
        _playCustomSound('success_chime');
        break;

      case SensoryFeedbackType.achievementUnlocked:
      case SensoryFeedbackType.levelUp:
        // Would play achievement fanfare
        _playCustomSound('achievement_fanfare');
        break;

      case SensoryFeedbackType.bigWin:
      case SensoryFeedbackType.celebration:
        // Would play celebration sound
        _playCustomSound('celebration');
        break;

      case SensoryFeedbackType.cardFlip:
        // Would play card flip sound
        _playCustomSound('card_flip');
        break;

      case SensoryFeedbackType.pageSwipe:
      case SensoryFeedbackType.tabSwitch:
        // Would play whoosh sound
        _playCustomSound('whoosh');
        break;

      case SensoryFeedbackType.error:
      case SensoryFeedbackType.streakBroken:
        // Would play error sound
        _playCustomSound('error');
        break;

      case SensoryFeedbackType.warning:
        // Would play warning beep
        _playCustomSound('warning');
        break;

      default:
        // Subtle UI sound
        SystemSound.play(SystemSoundType.click);
        break;
    }
  }

  // Custom sound playback (would use actual audio files)
  void _playCustomSound(String soundName) {
    // In a real implementation, you would:
    // await _audioPlayer.play(AssetSource('sounds/$soundName.mp3'));

    // For demo, using system click as placeholder
    SystemSound.play(SystemSoundType.click);
  }

  // Visual feedback effects
  void _triggerVisualFeedback(SensoryFeedbackType type, BuildContext context) {
    switch (type) {
      case SensoryFeedbackType.achievementUnlocked:
      case SensoryFeedbackType.levelUp:
      case SensoryFeedbackType.bigWin:
        _showCelebrationOverlay(context);
        break;

      case SensoryFeedbackType.contestEntered:
        _showSuccessRipple(context);
        break;

      case SensoryFeedbackType.error:
        _showErrorShake(context);
        break;

      default:
        // Subtle press feedback handled by widgets
        break;
    }
  }

  // Visual effect methods
  void _showCelebrationOverlay(BuildContext context) {
    // Would show particle effects or animated overlay
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 Amazing! You unlocked something special!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showSuccessRipple(BuildContext context) {
    // Would create expanding circle animation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Contest entered successfully!'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showErrorShake(BuildContext context) {
    // Would shake the widget
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('❌ Oops! Something went wrong.'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Settings
  void setHapticsEnabled(bool enabled) {
    _hapticsEnabled = enabled;
  }

  void setSoundsEnabled(bool enabled) {
    _soundsEnabled = enabled;
  }

  void setSoundVolume(double volume) {
    _soundVolume = volume.clamp(0.0, 1.0);
    _audioPlayer.setVolume(_soundVolume);
  }

  bool get hapticsEnabled => _hapticsEnabled;
  bool get soundsEnabled => _soundsEnabled;
  double get soundVolume => _soundVolume;

  // Cleanup
  void dispose() {
    _audioPlayer.dispose();
  }
}
