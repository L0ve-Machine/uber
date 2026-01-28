import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../shared/models/restaurant_model.dart';

/// レストランの簡易カード（地図ビュー用）
class RestaurantMiniCard extends StatelessWidget {
  final RestaurantModel restaurant;
  final double? distance;
  final VoidCallback onTap;

  const RestaurantMiniCard({
    super.key,
    required this.restaurant,
    this.distance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 画像
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: restaurant.coverImageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: restaurant.coverImageUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Icon(Icons.restaurant, size: 32),
                      ),
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                      child: const Icon(Icons.restaurant, size: 32),
                    ),
            ),
            const SizedBox(width: 12),

            // 情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // レストラン名
                  Text(
                    restaurant.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // カテゴリー
                  Text(
                    restaurant.category,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 評価・距離・配送料
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        restaurant.rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),

                      if (distance != null) ...[
                        Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 2),
                        Text(
                          '${distance!.toStringAsFixed(1)}km',
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                      ],

                      Icon(Icons.delivery_dining, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 2),
                      Text(
                        restaurant.deliveryFee == 0
                            ? '無料'
                            : '¥${restaurant.deliveryFee.toInt()}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 矢印アイコン
            const Icon(Icons.chevron_right, size: 24),
          ],
        ),
      ),
    );
  }
}
