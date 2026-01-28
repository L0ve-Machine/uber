import 'package:flutter/material.dart';
import '../../../shared/widgets/restaurant_card.dart';
import '../../../shared/models/restaurant_model.dart';

/// レストラン一覧（リストビュー）
class RestaurantListView extends StatelessWidget {
  final List<Map<String, dynamic>> restaurantsWithDistance;
  final Function(RestaurantModel) onRestaurantTap;
  final Future<void> Function() onRefresh;

  const RestaurantListView({
    super.key,
    required this.restaurantsWithDistance,
    required this.onRestaurantTap,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        itemCount: restaurantsWithDistance.length,
        itemBuilder: (context, index) {
          final item = restaurantsWithDistance[index];
          final restaurant = item['restaurant'] as RestaurantModel;
          final distance = item['distance'] as double?;

          return RestaurantCard(
            restaurant: restaurant,
            distance: distance,
            onTap: () => onRestaurantTap(restaurant),
          );
        },
      ),
    );
  }
}
