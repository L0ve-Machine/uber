import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/restaurant_card.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../providers/restaurant_provider.dart';
import '../providers/cart_provider.dart';
import '../../auth/providers/auth_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  String? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    ref.read(restaurantListProvider().notifier).updateFilters(
          search: query.isEmpty ? null : query,
          category: _selectedCategory,
        );
  }

  void _onCategorySelected(String? category) {
    setState(() {
      _selectedCategory = category;
    });
    ref.read(restaurantListProvider().notifier).updateFilters(
          search: _searchController.text.isEmpty ? null : _searchController.text,
          category: category,
        );
  }

  @override
  Widget build(BuildContext context) {
    final restaurantsAsync = ref.watch(restaurantListProvider());

    return Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: CustomTextField(
              controller: _searchController,
              hintText: 'レストランを検索...',
              prefixIcon: const Icon(Icons.search),
              onChanged: _onSearch,
            ),
          ),

          // Category filter
          _buildCategoryFilter(),

          // Restaurant list
          Expanded(
            child: restaurantsAsync.when(
              data: (restaurants) {
                if (restaurants.isEmpty) {
                  return EmptyState(
                    icon: Icons.restaurant,
                    title: 'レストランが見つかりません',
                    message: _searchController.text.isNotEmpty || _selectedCategory != null
                        ? '検索条件を変更してください'
                        : '現在利用可能なレストランがありません',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(restaurantListProvider().notifier).refresh();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    itemCount: restaurants.length,
                    itemBuilder: (context, index) {
                      final restaurant = restaurants[index];
                      return RestaurantCard(
                        restaurant: restaurant,
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            '/customer/restaurant',
                            arguments: restaurant.id,
                          );
                        },
                      );
                    },
                  ),
                );
              },
              loading: () => const LoadingIndicator(message: 'レストランを読み込み中...'),
              error: (error, _) => ErrorView(
                error: error,
                onRetry: () {
                  ref.invalidate(restaurantListProvider());
                },
              ),
            ),
          ),
        ],
    );
  }

  Widget _buildCategoryFilter() {
    final categories = ['和食', '中華', 'イタリアン', '韓国料理', 'アメリカン', 'タイ料理'];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          // All category chip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: const Text('すべて'),
              selected: _selectedCategory == null,
              onSelected: (selected) {
                _onCategorySelected(null);
              },
              selectedColor: Colors.black,
              backgroundColor: Colors.white,
              side: BorderSide(color: _selectedCategory == null ? Colors.black : AppColors.gray300),
              labelStyle: TextStyle(
                color: _selectedCategory == null ? Colors.white : Colors.black,
                fontWeight: _selectedCategory == null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          // Category chips
          ...categories.map((category) {
            final isSelected = _selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  _onCategorySelected(selected ? category : null);
                },
                selectedColor: Colors.black,
                backgroundColor: Colors.white,
                side: BorderSide(color: isSelected ? Colors.black : AppColors.gray300),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
