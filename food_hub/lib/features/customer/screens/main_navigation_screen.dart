import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/cart_icon_button.dart';
import 'home_screen.dart';
import 'order_history_screen.dart';
import 'favorites_screen.dart';
import 'menu_screen.dart';

/// メインナビゲーション画面（ボトムナビゲーションバー）
class MainNavigationScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _screens = const [
    HomeScreen(),
    OrderHistoryScreen(),
    FavoritesScreen(),
    MenuScreen(),
  ];

  PreferredSizeWidget _buildAppBar() {
    switch (_currentIndex) {
      case 0: // ホーム
        return AppBar(
          title: const Text('FoodHub'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          actions: const [
            CartIconButton(),
          ],
        );

      case 1: // 注文
        return AppBar(
          title: const Text('注文履歴'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        );

      case 2: // お気に入り
        return AppBar(
          title: const Text('お気に入り'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          actions: const [
            CartIconButton(),
          ],
        );

      case 3: // その他
        return AppBar(
          title: const Text('メニュー'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        );

      default:
        return AppBar(
          title: const Text('FoodHub'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey[600],
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: '注文',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: 'お気に入り',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: 'その他',
          ),
        ],
      ),
    );
  }
}
