import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/pet_image_card.dart';
import '../../../app/routes.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../discovery/providers/discovery_provider.dart';
import '../../matches/providers/match_provider.dart';
import '../../reports/models/pet_report_model.dart';
import '../../discovery/screens/public_report_detail_screen.dart';
import '../../notifications/providers/notification_provider.dart';

class HomeDashboardView extends ConsumerWidget {
  final VoidCallback onReportLost;
  final VoidCallback onReportFound;

  const HomeDashboardView({
    super.key,
    required this.onReportLost,
    required this.onReportFound,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final discoveryState = ref.watch(discoveryProvider);
    final matchesState = ref.watch(matchesProvider);
    final user = authState.user;

    final lostPets = discoveryState.reports.where((r) => r.isLost).toList();
    final foundPets = discoveryState.reports.where((r) => r.isFound).toList();
    final matches = matchesState.matches;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.pets, color: AppColors.primary, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'PawFinder',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: 20,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Nearby Map',
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.nearbyMap),
          ),
          Consumer(
            builder: (context, ref, _) {
              final unread = ref.watch(unreadNotificationCountProvider);
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    tooltip: 'Notifications',
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.notifications),
                  ),
                  if (unread > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unread > 9 ? '9+' : '$unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history_outlined),
            tooltip: 'My Reports History',
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.myReports),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(discoveryProvider.notifier).refresh();
          await ref.read(matchesProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Personalized Greeting
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user != null
                          ? 'Hello, ${user.name.split(" ").first}! 👋'
                          : 'Welcome to PawFinder! 👋',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Let’s help reunite pets with their families today.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Search Bar Trigger
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: InkWell(
                  onTap: () {
                    // Navigate or trigger search in Discover
                    ref.read(discoveryProvider.notifier).refresh();
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.search, color: AppColors.primary),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Search pets by name, breed, or color...',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Quick Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildActionBtn(
                        title: 'Report Lost Pet',
                        icon: Icons.search_rounded,
                        color: AppColors.secondary,
                        onTap: onReportLost,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionBtn(
                        title: 'Report Found Pet',
                        icon: Icons.pets_rounded,
                        color: AppColors.primary,
                        onTap: onReportFound,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Potential Matches Section
              if (matches.isNotEmpty) ...[
                _buildSectionTitle(
                  context,
                  'Potential Matches For You',
                  onSeeAll: null,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 110,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: matches.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final m = matches[i];
                      return Container(
                        width: 220,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    '${m.matchScore.toStringAsFixed(0)}% MATCH',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    m.status,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              m.lostReport?.petName ??
                                  '${m.lostReport?.animalType} match',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Near ${m.foundReport?.locationLabel ?? "location"}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Lost Pets Section
              _buildSectionTitle(context, 'Recently Lost Pets', onSeeAll: null),
              const SizedBox(height: 8),
              _buildHorizontalPetList(
                context,
                lostPets,
                discoveryState.isLoading,
              ),
              const SizedBox(height: 24),

              // Found Pets Section
              _buildSectionTitle(
                context,
                'Recently Found Pets',
                onSeeAll: null,
              ),
              const SizedBox(height: 8),
              _buildHorizontalPetList(
                context,
                foundPets,
                discoveryState.isLoading,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title, {
    VoidCallback? onSeeAll,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: const Text(
                'See All',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHorizontalPetList(
    BuildContext context,
    List<PetReportModel> pets,
    bool isLoading,
  ) {
    if (isLoading) {
      return const SizedBox(
        height: 140,
        child: Center(child: LoadingIndicator(message: 'Loading pets...')),
      );
    }
    if (pets.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Text(
          'No active listings found in this category.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: pets.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final pet = pets[index];
          return InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PublicReportDetailScreen(report: pet),
                ),
              );
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 140,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PetImageCard(
                    imageUrl: pet.images.isNotEmpty
                        ? pet.images.first.imageUrl
                        : null,
                    width: 140,
                    height: 100,
                    borderRadius: 0,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pet.petName ?? pet.animalType,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          pet.breed ?? pet.color,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          pet.locationLabel,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionBtn({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
