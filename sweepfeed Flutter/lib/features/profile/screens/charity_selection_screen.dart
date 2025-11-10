import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/charity_model.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_indicator.dart';

final availableCharitiesProvider = FutureProvider<List<Charity>>(
    (ref) async => ref.watch(charityServiceProvider).getAvailableCharities());

class CharitySelectionScreen extends ConsumerWidget {
  const CharitySelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final charitiesAsync = ref.watch(availableCharitiesProvider);
    final userProfile = ref.watch(userProfileProvider).value;
    final selectedCharityId = userProfile?.selectedCharityId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support a Charity'),
        backgroundColor: AppColors.primaryMedium,
      ),
      backgroundColor: AppColors.primaryDark,
      body: charitiesAsync.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (err, stack) => Center(
          child: Text(
            'Could not load charities: $err',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        data: (charities) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: charities.length,
          itemBuilder: (context, index) {
            final charity = charities[index];
            final isSelected = charity.id == selectedCharityId;
            return _buildCharityTile(context, ref, charity, isSelected);
          },
        ),
      ),
    );
  }

  Widget _buildCharityTile(
    BuildContext context,
    WidgetRef ref,
    Charity charity,
    bool isSelected,
  ) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.15)
              : AppColors.primaryMedium,
          borderRadius: BorderRadius.circular(12),
          border:
              isSelected ? Border.all(color: AppColors.accent, width: 2) : null,
        ),
        child: ListTile(
          leading: const CircleAvatar(
            // In a real app, you'd use a CachedNetworkImageProvider
            backgroundColor: Colors.white,
            child: Icon(
              Icons.volunteer_activism,
              color: AppColors.primaryDark,
            ),
          ),
          title: Text(
            charity.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            charity.description,
            style: const TextStyle(color: AppColors.textLight),
          ),
          trailing: isSelected
              ? const Icon(Icons.check_circle, color: AppColors.accent)
              : null,
          onTap: () async {
            final userId = ref.read(firebaseAuthProvider).currentUser?.uid;
            if (userId != null) {
              // Update the user's profile in Firestore
              await ref
                  .read(firestoreProvider)
                  .collection('users')
                  .doc(userId)
                  .update({
                'selectedCharityId': charity.id,
              });
              // Refresh the user profile provider to reflect the change immediately
              ref.refresh(userProfileProvider);
              Navigator.of(context).pop();
            }
          },
        ),
      );
}
