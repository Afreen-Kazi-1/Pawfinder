import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_display.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/pet_image_card.dart';
import '../models/pet_report_model.dart';
import '../providers/report_provider.dart';
import 'report_details_screen.dart';

class MyReportsScreen extends ConsumerStatefulWidget {
  const MyReportsScreen({super.key});

  @override
  ConsumerState<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends ConsumerState<MyReportsScreen> {
  String? _selectedType;
  String? _selectedStatus;

  final List<String> _typeFilters = ['All Types', 'Lost Reports', 'Found Reports'];
  final List<String> _statusFilters = ['All Statuses', 'Open', 'Under Review', 'Resolved', 'Closed'];

  void _applyFilter() {
    String? typeParam;
    if (_selectedType == 'Lost Reports') typeParam = 'LOST';
    if (_selectedType == 'Found Reports') typeParam = 'FOUND';

    String? statusParam;
    if (_selectedStatus != null && _selectedStatus != 'All Statuses') {
      statusParam = _selectedStatus;
    }

    ref.read(myReportsFilterProvider.notifier).setFilter(MyReportsFilter(
      reportType: typeParam,
      status: statusParam,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(myReportsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Reports History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(myReportsProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bars (Type & Status)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _typeFilters.map((t) {
                      final isSelected = (_selectedType == null && t == 'All Types') || _selectedType == t;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(t),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              _selectedType = t == 'All Types' ? null : t;
                            });
                            _applyFilter();
                          },
                          selectedColor: AppColors.primary.withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 6),
                // Status chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statusFilters.map((s) {
                      final isSelected = (_selectedStatus == null && s == 'All Statuses') || _selectedStatus == s;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(s),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              _selectedStatus = s == 'All Statuses' ? null : s;
                            });
                            _applyFilter();
                          },
                          selectedColor: AppColors.secondary.withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.secondaryDark : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // List Body
          Expanded(
            child: reportsAsync.when(
              loading: () => const LoadingIndicator(message: 'Loading your pet reports...'),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: ErrorDisplay(
                    message: err.toString(),
                    onRetry: () => ref.invalidate(myReportsProvider),
                  ),
                ),
              ),
              data: (reports) {
                if (reports.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.assignment_outlined,
                    title: 'No Reports Found',
                    message: 'No reports match your selected type and status filters.',
                    actionText: 'Reset Filters',
                    onAction: () {
                      setState(() {
                        _selectedType = null;
                        _selectedStatus = null;
                      });
                      _applyFilter();
                    },
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: reports.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    return _ReportCard(report: report);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final PetReportModel report;

  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final formattedDate = dateFormat.format(report.eventDatetime.toLocal());

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ReportDetailsScreen(report: report),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              PetImageCard(
                imageUrl: report.images.isNotEmpty ? report.images.first.imageUrl : null,
                width: 90,
                height: 90,
                borderRadius: 12,
              ),
              const SizedBox(width: 14),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status & Type Badge Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: report.isLost
                                ? AppColors.secondary.withValues(alpha: 0.15)
                                : AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            report.reportType.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: report.isLost ? AppColors.secondaryDark : AppColors.primary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _getStatusColor(report.status).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _getStatusColor(report.status)),
                          ),
                          child: Text(
                            report.status,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(report.status),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Title
                    Text(
                      report.petName ?? '${report.animalType} (${report.breed ?? "Unknown"})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),

                    // Location
                    Text(
                      report.locationLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Date
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Open':
        return AppColors.success;
      case 'Under Review':
        return AppColors.warning;
      case 'Reunited / Resolved':
      case 'Resolved':
        return Colors.blue;
      case 'Closed':
        return Colors.grey;
      default:
        return AppColors.textSecondary;
    }
  }
}
