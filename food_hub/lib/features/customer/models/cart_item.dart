import '../../../shared/models/menu_item_model.dart';
import '../../../shared/models/order_model.dart';

/// Cart Item model for local state
class CartItem {
  final String id; // Unique ID for cart item
  final MenuItemModel menuItem;
  final int quantity;
  final List<SelectedOptionModel> selectedOptions;
  final String? specialRequest;

  CartItem({
    required this.id,
    required this.menuItem,
    required this.quantity,
    this.selectedOptions = const [],
    this.specialRequest,
  });

  /// Calculate total price for this cart item
  double get totalPrice {
    final basePrice = menuItem.price * quantity;
    final optionsPrice = selectedOptions.fold<double>(
      0,
      (sum, option) => sum + (option.price * quantity),
    );
    return basePrice + optionsPrice;
  }

  /// Calculate unit price (including options)
  double get unitPrice {
    final basePrice = menuItem.price;
    final optionsPrice = selectedOptions.fold<double>(
      0,
      (sum, option) => sum + option.price,
    );
    return basePrice + optionsPrice;
  }

  /// Copy with
  CartItem copyWith({
    String? id,
    MenuItemModel? menuItem,
    int? quantity,
    List<SelectedOptionModel>? selectedOptions,
    String? specialRequest,
  }) {
    return CartItem(
      id: id ?? this.id,
      menuItem: menuItem ?? this.menuItem,
      quantity: quantity ?? this.quantity,
      selectedOptions: selectedOptions ?? this.selectedOptions,
      specialRequest: specialRequest ?? this.specialRequest,
    );
  }

  @override
  String toString() {
    return 'CartItem(id: $id, menuItem: ${menuItem.name}, quantity: $quantity, totalPrice: $totalPrice)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CartItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
