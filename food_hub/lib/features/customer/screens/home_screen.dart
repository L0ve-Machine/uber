import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/restaurant_card.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/custom_button.dart';
import '../providers/restaurant_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/address_provider.dart';
import '../../auth/providers/auth_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  String? _selectedCategory;
  String _sortBy = 'distance'; // 'distance', 'price', 'rating'
  double? _maxDistance; // null = no limit, 5, 10, 20
  bool _showFilters = false;

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
    final addressesAsync = ref.watch(addressListProvider);

    return Column(
        children: [
          // Address warning if no default address
          addressesAsync.when(
            data: (addresses) {
              final hasDefaultAddress = addresses.any((a) => a.isDefault && a.latitude != null && a.longitude != null);
              if (!hasDefaultAddress) {
                return Container(
                  color: Colors.orange[50],
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.location_off, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '先に住所登録してください',
                          style: TextStyle(
                            color: Colors.orange[900],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/customer/addresses');
                        },
                        child: const Text('登録する'),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),


          // Search bar with filter toggle
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _searchController,
                    hintText: 'レストランを検索...',
                    prefixIcon: const Icon(Icons.search),
                    onChanged: _onSearch,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    _showFilters ? Icons.filter_list_off : Icons.filter_list,
                    color: _showFilters ? Colors.black : Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _showFilters = !_showFilters;
                    });
                  },
                ),
              ],
            ),
          ),

          // Collapsible filters
          if (_showFilters) ...[
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sort and Distance filter in one row
                  Row(
                    children: [
                      // Sort dropdown
                      Expanded(
                        child: _buildCompactDropdown(
                          label: '並び替え',
                          value: _sortBy,
                          items: const {
                            'distance': '近い順',
                            'price': '安い順',
                            'rating': '評価順',
                          },
                          onChanged: (value) {
                            setState(() {
                              _sortBy = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Distance filter dropdown
                      Expanded(
                        child: _buildCompactDropdown(
                          label: '距離',
                          value: _maxDistance?.toString() ?? 'all',
                          items: const {
                            'all': 'すべて',
                            '5': '5km以内',
                            '10': '10km以内',
                            '20': '20km以内',
                          },
                          onChanged: (value) {
                            setState(() {
                              _maxDistance = value == 'all' ? null : double.parse(value!);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Category chips
                  _buildCategoryChips(),
                ],
              ),
            ),
          ]
          else ...[
            // Compact category filter when filters hidden
            _buildCategoryFilter(),
          ],

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

                // Calculate distances and sort by proximity
                return addressesAsync.when(
                  data: (addresses) {
                    final defaultAddress = addresses.where((a) => a.isDefault).firstOrNull;

                    List<Map<String, dynamic>> restaurantsWithDistance = [];

                    if (defaultAddress?.latitude != null && defaultAddress?.longitude != null) {
                      // Calculate distance for each restaurant
                      restaurantsWithDistance = restaurants.map((restaurant) {
                        final distance = Geolocator.distanceBetween(
                          defaultAddress!.latitude!,
                          defaultAddress.longitude!,
                          restaurant.latitude,
                          restaurant.longitude,
                        ) / 1000; // Convert to km
                        return {
                          'restaurant': restaurant,
                          'distance': distance,
                        };
                      }).toList();

                      // Apply distance filter
                      if (_maxDistance != null) {
                        restaurantsWithDistance = restaurantsWithDistance
                          .where((item) => (item['distance'] as double) <= _maxDistance!)
                          .toList();
                      }

                      // Sort by selected criteria
                      switch (_sortBy) {
                        case 'distance':
                          restaurantsWithDistance.sort((a, b) =>
                            (a['distance'] as double).compareTo(b['distance'] as double)
                          );
                          break;
                        case 'price':
                          restaurantsWithDistance.sort((a, b) =>
                            (a['restaurant'] as dynamic).deliveryFee.compareTo(
                              (b['restaurant'] as dynamic).deliveryFee
                            )
                          );
                          break;
                        case 'rating':
                          restaurantsWithDistance.sort((a, b) =>
                            (b['restaurant'] as dynamic).rating.compareTo(
                              (a['restaurant'] as dynamic).rating
                            )
                          );
                          break;
                      }
                    } else {
                      // No address, no distance calculation
                      restaurantsWithDistance = restaurants.map((r) => {
                        'restaurant': r,
                        'distance': null,
                      }).toList();
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        await ref.read(restaurantListProvider().notifier).refresh();
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 16),
                        itemCount: restaurantsWithDistance.length,
                        itemBuilder: (context, index) {
                          final item = restaurantsWithDistance[index];
                          final restaurant = item['restaurant'];
                          final distance = item['distance'] as double?;

                          return RestaurantCard(
                            restaurant: restaurant,
                            distance: distance,
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
                  error: (_, __) => RefreshIndicator(
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

  Widget _buildCompactDropdown({
    required String label,
    required String value,
    required Map<String, String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              isDense: true,
              items: items.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(
                    entry.value,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChips() {
    final categories = ['和食', '中華', 'イタリアン', '韓国料理', 'アメリカン', 'タイ料理'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((category) {
        final isSelected = _selectedCategory == category;
        return FilterChip(
          label: Text(category),
          selected: isSelected,
          onSelected: (selected) {
            _onCategorySelected(selected ? category : null);
          },
          selectedColor: Colors.black,
          backgroundColor: Colors.white,
          side: BorderSide(color: isSelected ? Colors.black : Colors.grey[300]!),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontSize: 13,
          ),
        );
      }).toList(),
    );
  }
}
