import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../app/routes.dart';
import '../../authentication/providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _showChangePasswordDialog() {
    _oldPasswordController.clear();
    _newPasswordController.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _oldPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current Password', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password (min 8 chars, 1 digit)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final oldP = _oldPasswordController.text;
              final newP = _newPasswordController.text;
              if (oldP.isEmpty || newP.length < 8) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password must be at least 8 characters')),
                );
                return;
              }
              Navigator.pop(ctx);
              // Updating password
              try {
                final repo = ref.read(authRepositoryProvider);
                await repo.changePassword(currentPassword: oldP, newPassword: newP);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password changed successfully! Please log in again.')),
                  );
                  await ref.read(authProvider.notifier).logout();
                  if (mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to change password: $e')),
                  );
                }
              } finally {
              }
            },
            child: const Text('Update Password'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings & Privacy'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Security Section
          const Text('Security & Credentials', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              leading: const Icon(Icons.lock_outline, color: AppColors.primary),
              title: const Text('Change Password'),
              subtitle: const Text('Update your master account password'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showChangePasswordDialog,
            ),
          ),
          const SizedBox(height: 24),

          // About & Privacy Section
          const Text('App Information & Privacy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.security, color: AppColors.primary),
                  title: const Text('Location Privacy Strategy'),
                  subtitle: const Text('Exact coordinates are masked with ~100m approximate rounding to protect residential privacy.'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: AppColors.primary),
                  title: const Text('PawFinder App Version'),
                  subtitle: const Text('v1.0.0 (Production Candidate)'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Logout
          PrimaryButton(
            text: 'Sign Out',
            backgroundColor: AppColors.error,
            icon: Icons.logout,
            onPressed: () {
              ConfirmationDialog.show(
                context,
                title: 'Sign Out',
                content: 'Are you sure you want to sign out of PawFinder?',
                confirmText: 'Sign Out',
                confirmColor: AppColors.error,
                onConfirm: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
