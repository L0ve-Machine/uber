import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../providers/restaurant_profile_provider.dart';
import '../../customer/widgets/location_picker_map.dart';

class RestaurantAddressEditScreen extends ConsumerStatefulWidget {
  const RestaurantAddressEditScreen({super.key});

  @override
  ConsumerState<RestaurantAddressEditScreen> createState() =>
      _RestaurantAddressEditScreenState();
}

class _RestaurantAddressEditScreenState
    extends ConsumerState<RestaurantAddressEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();

  bool _isLoading = false;
  bool _showMapPicker = false;
  bool _isReverseGeocodingLoading = false;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _loadCurrentAddress();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentAddress() async {
    final profileAsync = ref.read(restaurantProfileProvider);
    profileAsync.whenData((profile) {
      if (profile != null) {
        _addressController.text = profile.address;
        _latitude = profile.latitude;
        _longitude = profile.longitude;
      }
    });
  }

  /// 地図で位置が選択されたときの処理
  void _onMapLocationSelected(double lat, double lon) async {
    print('[RestaurantAddressEdit] Map location selected: lat=$lat, lon=$lon');

    setState(() {
      _latitude = lat;
      _longitude = lon;
    });

    // 住所フィールドが空なら自動入力
    final currentAddress = _addressController.text.trim();

    if (currentAddress.isEmpty) {
      await _fetchAndFillAddress(lat, lon);
    } else {
      // 入力済みなら確認ダイアログ
      final shouldUpdate = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('住所を更新しますか？'),
          content: const Text('選択した位置の住所で上書きします。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('そのまま'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('更新する'),
            ),
          ],
        ),
      );

      if (shouldUpdate == true) {
        await _fetchAndFillAddress(lat, lon);
      }
    }
  }

  /// 逆ジオコーディング実行
  Future<void> _fetchAndFillAddress(double lat, double lon) async {
    setState(() {
      _isReverseGeocodingLoading = true;
    });

    try {
      print('[RestaurantAddressEdit] Reverse geocoding: lat=$lat, lon=$lon');
      final placemarks = await placemarkFromCoordinates(lat, lon);

      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        print('[RestaurantAddressEdit] Placemark found: ${place.toString()}');

        // 日本の住所形式で組み立て
        final addressParts = [
          place.administrativeArea ?? '', // 都道府県
          place.locality ?? '', // 市区町村
          place.subLocality ?? '', // 町名
          place.thoroughfare ?? '', // 番地
        ].where((part) => part.isNotEmpty).join('');

        setState(() {
          if (addressParts.isNotEmpty) {
            _addressController.text = addressParts;
          }
          _isReverseGeocodingLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('住所を取得しました。番地以降は手動で入力してください。'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('[RestaurantAddressEdit] Reverse geocoding error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('住所の取得に失敗しました。手動で入力してください。'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isReverseGeocodingLoading = false;
        });
      }
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await ref
          .read(restaurantProfileProvider.notifier)
          .updateAddress(
            address: _addressController.text.trim(),
            latitude: _latitude,
            longitude: _longitude,
          );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('住所を更新しました'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('住所の更新に失敗しました'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(restaurantProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('住所変更'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('プロフィール情報が見つかりません'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 現在の住所表示
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.black, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '現在の住所',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          profile.address,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 地図選択ボタン
                  OutlinedButton.icon(
                    onPressed: _isReverseGeocodingLoading
                        ? null
                        : () {
                            setState(() {
                              _showMapPicker = !_showMapPicker;
                            });
                          },
                    icon: Icon(_showMapPicker ? Icons.map : Icons.add_location),
                    label: Text(_showMapPicker ? '地図を閉じる' : '地図で位置を選択'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),

                  if (_showMapPicker) ...[
                    const SizedBox(height: 16),
                    LocationPickerMap(
                      initialLatitude: _latitude ?? profile.latitude,
                      initialLongitude: _longitude ?? profile.longitude,
                      onLocationSelected: _onMapLocationSelected,
                      height: 350,
                    ),
                  ],

                  const SizedBox(height: 24),

                  // 住所入力フィールド
                  CustomTextField(
                    controller: _addressController,
                    labelText: '住所',
                    hintText: '東京都渋谷区神南1-2-3',
                    prefixIcon: const Icon(Icons.home),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '住所を入力してください';
                      }
                      return null;
                    },
                    enabled: !_isReverseGeocodingLoading,
                    maxLines: 2,
                  ),

                  const SizedBox(height: 16),

                  // 位置情報設定状態の表示
                  if (_latitude != null && _longitude != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '位置情報が設定されています',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // 保存ボタン
                  CustomButton(
                    text: '保存する',
                    onPressed: _isLoading ? null : _saveAddress,
                    isLoading: _isLoading,
                  ),

                  const SizedBox(height: 16),

                  // 注意書き
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              '住所変更について',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '・ 地図で位置を選択すると、住所が自動入力されます\n'
                          '・ 番地以降は手動で入力してください\n'
                          '・ 正確な住所を入力すると、顧客が見つけやすくなります',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.black)),
        error: (error, _) => Center(child: Text('エラー: $error')),
      ),
    );
  }
}
