import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../data/discovery_repository.dart';
import '../providers/discovery_provider.dart';

class NearbyMapScreen extends ConsumerStatefulWidget {
  const NearbyMapScreen({super.key});

  @override
  ConsumerState<NearbyMapScreen> createState() => _NearbyMapScreenState();
}

class _NearbyMapScreenState extends ConsumerState<NearbyMapScreen> {
  // Configurable radius options
  final List<double> _radiusOptions = [2.0, 5.0, 10.0, 25.0, 50.0];

  @override
  void initState() {
    super.initState();
    // Simulate initial location request or default location
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestLocationOrFallback();
    });
  }

  void _requestLocationOrFallback() {
    // When real GPS is ready via geolocator, we request position.
    // Default fallback coordinate (San Francisco center: 37.7749, -122.4194)
    ref.read(nearbyProvider.notifier).setLocation(
          latitude: 37.7749,
          longitude: -122.4194,
        );
  }

  void _showManualLocationDialog() {
    final latController = TextEditingController(text: '37.7749');
    final lonController = TextEditingController(text: '-122.4194');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Location Manually'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Location permission was denied or GPS is disabled. Enter your coordinates to find nearby reports:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: latController,
              decoration: const InputDecoration(labelText: 'Latitude', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lonController,
              decoration: const InputDecoration(labelText: 'Longitude', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final lat = double.tryParse(latController.text);
              final lon = double.tryParse(lonController.text);
              if (lat != null && lon != null) {
                ref.read(nearbyProvider.notifier).setLocation(latitude: lat, longitude: lon);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Set Location'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nearbyProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nearby Pet Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_location_alt_outlined),
            tooltip: 'Manual Location',
            onPressed: _showManualLocationDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Radius selector header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.surface,
            child: Row(
              children: [
                const Icon(Icons.radar, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text('Search Radius:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _radiusOptions.map((radius) {
                        final isSelected = state.currentRadiusKm == radius;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text('${radius.toInt()} km'),
                            selected: isSelected,
                            onSelected: (_) {
                              ref.read(nearbyProvider.notifier).setRadius(radius);
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
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Main Map representation or Nearby List
          Expanded(
            child: _buildMapOrList(state),
          ),
        ],
      ),
    );
  }

  Widget _buildMapOrList(NearbyState state) {
    if (state.isLoading) {
      return const Center(child: LoadingIndicator(message: 'Scanning nearby area...'));
    }

    if (state.permissionDenied) {
      return Center(
        child: EmptyStateWidget(
          title: 'Location Permission Denied',
          message: 'PawFinder needs location access to show nearby lost & found pets. You can also pick a location manually.',
          icon: Icons.location_off_rounded,
          actionText: 'Enter Location Manually',
          onAction: _showManualLocationDialog,
        ),
      );
    }

    if (state.reports.isEmpty) {
      return Center(
        child: EmptyStateWidget(
          title: 'No nearby pets found',
          message: 'No reports within ${state.currentRadiusKm.toInt()} km. Try increasing the search radius.',
          icon: Icons.pets_outlined,
          actionText: 'Widen to 50 km',
          onAction: () {
            ref.read(nearbyProvider.notifier).setRadius(50.0);
          },
        ),
      );
    }

    // List of reports sorted by distance with approximate public location markers
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: state.reports.length,
      itemBuilder: (context, index) {
        final r = state.reports[index];
        return _buildNearbyReportCard(r);
      },
    );
  }

  Widget _buildNearbyReportCard(PublicPetReportModel report) {
    final dateFormat = DateFormat('MMM d • h:mm a');
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: report.isLost ? AppColors.secondary.withValues(alpha: 0.15) : AppColors.primary.withValues(alpha: 0.15),
          child: Icon(
            report.isLost ? Icons.search : Icons.pets,
            color: report.isLost ? AppColors.secondary : AppColors.primary,
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                report.petName ?? '${report.animalType} (${report.breed ?? "Unknown"})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (report.distanceKm != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${report.distanceKm!.toStringAsFixed(1)} km away',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${report.color} • ${report.locationLabel}',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 2),
            Text(
              'Approx. area: ${report.approxLatitude.toStringAsFixed(2)}, ${report.approxLongitude.toStringAsFixed(2)} • ${dateFormat.format(report.eventDatetime.toLocal())}',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

