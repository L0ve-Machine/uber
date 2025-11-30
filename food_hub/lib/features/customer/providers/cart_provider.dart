import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../../shared/models/menu_item_model.dart';
import '../../../shared/models/order_model.dart';
import '../models/cart_item.dart';

part 'cart_provider.g.dart';

const _uuid = Uuid();

/// Cart Provider - manages shopping cart state
@riverpod
class Cart extends _$Cart {
  @override
  List<CartItem> build() {
    print('[CartProvider] build() called - returning empty list');
    return [];
  }

  /// Add item to cart
  void addItem({
    required MenuItemModel menuItem,
    required int quantity,
    List<SelectedOptionModel> selectedOptions = const [],
    String? specialRequest,
  }) {
    final cartItem = CartItem(
      id: _uuid.v4(),
      menuItem: menuItem,
      quantity: quantity,
      selectedOptions: selectedOptions,
      specialRequest: specialRequest,
    );

    print('[CartProvider] Adding item: ${menuItem.name}, quantity: $quantity');
    state = [...state, cartItem];
    print('[CartProvider] Cart items count after add: ${state.length}');
  }

  /// Remove item from cart by ID
  void removeItem(String itemId) {
    state = state.where((item) => item.id != itemId).toList();
  }

  /// Update item quantity
  void updateQuantity(String itemId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(itemId);
      return;
    }

    state = state.map((item) {
      if (item.id == itemId) {
        return item.copyWith(quantity: newQuantity);
      }
      return item;
    }).toList();
  }

  /// Increment item quantity
  void incrementQuantity(String itemId) {
    state = state.map((item) {
      if (item.id == itemId) {
        return item.copyWith(quantity: item.quantity + 1);
      }
      return item;
    }).toList();
  }

  /// Decrement item quantity
  void decrementQuantity(String itemId) {
    state = state.map((item) {
      if (item.id == itemId) {
        final newQuantity = item.quantity - 1;
        if (newQuantity <= 0) {
          return null;
        }
        return item.copyWith(quantity: newQuantity);
      }
      return item;
    }).whereType<CartItem>().toList();
  }

  /// Clear cart
  void clear() {
    state = [];
  }

  /// Get cart item count
  int get itemCount => state.length;

  /// Get total quantity of all items
  int get totalQuantity {
    return state.fold(0, (sum, item) => sum + item.quantity);
  }

  /// Get subtotal (sum of all item prices)
  double get subtotal {
    return state.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  /// Get delivery fee (from first restaurant in cart)
  /// Note: In real app, this should come from the restaurant
  double get deliveryFee {
    // TODO: Get from restaurant data
    return 300.0;
  }

  /// Calculate service fee (15% of subtotal)
  double get serviceFee {
    const SERVICE_FEE_RATE = 0.15;
    return subtotal * SERVICE_FEE_RATE;
  }

  /// Calculate subtotal before tax
  double get subtotalBeforeTax => subtotal + deliveryFee + serviceFee;

  /// Calculate tax (10% of subtotal before tax)
  double get tax => subtotalBeforeTax * 0.1;

  /// Calculate total
  double get total => subtotalBeforeTax + tax;

  /// Check if cart is empty
  bool get isEmpty => state.isEmpty;

  /// Check if cart has items
  bool get isNotEmpty => state.isNotEmpty;

  /// Get all restaurant IDs in cart
  Set<int> get restaurantIds {
    return state.map((item) => item.menuItem.restaurantId).toSet();
  }

  /// Check if all items are from same restaurant
  bool get isFromSingleRestaurant => restaurantIds.length <= 1;
}

/// Cart item count provider (for badge)
@riverpod
int cartItemCount(CartItemCountRef ref) {
  final cart = ref.watch(cartProvider);
  return cart.length;
}

/// Cart total quantity provider
@riverpod
int cartTotalQuantity(CartTotalQuantityRef ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, item) => sum + item.quantity);
}

/// Cart subtotal provider
@riverpod
double cartSubtotal(CartSubtotalRef ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0.0, (sum, item) => sum + item.totalPrice);
}

/// Cart total provider
@riverpod
double cartTotal(CartTotalRef ref) {
  final cartNotifier = ref.watch(cartProvider.notifier);
  return cartNotifier.total;
}
