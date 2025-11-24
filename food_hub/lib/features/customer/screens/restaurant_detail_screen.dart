import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../providers/restaurant_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/add_to_cart_sheet.dart';

class RestaurantDetailScreen extends ConsumerStatefulWidget {
  final int restaurantId;

  const RestaurantDetailScreen({
    super.key,
    required this.restaurantId,
  });

  @override
  ConsumerState<RestaurantDetailScreen> createState() =>
      _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState
    extends ConsumerState<RestaurantDetailScreen> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final restaurantAsync = ref.watch(restaurantDetailProvider(widget.restaurantId));
    final menuAsync = ref.watch(restaurantMenuProvider(
      restaurantId: widget.restaurantId,
      category: _selectedCategory,
    ));
    final categories = ref.watch(menuCategoriesProvider(widget.restaurantId));
    final cartItemCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: cartItemCount > 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).pushNamed('/customer/cart');
              },
              backgroundColor: AppColors.primaryGreen,
              icon: const Icon(Icons.shopping_cart),
              label: Text('カート ($cartItemCount)'),
            )
          : null,
      body: restaurantAsync.when(
        data: (restaurant) => CustomScrollView(
          slivers: [
            // App Bar with Cover Image
            SliverAppBar(
              expandedHeight: 250,
              pinned: true,
              backgroundColor: AppColors.primaryGreen,
              flexibleSpace: FlexibleSpaceBar(
                background: restaurant.coverImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: restaurant.coverImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.restaurant, size: 64),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.restaurant, size: 64),
                      ),
              ),
            ),

            // Restaurant Info
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and Status
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            restaurant.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!restaurant.isOpen)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '閉店中',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.red[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Category
                    Text(
                      restaurant.category,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Description
                    if (restaurant.description != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        restaurant.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Stats Row
                    Row(
                      children: [
                        // Rating
                        _buildStatItem(
                          icon: Icons.star,
                          iconColor: Colors.amber,
                          label: restaurant.rating.toStringAsFixed(1),
                          sublabel: '(${restaurant.totalReviews})',
                        ),
                        const SizedBox(width: 24),

                        // Delivery Fee
                        _buildStatItem(
                          icon: Icons.delivery_dining,
                          iconColor: AppColors.primaryGreen,
                          label: restaurant.deliveryFee == 0
                              ? '無料'
                              : '¥${restaurant.deliveryFee.toInt()}',
                          sublabel: '配送料',
                        ),
                        const SizedBox(width: 24),

                        // Delivery Time
                        _buildStatItem(
                          icon: Icons.access_time,
                          iconColor: AppColors.primaryGreen,
                          label: '${restaurant.deliveryTimeMinutes}分',
                          sublabel: '配達時間',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Min Order
                    if (restaurant.minOrderAmount > 0) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.lightGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 20,
                              color: AppColors.darkGreen,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '最低注文金額: ¥${restaurant.minOrderAmount.toInt()}',
                              style: TextStyle(
                                color: AppColors.darkGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Category Filter
            if (categories.isNotEmpty)
              SliverToBoxAdapter(
                child: Container(
                  height: 50,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      // All category
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChip(
                          label: const Text('すべて'),
                          selected: _selectedCategory == null,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = null;
                            });
                          },
                          selectedColor: AppColors.primaryGreen,
                          labelStyle: TextStyle(
                            color: _selectedCategory == null
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      // Categories
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
                            },
                            selectedColor: AppColors.primaryGreen,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

            // Menu Items
            menuAsync.when(
              data: (menuItems) {
                if (menuItems.isEmpty) {
                  return SliverFillRemaining(
                    child: EmptyState(
                      icon: Icons.restaurant_menu,
                      title: 'メニューがありません',
                      message: _selectedCategory != null
                          ? 'このカテゴリーにはメニューがありません'
                          : 'メニューが登録されていません',
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.all(8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = menuItems[index];
                        return _buildMenuItem(item);
                      },
                      childCount: menuItems.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: LoadingIndicator(message: 'メニューを読み込み中...'),
              ),
              error: (error, _) => SliverFillRemaining(
                child: ErrorView(
                  error: error,
                  onRetry: () {
                    ref.invalidate(restaurantMenuProvider(
                      restaurantId: widget.restaurantId,
                    ));
                  },
                ),
              ),
            ),
          ],
        ),
        loading: () => const LoadingIndicator(message: 'レストラン情報を読み込み中...'),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () {
            ref.invalidate(restaurantDetailProvider(widget.restaurantId));
          },
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String sublabel,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              sublabel,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuItem(menuItem) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: menuItem.isAvailable
            ? () {
                _showAddToCartSheet(context, menuItem);
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: menuItem.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: menuItem.imageUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child: const Icon(Icons.fastfood),
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Icon(Icons.fastfood),
                      ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      menuItem.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (menuItem.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        menuItem.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '¥${menuItem.price.toInt()}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        const Spacer(),
                        if (!menuItem.isAvailable)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '売り切れ',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
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

  void _showAddToCartSheet(BuildContext context, MenuItemModel menuItem) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddToCartSheet(menuItem: menuItem),
    );
  }
}
