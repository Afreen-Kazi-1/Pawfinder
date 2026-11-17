import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/pet_image_card.dart';
import '../models/match_model.dart';
import 'match_detail_screen.dart';

class MatchCard extends StatelessWidget {
  final MatchModel match;
  final VoidCallback onMarkRelevant;
  final VoidCallback onDismiss;

  const MatchCard({
    super.key,
    required this.match,
    required this.onMarkRelevant,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final lost = match.lostReport;
    final found = match.foundReport;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MatchDetailScreen(match: match),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Score indicator + Category badge + Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Circular Score Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: match.isHighPotential
                          ? AppColors.primary
                          : (match.matchScore >= 60.0 ? AppColors.secondary : Colors.grey),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${match.matchScore.toStringAsFixed(0)}% MATCH',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(match.status).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _getStatusColor(match.status)),
                    ),
                    child: Text(
                      match.status,
                      style: TextStyle(
                        color: _getStatusColor(match.status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Side-by-side or stacked summary of Lost vs Found
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    // Lost Report Side
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (lost != null && lost.images.isNotEmpty) ...[
                            PetImageCard(
                              imageUrl: lost.images.first.imageUrl,
                              width: 64,
                              height: 64,
                              borderRadius: 8,
                            ),
                            const SizedBox(height: 8),
                          ],
                          Row(
                            children: const [
                              Icon(Icons.search, size: 14, color: AppColors.secondary),
                              SizedBox(width: 4),
                              Text(
                                'LOST REPORT',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lost?.petName ?? (lost?.animalType ?? 'Pet'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${lost?.breed ?? "Unknown"} • ${lost?.color ?? ""}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            lost?.locationLabel ?? '',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const VerticalDivider(width: 16),
                    // Found Report Side
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (found != null && found.images.isNotEmpty) ...[
                            PetImageCard(
                              imageUrl: found.images.first.imageUrl,
                              width: 64,
                              height: 64,
                              borderRadius: 8,
                            ),
                            const SizedBox(height: 8),
                          ],
                          Row(
                            children: const [
                              Icon(Icons.pets, size: 14, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text(
                                'FOUND REPORT',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            found?.petName ?? 'Found ${found?.animalType ?? "Animal"}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${found?.breed ?? "Unknown"} • ${found?.color ?? ""}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            found?.locationLabel ?? '',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              // Disclaimer Notice
              const Text(
                'Note: Match recommendations are automated similarity suggestions and do not confirm identity.',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic),
              ),

              // Action Buttons
              if (match.status != 'Resolved') ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (match.status != 'Dismissed')
                      TextButton.icon(
                        icon: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                        label: const Text('Dismiss', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                        onPressed: onDismiss,
                      ),
                    if (match.status != 'Relevant')
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Mark Relevant', style: TextStyle(fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: onMarkRelevant,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Relevant':
        return AppColors.success;
      case 'Dismissed':
        return Colors.grey;
      case 'Resolved':
        return Colors.blue;
      default:
        return AppColors.primary;
    }
  }
}
