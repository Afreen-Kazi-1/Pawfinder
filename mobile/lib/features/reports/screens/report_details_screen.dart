import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/pet_image_card.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../authentication/providers/auth_provider.dart';
import '../models/pet_report_model.dart';
import '../providers/report_provider.dart';

class ReportDetailsScreen extends ConsumerStatefulWidget {
  final PetReportModel report;

  const ReportDetailsScreen({
    super.key,
    required this.report,
  });

  @override
  ConsumerState<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends ConsumerState<ReportDetailsScreen> {
  late PetReportModel _currentReport;
  int _activeImageIndex = 0;
  bool _isLoadingAction = false;

  @override
  void initState() {
    super.initState();
    _currentReport = widget.report;
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isLoadingAction = true);
    try {
      final repo = ref.read(reportRepositoryProvider);
      final updated = await repo.updateStatus(id: _currentReport.id, newStatus: newStatus);
      if (mounted) {
        setState(() {
          _currentReport = updated;
          _isLoadingAction = false;
        });
        ref.invalidate(myReportsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $newStatus')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAction = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  Future<void> _deleteReport() async {
    ConfirmationDialog.show(
      context,
      title: 'Delete Pet Report',
      content: 'Are you sure you want to delete this report? This action cannot be undone.',
      confirmText: 'Delete',
      confirmColor: AppColors.error,
      onConfirm: () async {
        setState(() => _isLoadingAction = true);
        try {
          final repo = ref.read(reportRepositoryProvider);
          await repo.deleteReport(_currentReport.id);
          ref.invalidate(myReportsProvider);
          if (mounted) {
            Navigator.of(context).pop(); // Back to previous list
          }
        } catch (e) {
          if (mounted) {
            setState(() => _isLoadingAction = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete report: $e')),
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(authProvider).user?.id;
    final isOwner = currentUserId != null && currentUserId == _currentReport.userId;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_currentReport.isLost ? 'Lost Pet Details' : 'Found Animal Details'),
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              tooltip: 'Delete Report',
              onPressed: _isLoadingAction ? null : _deleteReport,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Images Carousel / Card
            if (_currentReport.images.isNotEmpty) ...[
              PetImageCard(
                imageUrl: _currentReport.images[_activeImageIndex].imageUrl,
                height: 240,
              ),
              if (_currentReport.images.length > 1) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 60,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _currentReport.images.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final img = _currentReport.images[index];
                      final isSelected = index == _activeImageIndex;
                      return GestureDetector(
                        onTap: () => setState(() => _activeImageIndex = index),
                        child: Container(
                          width: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(img.imageUrl, fit: BoxFit.cover),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ] else ...[
              const PetImageCard(height: 180),
            ],
            const SizedBox(height: 16),

            // Badges row (Report Type + Status)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _currentReport.isLost
                        ? AppColors.secondary.withValues(alpha: 0.15)
                        : AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _currentReport.reportType.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _currentReport.isLost ? AppColors.secondaryDark : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _currentReport.isOpen
                        ? AppColors.success.withValues(alpha: 0.15)
                        : AppColors.textSecondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _currentReport.status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _currentReport.isOpen ? AppColors.success : AppColors.textSecondary,
                    ),
                  ),
                ),
                if (_currentReport.reward != null && _currentReport.reward! > 0) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade700),
                    ),
                    child: Text(
                      'Reward: \$${_currentReport.reward!.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Pet Title
            Text(
              _currentReport.petName ?? '${_currentReport.animalType} (${_currentReport.reportType})',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Attributes Card
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow('Animal Type', _currentReport.animalType),
                    const Divider(height: 16),
                    _buildInfoRow('Breed', _currentReport.breed ?? 'Unknown'),
                    const Divider(height: 16),
                    _buildInfoRow('Color', _currentReport.color),
                    const Divider(height: 16),
                    _buildInfoRow('Gender', _currentReport.gender ?? 'Unknown'),
                    const Divider(height: 16),
                    _buildInfoRow('Approximate Age', _currentReport.approximateAge ?? 'Not specified'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Distinguishing Features
            const Text(
              'Distinguishing Features',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              _currentReport.distinguishingFeatures.isNotEmpty
                  ? _currentReport.distinguishingFeatures
                  : 'None specified.',
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),

            // Description
            const Text(
              'Description & Observations',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              _currentReport.description.isNotEmpty ? _currentReport.description : 'None provided.',
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),

            // Location & Date
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, color: AppColors.primary, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentReport.locationLabel,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Coordinates: ${_currentReport.latitude.toStringAsFixed(4)}, ${_currentReport.longitude.toStringAsFixed(4)}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.event, color: AppColors.primary, size: 22),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('MMMM dd, yyyy - hh:mm a').format(_currentReport.eventDatetime),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Status Management Actions (for report owner)
            if (isOwner && _currentReport.isOpen) ...[
              PrimaryButton(
                text: 'Mark as Reunited / Resolved',
                icon: Icons.check_circle_outline,
                isLoading: _isLoadingAction,
                onPressed: () => _updateStatus('Reunited / Resolved'),
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                text: 'Close Report',
                isLoading: _isLoadingAction,
                onPressed: () => _updateStatus('Closed'),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ],
    );
  }
}
