import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/primary_button.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../../app/routes.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error),
            tooltip: 'Log Out',
            onPressed: () => _confirmLogout(context, ref),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('No active profile'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Profile Avatar
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                          backgroundImage: (user.profileImageUrl != null &&
                                  user.profileImageUrl!.isNotEmpty)
                              ? NetworkImage(user.profileImageUrl!)
                              : null,
                          child: (user.profileImageUrl == null ||
                                  user.profileImageUrl!.isEmpty)
                              ? Text(
                                  user.name.isNotEmpty
                                      ? user.name[0].toUpperCase()
                                      : 'P',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: user.isAdmin
                          ? AppColors.secondary.withValues(alpha: 0.15)
                          : AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.role.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: user.isAdmin ? AppColors.secondaryDark : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Profile Details Card
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Account Info',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Edit'),
                                onPressed: () {
                                  Navigator.of(context).pushNamed(AppRoutes.editProfile);
                                },
                              ),
                            ],
                          ),
                          const Divider(),
                          _buildProfileRow(
                            icon: Icons.person_outline,
                            label: 'Full Name',
                            value: user.name,
                          ),
                          const Divider(height: 24),
                          _buildProfileRow(
                            icon: Icons.email_outlined,
                            label: 'Email Address',
                            value: user.email,
                          ),
                          const Divider(height: 24),
                          _buildProfileRow(
                            icon: Icons.phone_outlined,
                            label: 'Phone Number',
                            value: user.phone ?? 'Not provided',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // My Reports Navigation Card
                  Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.assignment_outlined, color: AppColors.primary),
                      ),
                      title: const Text(
                        'My Submitted Reports',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      subtitle: const Text('View and manage your lost and found listings'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).pushNamed(AppRoutes.myReports);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Contact Requests Navigation Card
                  Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.contact_mail_outlined, color: AppColors.primary),
                      ),
                      title: const Text(
                        'Contact Requests',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      subtitle: const Text('Received and sent communication inquiries'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).pushNamed(AppRoutes.contactRequests);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Settings & Privacy Card
                  Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.settings_outlined, color: AppColors.secondary),
                      ),
                      title: const Text(
                        'Settings & Privacy',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      subtitle: const Text('Password, security, and location privacy strategy'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).pushNamed(AppRoutes.settings);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Admin Moderation Queue Card (Visible when user has role == 'admin')
                  if (user.role.toLowerCase() == 'admin') ...[
                    Card(
                      margin: EdgeInsets.zero,
                      color: AppColors.error.withValues(alpha: 0.05),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.admin_panel_settings_outlined, color: AppColors.error),
                        ),
                        title: const Text(
                          'Moderation Administration',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.error),
                        ),
                        subtitle: const Text('Review and resolve flagged abuse reports'),
                        trailing: const Icon(Icons.chevron_right, color: AppColors.error),
                        onTap: () {
                          Navigator.of(context).pushNamed(AppRoutes.adminModeration);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 12),

                  // Logout Button
                  PrimaryButton(
                    text: 'Sign Out',
                    icon: Icons.logout,
                    backgroundColor: AppColors.error,
                    onPressed: () => _confirmLogout(context, ref),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 22, color: AppColors.primary),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    ConfirmationDialog.show(
      context,
      title: 'Sign Out',
      content: 'Are you sure you want to sign out of PawFinder?',
      confirmText: 'Sign Out',
      confirmColor: AppColors.error,
      onConfirm: () async {
        await ref.read(authProvider.notifier).logout();
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.login,
            (route) => false,
          );
        }
      },
    );
  }
}

