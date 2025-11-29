import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../auth/providers/auth_provider.dart';

/// その他タブ - 設定・プロフィール管理画面
class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authProvider);

    return userAsync.when(
      data: (user) {
        return SingleChildScrollView(
          child: Column(
            children: [
              // プロフィールヘッダー
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.gray200,
                      child: const Icon(
                        Icons.person,
                        size: 30,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'ゲスト',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // メニューリスト
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
                icon: Icons.rate_review,
                title: 'マイレビュー',
                onTap: () {
                  Navigator.of(context).pushNamed('/customer/my-reviews');
                },
              ),
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
                icon: Icons.lock,
                title: 'パスワード変更',
                onTap: () {
                  Navigator.of(context).pushNamed('/customer/password/change');
                },
              ),

              const Divider(height: 32),

              _buildMenuItem(
                context,
                icon: Icons.logout,
                title: 'ログアウト',
                color: Colors.red,
                onTap: () async {
                  final confirmed = await showDialog<bool>(
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
                          child: const Text(
                            'ログアウト',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && context.mounted) {
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
            ],
          ),
        );
      },
      loading: () => const LoadingIndicator(),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'ユーザー情報の読み込みに失敗しました',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: color ?? Colors.black),
        title: Text(
          title,
          style: TextStyle(color: color),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey[400],
        ),
        onTap: onTap,
      ),
    );
  }
}
