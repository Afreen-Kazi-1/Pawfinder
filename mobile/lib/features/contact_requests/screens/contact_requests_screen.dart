import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../models/contact_request_model.dart';
import '../providers/contact_request_provider.dart';

class ContactRequestsScreen extends ConsumerWidget {
  const ContactRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(contactRequestsProvider);
    final notifier = ref.read(contactRequestsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Contact Requests'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Segmented Tabs: Received vs Sent
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    context: context,
                    title: 'Received',
                    icon: Icons.inbox_rounded,
                    isSelected: state.activeTab == ContactRequestTab.received,
                    onTap: () => notifier.setTab(ContactRequestTab.received),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTabButton(
                    context: context,
                    title: 'Sent',
                    icon: Icons.outbox_rounded,
                    isSelected: state.activeTab == ContactRequestTab.sent,
                    onTap: () => notifier.setTab(ContactRequestTab.sent),
                  ),
                ),
              ],
            ),
          ),

          // Content body
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => notifier.loadRequests(),
              child: _buildBody(context, state, notifier),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ContactRequestsState state,
    ContactRequestsNotifier notifier,
  ) {
    if (state.isLoading && state.requests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => notifier.loadRequests(),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.requests.isEmpty) {
      final isReceived = state.activeTab == ContactRequestTab.received;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isReceived ? Icons.mail_outline : Icons.outgoing_mail,
              size: 54,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              isReceived ? 'No received requests yet' : 'You haven\'t sent any requests',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isReceived
                  ? 'When users reach out about your reports, they will show up here.'
                  : 'You can contact report owners directly from pet details.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: state.requests.length,
      itemBuilder: (context, index) {
        final request = state.requests[index];
        return _buildRequestCard(context, request, state.activeTab, notifier);
      },
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    ContactRequestModel request,
    ContactRequestTab tab,
    ContactRequestsNotifier notifier,
  ) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final formattedDate = dateFormat.format(request.createdAt.toLocal());
    final isReceived = tab == ContactRequestTab.received;
    final otherPartyName = isReceived ? request.sender.name : request.receiver.name;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Status badge & timestamp
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusChip(request.status),
                Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Pet Report Preview (if available)
            if (request.report != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.pets, size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Report: ${request.report!.petName ?? request.report!.animalType} (${request.report!.reportType})',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // User Info
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    otherPartyName.isNotEmpty ? otherPartyName[0].toUpperCase() : 'U',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isReceived ? 'From: $otherPartyName' : 'To: $otherPartyName',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Message text
            if (request.message != null && request.message!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.surfaceVariant),
                ),
                child: Text(
                  request.message!,
                  style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Approved Contact Info View (Shown upon ACCEPTANCE)
            if (request.isAccepted) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lock_open_rounded, size: 16, color: AppColors.success),
                        SizedBox(width: 6),
                        Text(
                          'Approved Contact Details',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (isReceived && request.senderContactInfo != null)
                      Text('Sender Contact: ${request.senderContactInfo}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    if (!isReceived && request.receiverContactInfo != null)
                      Text('Owner Contact: ${request.receiverContactInfo}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Action Buttons
            if (isReceived && request.isPending) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _confirmAction(
                        context,
                        title: 'Decline Request',
                        content: 'Are you sure you want to decline this contact request?',
                        onConfirm: () => notifier.rejectRequest(request.id),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _showAcceptDialog(context, request, notifier),
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ] else if (!isReceived && request.isPending) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _confirmAction(
                    context,
                    title: 'Cancel Request',
                    content: 'Cancel this pending request to the pet owner?',
                    onConfirm: () => notifier.cancelRequest(request.id),
                  ),
                  child: const Text('Cancel Request'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg;
    Color fg;
    String label = status.toUpperCase();

    switch (status.toLowerCase()) {
      case 'accepted':
        bg = AppColors.success.withValues(alpha: 0.15);
        fg = AppColors.success;
        break;
      case 'rejected':
        bg = AppColors.error.withValues(alpha: 0.15);
        fg = AppColors.error;
        break;
      case 'cancelled':
        bg = AppColors.surfaceVariant;
        fg = AppColors.textSecondary;
        break;
      case 'pending':
      default:
        bg = AppColors.warning.withValues(alpha: 0.15);
        fg = AppColors.warning;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _confirmAction(
    BuildContext context, {
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('No')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirm();
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _showAcceptDialog(
    BuildContext context,
    ContactRequestModel request,
    ContactRequestsNotifier notifier,
  ) {
    final contactCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Accept Contact Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Accepting will securely exchange contact information with this user.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: contactCtrl,
              decoration: InputDecoration(
                labelText: 'Your Contact Method (Optional)',
                hintText: 'e.g. Phone number or email',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                helperText: 'Defaults to profile phone/email if blank',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              notifier.acceptRequest(
                request.id,
                receiverContactInfo:
                    contactCtrl.text.trim().isNotEmpty ? contactCtrl.text.trim() : null,
              );
            },
            child: const Text('Confirm & Share'),
          ),
        ],
      ),
    );
  }
}
