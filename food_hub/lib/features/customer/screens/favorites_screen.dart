import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/restaurant_card.dart';
import '../providers/favorite_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoriteListProvider);

    return favoritesAsync.when(
        data: (favorites) {
          if (favorites.isEmpty) {
            return const EmptyState(
              icon: Icons.favorite_border,
              title: 'お気に入りがありません',
              message: 'レストランをお気に入りに追加すると\nここに表示されます',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(favoriteListProvider.notifier).refresh();
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final favorite = favorites[index];
                final restaurant = favorite.restaurant;

                if (restaurant == null) {
                  return const SizedBox.shrink();
                }

                return Dismissible(
                  key: Key('favorite_${favorite.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('お気に入りから削除'),
                        content: Text('${restaurant.name}をお気に入りから削除しますか？'),
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
                            child: const Text('削除'),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) async {
                    await ref
                        .read(favoriteListProvider.notifier)
                        .removeFavorite(favorite.id);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${restaurant.name}をお気に入りから削除しました'),
                          action: SnackBarAction(
                            label: '元に戻す',
                            onPressed: () async {
                              await ref
                                  .read(favoriteListProvider.notifier)
                                  .addFavorite(restaurant.id);
                            },
                          ),
                        ),
                      );
                    }
                  },
                  child: RestaurantCard(
                    restaurant: restaurant,
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        '/customer/restaurant',
                        arguments: restaurant.id,
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
        loading: () => const LoadingIndicator(message: 'お気に入りを読み込み中...'),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () {
            ref.invalidate(favoriteListProvider);
          },
        ),
    );
  }
}
