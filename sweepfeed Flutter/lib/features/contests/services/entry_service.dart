import 'package:url_launcher/url_launcher.dart';
import '../models/sweepstakes_model.dart';
import '../../tracking/services/tracking_service.dart';
import '../../../core/models/sweepstake.dart';

class EntryService {
  final TrackingService _trackingService;

  EntryService(this._trackingService);

  Future<void> enterSweepstakes(Sweepstakes sweepstakes) async {
    // Track the entry
    await _trackingService.trackEntry(sweepstakes);

    // Launch the entry URL
    final Uri url = Uri.parse(sweepstakes.entryUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    } else {
      throw Exception('Could not launch ${sweepstakes.entryUrl}');
    }
  }

  bool canEnterDaily(Sweepstakes sweepstakes) {
    if (!sweepstakes.isDailyEntry) return true;

    final lastEntry = _trackingService.trackedEntries[sweepstakes.id];
    if (lastEntry == null) return true;

    return DateTime.now().difference(lastEntry).inHours >= 24;
  }
}
