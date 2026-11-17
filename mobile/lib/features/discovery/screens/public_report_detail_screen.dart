import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../reports/models/pet_report_model.dart';
import '../../contact_requests/widgets/contact_request_dialog.dart';
import '../../moderation/widgets/report_abuse_dialog.dart';

class PublicReportDetailScreen extends StatelessWidget {
  final PetReportModel report;

  const PublicReportDetailScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy • h:mm a');
    final formattedDate = dateFormat.format(report.eventDatetime.toLocal());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(report.petName ?? '${report.animalType} Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report link copied to clipboard')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.flag_outlined, color: AppColors.error),
            tooltip: 'Report Listing',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => ReportAbuseDialog(
                  petReportId: report.id,
                  entityTitle: 'Report for ${report.petName ?? report.animalType}',
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Carousel / Hero Image
            if (report.images.isNotEmpty)
              SizedBox(
                height: 280,
                child: PageView.builder(
                  itemCount: report.images.length,
                  itemBuilder: (context, index) {
                    return Image.network(
                      report.images[index].imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                    );
                  },
                ),
              )
            else
              _buildPlaceholder(height: 220),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: report.isLost ? AppColors.secondary : AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          report.reportType.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          report.status,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (report.isLost && report.reward != null && report.reward! > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade700,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Reward: \$${report.reward!.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Pet Name / Title
                  Text(
                    report.petName?.isNotEmpty == true
                        ? report.petName!
                        : '${report.animalType} (Name Unknown)',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Location Label
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 20, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          report.locationLabel,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Date
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      Text(
                        formattedDate,
                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // Attributes Grid
                  const Text(
                    'Pet Characteristics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    color: AppColors.surfaceVariant,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildDetailRow('Animal Type', report.animalType),
                          const Divider(height: 16),
                          _buildDetailRow('Breed', report.breed ?? 'Unknown / Not specified'),
                          const Divider(height: 16),
                          _buildDetailRow('Color', report.color),
                          const Divider(height: 16),
                          _buildDetailRow('Gender', report.gender ?? 'Unknown'),
                          if (report.approximateAge != null && report.approximateAge!.isNotEmpty) ...[
                            const Divider(height: 16),
                            _buildDetailRow('Age', report.approximateAge!),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Distinguishing Features
                  if (report.distinguishingFeatures.isNotEmpty) ...[
                    const Text(
                      'Distinguishing Features',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      report.distinguishingFeatures,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Description
                  if (report.description.isNotEmpty) ...[
                    const Text(
                      'Description & Circumstances',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      report.description,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Contact / Help Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: Text(
                        report.isLost ? 'I Have Found This Pet' : 'This Is My Pet',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: report.isLost ? AppColors.secondary : AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => ContactRequestDialog(
                            reportId: report.id,
                            petDisplayName: report.petName ?? report.animalType,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 14)),
      ],
    );
  }

  Widget _buildPlaceholder({double height = 220}) {
    return Container(
      height: height,
      color: AppColors.surfaceVariant,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              report.isLost ? Icons.search : Icons.pets,
              size: 56,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 8),
            const Text(
              'No photo available',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
