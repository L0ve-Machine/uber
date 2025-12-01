import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../providers/restaurant_menu_provider.dart';
import '../widgets/restaurant_menu_item_card.dart';
import 'restaurant_menu_edit_screen.dart';

class RestaurantMenuListScreen extends ConsumerStatefulWidget {
  const RestaurantMenuListScreen({super.key});

  @override
  ConsumerState<RestaurantMenuListScreen> createState() => _RestaurantMenuListScreenState();
}

class _RestaurantMenuListScreenState extends ConsumerState<RestaurantMenuListScreen> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final menuAsync = ref.watch(restaurantMenuProvider(category: _selectedCategory));

    return Column(
      children: [
        // Category filter
        _buildCategoryFilter(),

        // Menu list
        Expanded(
          child: menuAsync.when(
            data: (menuItems) {
              if (menuItems.isEmpty) {
                return EmptyState(
                  icon: Icons.restaurant_menu_outlined,
                  title: 'メニューがありません',
                  message: _selectedCategory != null
                      ? 'このカテゴリにはメニューがありません'
                      : 'メニューを追加してください',
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(restaurantMenuProvider(category: _selectedCategory));
                },
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: menuItems.length,
                  itemBuilder: (context, index) {
                    final menuItem = menuItems[index];
                    return RestaurantMenuItemCard(
                      menuItem: menuItem,
                      onTap: () => _navigateToEdit(menuItem.id),
                      onEdit: () => _navigateToEdit(menuItem.id),
                      onToggleAvailability: () => _handleToggleAvailability(menuItem.id),
                      onDelete: () => _handleDelete(menuItem.id, menuItem.name),
                    );
                  },
                ),
              );
            },
            loading: () => const LoadingIndicator(message: 'メニューを読み込み中...'),
            error: (error, _) => ErrorView(
              error: error,
              onRetry: () {
                ref.invalidate(restaurantMenuProvider(category: _selectedCategory));
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    final categories = ['メイン', 'サイド', 'ドリンク', 'デザート', 'その他'];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: const Text('すべて'),
              selected: _selectedCategory == null,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = null;
                });
                ref.read(restaurantMenuProvider(category: null).notifier)
                    .filterByCategory(null);
              },
              selectedColor: Colors.black,
              labelStyle: TextStyle(
                color: _selectedCategory == null ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          ...categories.map((category) {
            final isSelected = _selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = selected ? category : null;
                  });
                  ref.read(restaurantMenuProvider(category: _selectedCategory).notifier)
                      .filterByCategory(_selectedCategory);
                },
                selectedColor: Colors.black,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _navigateToEdit(int menuItemId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RestaurantMenuEditScreen(menuItemId: menuItemId),
      ),
    );
  }

  Future<void> _handleToggleAvailability(int menuItemId) async {
    final success = await ref
        .read(restaurantMenuProvider(category: _selectedCategory).notifier)
        .toggleAvailability(menuItemId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '提供状態を変更しました' : '変更に失敗しました'),
          backgroundColor: success ? AppColors.success : Colors.red,
        ),
      );
    }
  }

  Future<void> _handleDelete(int menuItemId, String menuName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('メニューを削除'),
        content: Text('「$menuName」を削除しますか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(restaurantMenuProvider(category: _selectedCategory).notifier)
          .deleteMenuItem(menuItemId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'メニューを削除しました' : '削除に失敗しました'),
            backgroundColor: success ? Colors.orange : Colors.red,
          ),
        );
      }
    }
  }
}
