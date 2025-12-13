import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../support/models/support_ticket_model.dart';
import '../../support/services/support_service.dart';

class SupportTicketListScreen extends ConsumerWidget {
  const SupportTicketListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supportService = ref.watch(supportServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: const Text('Support Tickets'),
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
      ),
      body: StreamBuilder<List<SupportTicket>>(
        stream: supportService.getTickets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          }

          final tickets = snapshot.data ?? [];

          if (tickets.isEmpty) {
            return const Center(child: Text('No tickets found', style: TextStyle(color: Colors.white)));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: tickets.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              return _buildTicketCard(context, ticket, supportService);
            },
          );
        },
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context, SupportTicket ticket, SupportService service) => InkWell(
      onTap: () => _showTicketDetails(context, ticket, service),
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(ticket.status).withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  ticket.userName,
                  style: AppTextStyles.titleMedium.copyWith(color: AppColors.textWhite),
                ),
              ),
              _buildStatusBadge(ticket.status),
            ],
          ),
          Text(
            ticket.userEmail,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
          ),
          const SizedBox(height: 12),
          Text(
              ticket.message.length > 100 
                  ? '${ticket.message.substring(0, 100)}...' 
                  : ticket.message,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textWhite),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (ticket.adminNotes != null && ticket.adminNotes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.brandCyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.brandCyan.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.note, color: AppColors.brandCyan, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Admin Note: ${ticket.adminNotes}',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.brandCyan),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMM d, y h:mm a').format(ticket.createdAt),
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textLight),
                color: AppColors.primaryMedium,
                onSelected: (value) {
                    if (value.startsWith('status:')) {
                      service.updateTicketStatus(ticket.id, value.substring(7));
                    } else if (value == 'add_note') {
                      _showAddNoteDialog(context, ticket, service);
                    }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                      value: 'status:open',
                    child: Text('Mark Open', style: TextStyle(color: Colors.white)),
                  ),
                  const PopupMenuItem(
                      value: 'status:in_progress',
                    child: Text('Mark In Progress', style: TextStyle(color: Colors.white)),
                  ),
                  const PopupMenuItem(
                      value: 'status:resolved',
                    child: Text('Mark Resolved', style: TextStyle(color: Colors.white)),
                  ),
                  const PopupMenuItem(
                      value: 'status:closed',
                    child: Text('Close', style: TextStyle(color: Colors.white)),
                  ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'add_note',
                      child: Row(
                        children: [
                          Icon(Icons.note_add, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text('Add Note', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            ),
          ],
        ),
      ),
    );

  void _showTicketDetails(BuildContext context, SupportTicket ticket, SupportService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryMedium,
        title: Text(
          'Ticket Details',
          style: AppTextStyles.titleMedium.copyWith(color: AppColors.textWhite),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('User', ticket.userName),
              _buildDetailRow('Email', ticket.userEmail),
              _buildDetailRow('Status', ticket.status.toUpperCase()),
              _buildDetailRow('Created', DateFormat('MMM d, y h:mm a').format(ticket.createdAt)),
              if (ticket.updatedAt != null)
                _buildDetailRow('Updated', DateFormat('MMM d, y h:mm a').format(ticket.updatedAt!)),
              const SizedBox(height: 16),
              Text(
                'Message:',
                style: AppTextStyles.labelLarge.copyWith(color: AppColors.brandCyan),
              ),
              const SizedBox(height: 8),
              Text(
                ticket.message,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textWhite),
              ),
              if (ticket.adminNotes != null && ticket.adminNotes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Admin Notes:',
                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.brandCyan),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.brandCyan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ticket.adminNotes!,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textWhite),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.textLight),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showAddNoteDialog(context, ticket, service);
            },
            child: Text(
              'Add Note',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.brandCyan),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: AppTextStyles.labelMedium.copyWith(color: AppColors.textLight),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textWhite),
            ),
          ),
        ],
      ),
    );

  void _showAddNoteDialog(BuildContext context, SupportTicket ticket, SupportService service) {
    final noteController = TextEditingController(text: ticket.adminNotes ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryMedium,
        title: Text(
          'Add Admin Note',
          style: AppTextStyles.titleMedium.copyWith(color: AppColors.textWhite),
        ),
        content: TextField(
          controller: noteController,
          style: const TextStyle(color: Colors.white),
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Enter admin note...',
            hintStyle: const TextStyle(color: Colors.white54),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.brandCyan),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.brandCyan, width: 2),
            ),
            filled: true,
            fillColor: AppColors.primaryDark,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.textLight),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (noteController.text.isNotEmpty) {
                await service.addAdminNote(ticket.id, noteController.text);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Note added successfully'),
                      backgroundColor: AppColors.successGreen,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Save',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.brandCyan),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getStatusColor(status)),
      ),
      child: Text(
        status.toUpperCase().replaceAll('_', ' '),
        style: AppTextStyles.labelSmall.copyWith(
          color: _getStatusColor(status),
          fontWeight: FontWeight.bold,
        ),
      ),
    );

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
