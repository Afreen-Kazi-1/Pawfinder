import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../models/abuse_report_model.dart';
import '../providers/moderation_provider.dart';

class AdminModerationScreen extends ConsumerStatefulWidget {
  const AdminModerationScreen({super.key});

  @override
  ConsumerState<AdminModerationScreen> createState() => _AdminModerationScreenState();
}

class _AdminModerationScreenState extends ConsumerState<AdminModerationScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(moderationProvider.notifier).loadReports());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(moderationProvider);
    final notifier = ref.read(moderationProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Moderation Queue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Queue',
            onPressed: () => notifier.loadReports(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', null, state.statusFilter, notifier),
                  const SizedBox(width: 8),
                  _buildFilterChip('Pending', 'pending', state.statusFilter, notifier),
                  const SizedBox(width: 8),
                  _buildFilterChip('Under Review', 'under_review', state.statusFilter, notifier),
                  const SizedBox(width: 8),
                  _buildFilterChip('Resolved', 'resolved', state.statusFilter, notifier),
                  const SizedBox(width: 8),
                  _buildFilterChip('Dismissed', 'dismissed', state.statusFilter, notifier),
                ],
              ),
            ),
          ),

          // Main Body
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => notifier.loadReports(),
              child: _buildContent(context, state, notifier),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String? statusValue,
    String? currentFilter,
    ModerationNotifier notifier,
  ) {
    final isSelected = currentFilter == statusValue;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => notifier.setFilter(statusValue),
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ModerationState state,
    ModerationNotifier notifier,
  ) {
    if (state.isLoading && state.reports.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.reports.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.security, size: 52, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => notifier.loadReports(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.reports.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_user_outlined, size: 56, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text(
              'Moderation queue clear!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
            SizedBox(height: 6),
            Text(
              'No abuse reports matching the current filter.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.reports.length,
      itemBuilder: (context, index) {
        final report = state.reports[index];
        return _buildModerationCard(context, report, notifier);
      },
    );
  }

  Widget _buildModerationCard(
    BuildContext context,
    AbuseReportModel report,
    ModerationNotifier notifier,
  ) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final formattedDate = dateFormat.format(report.createdAt.toLocal());

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and timestamp
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusChip(report.status),
                Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Target information
            if (report.petName != null || report.petReportId != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.pets, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Target Listing: ${report.petName ?? "Pet Listing"}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Reporter & Reported party
            Text(
              'Reporter: ${report.reporterName ?? "User"}\nReported: ${report.reportedUserName ?? "User"}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 10),

            // Reason
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.surfaceVariant),
              ),
              child: Text(
                report.reason,
                style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 14),

            // Action Buttons for Admin
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!report.isUnderReview && !report.isResolved && !report.isDismissed)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.manage_search, size: 16),
                    label: const Text('Review'),
                    onPressed: () => notifier.updateStatus(report.id, 'under_review'),
                  ),
                if (!report.isResolved)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Resolve (Action Taken)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => notifier.updateStatus(report.id, 'resolved'),
                  ),
                if (!report.isDismissed)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Dismiss'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.textSecondary),
                    onPressed: () => notifier.updateStatus(report.id, 'dismissed'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg;
    Color fg;
    String label = status.replaceAll('_', ' ').toUpperCase();

    switch (status.toLowerCase()) {
      case 'resolved':
        bg = AppColors.success.withValues(alpha: 0.15);
        fg = AppColors.success;
        break;
      case 'dismissed':
        bg = AppColors.surfaceVariant;
        fg = AppColors.textSecondary;
        break;
      case 'under_review':
        bg = AppColors.info.withValues(alpha: 0.15);
        fg = AppColors.info;
        break;
      case 'pending':
      default:
        bg = AppColors.error.withValues(alpha: 0.15);
        fg = AppColors.error;
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
}

