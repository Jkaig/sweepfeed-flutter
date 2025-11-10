import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../utils/logger.dart';

class RemoteConfigService {
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();
  static final RemoteConfigService _instance = RemoteConfigService._internal();

  FirebaseRemoteConfig? _remoteConfig;
  bool _initialized = false;

  static const String adFrequencyType = 'ad_frequency_type';
  static const String adFrequencyValue = 'ad_frequency_value';

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _remoteConfig = FirebaseRemoteConfig.instance;

      await _remoteConfig!.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );

      await _remoteConfig!.setDefaults({
        adFrequencyType: 'entry',
        adFrequencyValue: 3,
      });

      await _remoteConfig!.fetchAndActivate();
      _initialized = true;

      logger.i('Remote Config initialized successfully');
      logger
          .d('Ad Frequency Type: ${_remoteConfig!.getString(adFrequencyType)}');
      logger
          .d('Ad Frequency Value: ${_remoteConfig!.getInt(adFrequencyValue)}');
    } catch (e) {
      logger.e('Error initializing Remote Config', error: e);
    }
  }

  String getAdFrequencyType() =>
      _remoteConfig?.getString(adFrequencyType) ?? 'entry';

  int getAdFrequencyValue() => _remoteConfig?.getInt(adFrequencyValue) ?? 3;

  bool shouldShowAd(int entryCount) {
    final type = getAdFrequencyType();
    final value = getAdFrequencyValue();

    if (type == 'entry' && value > 0) {
      return entryCount % value == 0;
    }

    return false;
  }

  Future<void> refresh() async {
    try {
      await _remoteConfig?.fetchAndActivate();
      logger.i('Remote Config refreshed');
    } catch (e) {
      logger.e('Error refreshing Remote Config', error: e);
    }
  }
}

final remoteConfigService = RemoteConfigService();
