import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BranchService {
  Future<void> init() async {
    FlutterBranchSdk.init();
  }

  Future<String> createDeepLink(String sweepstakeId) async {
    final buo = BranchUniversalObject(
      canonicalIdentifier: 'sweepstake/$sweepstakeId',
      title: 'Check out this sweepstake!',
      contentDescription: 'You can win amazing prizes!',
    );

    final lp = BranchLinkProperties(
      channel: 'sms',
      feature: 'sharing',
    );

    final response = await FlutterBranchSdk.getShortUrl(buo: buo, linkProperties: lp);

    if (response.success) {
      return response.result;
    } else {
      throw Exception('Failed to create deep link: ${response.errorMessage}');
    }
  }

  Stream<Map> listenToDeepLinks() => FlutterBranchSdk.listSession();
}

final branchServiceProvider = Provider<BranchService>((ref) => BranchService());
