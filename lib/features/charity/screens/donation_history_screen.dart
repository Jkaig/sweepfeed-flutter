import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/donation_model.dart';
import '../../../core/providers/providers.dart';

class DonationHistoryScreen extends ConsumerWidget {
  const DonationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donationHistoryAsync = ref.watch(donationHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Donation History'),
      ),
      body: donationHistoryAsync.when(
        data: (donations) {
          if (donations.isEmpty) {
            return const Center(
              child: Text("You haven't made any donations yet."),
            );
          }
          return ListView.builder(
            itemCount: donations.length,
            itemBuilder: (context, index) {
              final donation = donations[index];
              return ListTile(
                title: Text('Donation to ${donation.charityId}'),
                subtitle: Text(
                  DateFormat.yMMMd().add_jm().format(donation.timestamp),
                ),
                trailing: Text(
                  '\$${donation.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const Center(
          child: Text('Error loading donation history'),
        ),
      ),
    );
  }
}

final donationHistoryProvider = FutureProvider<List<Donation>>((ref) async {
  final charityService = ref.watch(charityServiceProvider);
  // TODO: Get the current user's ID
  return charityService.getDonationHistory('user123');
});
