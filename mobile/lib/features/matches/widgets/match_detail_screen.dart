import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../models/match_model.dart';
import '../providers/match_provider.dart';

class MatchDetailScreen extends ConsumerStatefulWidget {
  final MatchModel match;

  const MatchDetailScreen({super.key, required this.match});

  @override
  ConsumerState<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends ConsumerState<MatchDetailScreen> {
  late MatchModel _match;

  @override
  void initState() {
    super.initState();
    _match = widget.match;
  }

  void _updateStatus(String newStatus) async {
    await ref.read(matchesProvider.notifier).updateStatus(_match.id, newStatus);
    setState(() {
      _match = _match.copyWith(status: newStatus);
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Match marked as $newStatus')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lost = _match.lostReport;
    final found = _match.foundReport;
    final reasons = _match.matchReasons;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Match Analysis'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _match.isHighPotential
                      ? [AppColors.primary, AppColors.primaryDark]
                      : [AppColors.secondary, AppColors.secondaryDark],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Text(
                      '${_match.matchScore.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _match.isHighPotential ? AppColors.primary : AppColors.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _match.matchCategory.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Status: ${_match.status}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Comparison of Lost vs Found Characteristics
            const Text(
              'Side-by-Side Comparison',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            _buildComparisonTable(lost, found),
            const SizedBox(height: 24),

            // Scoring Reasons & Breakdown
            const Text(
              'Match Scoring Criteria',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            _buildReasonTile('Animal Type (25%)', reasons['animal_type']),
            _buildReasonTile('Breed Similarity (15%)', reasons['breed']),
            _buildReasonTile('Color Similarity (15%)', reasons['color']),
            _buildReasonTile('Location Proximity (20%)', reasons['location']),
            _buildReasonTile('Date Proximity (10%)', reasons['date']),
            _buildReasonTile('Distinguishing Features & Description (15%)', reasons['description']),
            const SizedBox(height: 24),

            // Actions
            if (_match.status != 'Resolved') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateStatus('Dismissed'),
                      child: const Text('Dismiss Match'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _updateStatus('Relevant'),
                      child: const Text('Mark Relevant'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Resolve Match (Reunited)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _updateStatus('Resolved'),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonTable(dynamic lost, dynamic found) {
    return Card(
      elevation: 0,
      color: AppColors.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: const [
                Expanded(child: SizedBox()),
                Expanded(
                  child: Text('LOST PET',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary, fontSize: 12)),
                ),
                Expanded(
                  child: Text('FOUND PET',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12)),
                ),
              ],
            ),
            const Divider(),
            _buildRow('Animal', lost?.animalType, found?.animalType),
            _buildRow('Breed', lost?.breed, found?.breed),
            _buildRow('Color', lost?.color, found?.color),
            _buildRow('Location', lost?.locationLabel, found?.locationLabel),
            _buildRow('Features', lost?.distinguishingFeatures, found?.distinguishingFeatures),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String attribute, String? valLost, String? valFound) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(attribute, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          Expanded(
            child: Text(valLost ?? 'N/A', style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            child: Text(valFound ?? 'N/A', style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonTile(String title, dynamic data) {
    final score = data != null ? data['score'] : null;
    final explanation = data != null ? data['explanation'] : 'N/A';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            if (score != null)
              Text(
                '${score.toString()}/100',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(explanation.toString(), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ),
      ),
    );
  }
}

