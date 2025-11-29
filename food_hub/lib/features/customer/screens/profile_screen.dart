import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_view.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('プロフィール'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('ログインしてください'));
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Profile header
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.gray200,
                          child: user.profileImageUrl != null
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: user.profileImageUrl!,
                                    width: 96,
                                    height: 96,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        const CircularProgressIndicator(),
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.person, size: 48),
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 48,
                                  color: Colors.black,
                                ),
                        ),
                        const SizedBox(height: 16),
                        // Name
                        Text(
                          user.fullName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Email
                        Text(
                          user.email,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Menu items
                _buildMenuItem(
                  context,
                  icon: Icons.edit,
                  title: 'プロフィール編集',
                  onTap: () {
                    Navigator.of(context).pushNamed('/customer/profile/edit');
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.lock,
                  title: 'パスワード変更',
                  onTap: () {
                    Navigator.of(context).pushNamed('/customer/password/change');
                  },
                ),
                const Divider(height: 1),
                _buildMenuItem(
                  context,
                  icon: Icons.location_on,
                  title: '住所管理',
                  onTap: () {
                    Navigator.of(context).pushNamed('/customer/addresses/select');
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.favorite,
                  title: 'お気に入り',
                  onTap: () {
                    Navigator.of(context).pushNamed('/customer/favorites');
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.receipt_long,
                  title: '注文履歴',
                  onTap: () {
                    Navigator.of(context).pushNamed('/customer/order-history');
                  },
                ),
                const Divider(height: 1),
                _buildMenuItem(
                  context,
                  icon: Icons.logout,
                  title: 'ログアウト',
                  iconColor: Colors.red,
                  textColor: Colors.red,
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('ログアウト'),
                        content: const Text('ログアウトしますか？'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('キャンセル'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('ログアウト'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/login',
                          (route) => false,
                        );
                      }
                    }
                  },
                ),

                const SizedBox(height: 32),

                // App info
                Text(
                  'FoodHub v1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
        loading: () => const LoadingIndicator(message: '読み込み中...'),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () {
            ref.invalidate(authProvider);
          },
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return Container(
      color: Colors.white,
      child: ListTile(
        leading: Icon(
          icon,
          color: iconColor ?? Colors.black,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor ?? AppColors.textPrimary,
            fontSize: 16,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: AppColors.textSecondary,
        ),
        onTap: onTap,
      ),
    );
  }
}
