import 'package:contacts_service_plus/contacts_service_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/branch_service.dart';
import '../../../core/services/contacts_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({this.sweepstakeId, super.key});

  final String? sweepstakeId;

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  @override
  void initState() {
    super.initState();
    // Check permission status on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissionStatus();
    });
  }

  Future<void> _checkPermissionStatus() async {
    final status = await Permission.contacts.status;
    
    if (status.isDenied) {
      // Show permission request dialog
      if (mounted) {
        _showPermissionRequestDialog();
      }
    } else if (status.isPermanentlyDenied) {
      // Show settings dialog
      if (mounted) {
        _showSettingsDialog();
      }
    }
  }

  void _showPermissionRequestDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryDark,
        title: Text(
          'Access Contacts',
          style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
        ),
        content: Text(
          'SweepFeed needs access to your contacts to help you find and invite friends. This makes it easier to share contests and compete together!',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Not Now',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final status = await Permission.contacts.request();
              if (status.isGranted) {
                // Refresh contacts
                ref.invalidate(contactsProvider);
              } else if (status.isPermanentlyDenied) {
                if (mounted) {
                  _showSettingsDialog();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandCyan,
            ),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryDark,
        title: Text(
          'Permission Required',
          style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
        ),
        content: Text(
          'Contacts permission was denied. Please enable it in your device settings to find and invite friends.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await openAppSettings();
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandCyan,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(contactsProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: const Text('Find Friends'),
        backgroundColor: AppColors.primaryDark,
      ),
      body: contactsAsync.when(
        data: (contacts) {
          if (contacts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.contacts_outlined,
                    size: 64,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No contacts found',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Make sure contacts permission is enabled',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      final status = await Permission.contacts.request();
                      if (status.isGranted) {
                        ref.invalidate(contactsProvider);
                      } else if (status.isPermanentlyDenied) {
                        _showSettingsDialog();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandCyan,
                    ),
                    child: const Text('Request Permission'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    contact.displayName?.isNotEmpty == true
                        ? contact.displayName![0].toUpperCase()
                        : '?',
                    style: TextStyle(color: AppColors.brandCyan),
                  ),
                ),
                title: Text(
                  contact.displayName ?? 'Unknown',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white,
                  ),
                ),
                subtitle: Text(
                  contact.phones?.isNotEmpty == true
                      ? contact.phones!.first.value ?? ''
                      : 'No phone number',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                trailing: ElevatedButton(
                  onPressed: () {
                    final phone = contact.phones?.first.value;
                    if (phone != null) {
                      _sendInvitation(phone, ref);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandCyan,
                  ),
                  child: const Text('Invite'),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.errorRed,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading contacts',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(contactsProvider);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandCyan,
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendInvitation(String phone, WidgetRef ref) async {
    final branchService = ref.read(branchServiceProvider);
    final link = await branchService.createDeepLink(widget.sweepstakeId ?? '');
    final message = widget.sweepstakeId != null
        ? 'Check out this sweepstake: $link'
        : 'Join me on SweepFeed! $link';
    final url = 'sms:$phone?body=$message';
    launch(url);
  }
}

final contactsProvider = FutureProvider<List<Contact>>((ref) async {
  final contactsService = ref.watch(contactsServiceProvider);
  final permission = await Permission.contacts.status;
  if (permission.isGranted) {
    return ContactsService.getContacts();
  }
  return [];
});