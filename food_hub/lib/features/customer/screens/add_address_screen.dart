import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../providers/address_provider.dart';
import '../widgets/location_picker_map.dart';

class AddAddressScreen extends ConsumerStatefulWidget {
  const AddAddressScreen({super.key});

  @override
  ConsumerState<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends ConsumerState<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _postalCodeController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();

  String _selectedLabel = 'Home';
  bool _isDefault = false;
  bool _isLoading = false;

  // 地図関連の状態
  bool _showMapPicker = false;
  bool _isReverseGeocodingLoading = false;
  double? _latitude;
  double? _longitude;

  final List<Map<String, dynamic>> _labelOptions = [
    {'value': 'Home', 'label': '自宅', 'icon': Icons.home},
    {'value': 'Work', 'label': '会社', 'icon': Icons.business},
    {'value': 'Other', 'label': 'その他', 'icon': Icons.location_on},
  ];

  @override
  void dispose() {
    _postalCodeController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    super.dispose();
  }

  /// 地図で位置が選択されたときの処理
  void _onMapLocationSelected(double lat, double lon) async {
    print('[AddAddress] Map location selected: lat=$lat, lon=$lon');

    setState(() {
      _latitude = lat;
      _longitude = lon;
    });

    // 住所フィールドが空なら自動入力
    final currentAddress = _addressLine1Controller.text.trim();

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
      print('[AddAddress] Reverse geocoding: lat=$lat, lon=$lon');
      final placemarks = await placemarkFromCoordinates(lat, lon);

      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        print('[AddAddress] Placemark found: ${place.toString()}');

        // 日本の住所形式で組み立て
        final addressParts = [
          place.administrativeArea ?? '', // 都道府県
          place.locality ?? '',            // 市区町村
          place.subLocality ?? '',         // 町名
          place.thoroughfare ?? '',        // 番地
        ].where((part) => part.isNotEmpty).join('');

        setState(() {
          if (addressParts.isNotEmpty) {
            _addressLine1Controller.text = addressParts;
          }
          if (place.postalCode != null && place.postalCode!.isNotEmpty) {
            _postalCodeController.text = place.postalCode!;
          }
          _isReverseGeocodingLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('住所を取得しました'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('[AddAddress] Reverse geocoding error: $e');
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
      // 地図選択の座標を優先、未選択時のみテキストからジオコーディング
      double? latitude = _latitude;
      double? longitude = _longitude;

      // 地図で選択していない場合のみ自動ジオコーディング
      if (latitude == null || longitude == null) {
        final fullAddress = '${_postalCodeController.text.trim()} '
                            '${_addressLine1Controller.text.trim()}';

        try {
          print('[AddAddress] Geocoding address: $fullAddress');
          final locations = await locationFromAddress(fullAddress);

          if (locations.isNotEmpty) {
            latitude = locations.first.latitude;
            longitude = locations.first.longitude;
            print('[AddAddress] Geocoded successfully: lat=$latitude, lng=$longitude');
          } else {
            print('[AddAddress] No locations found for address');
          }
        } catch (e) {
          print('[AddAddress] Geocoding error: $e');
          // エラーでも続行（latitude/longitudeはNULL）
        }
      } else {
        print('[AddAddress] Using map-selected coordinates: lat=$latitude, lng=$longitude');
      }

      final result = await ref.read(addressListProvider.notifier).addAddress(
            postalCode: _postalCodeController.text.trim(),
            addressLine1: _addressLine1Controller.text.trim(),
            addressLine2: _addressLine2Controller.text.trim().isEmpty
                ? null
                : _addressLine2Controller.text.trim(),
            latitude: latitude,
            longitude: longitude,
            isDefault: _isDefault,
            label: _selectedLabel,
          );

      if (!mounted) return;

      result.when(
        success: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('住所を追加しました'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        },
        failure: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('エラー: ${error.message}'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('新しい住所を追加'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label selection
              const Text(
                'ラベル',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: _labelOptions.map((option) {
                  final isSelected = _selectedLabel == option['value'];
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: option != _labelOptions.last ? 8 : 0,
                      ),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedLabel = option['value'];
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.black.withOpacity(0.05)
                                : Colors.white,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.black
                                  : Colors.grey[300]!,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                option['icon'],
                                color: isSelected
                                    ? Colors.black
                                    : Colors.grey[600],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                option['label'],
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Postal code (FIRST - Japanese standard)
              CustomTextField(
                controller: _postalCodeController,
                labelText: '郵便番号',
                hintText: '例: 150-0001',
                prefixIcon: const Icon(Icons.markunread_mailbox_outlined),
                keyboardType: TextInputType.text,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '郵便番号を入力してください';
                  }
                  return null;
                },
                enabled: !_isReverseGeocodingLoading,
              ),

              const SizedBox(height: 16),

              // Address line 1 (Main address)
              CustomTextField(
                controller: _addressLine1Controller,
                labelText: '住所1',
                hintText: '例: 東京都渋谷区神宮前3-15-8',
                prefixIcon: const Icon(Icons.location_on_outlined),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '住所を入力してください';
                  }
                  return null;
                },
                enabled: !_isReverseGeocodingLoading,
              ),

              const SizedBox(height: 16),

              // 地図選択ボタン
              OutlinedButton.icon(
                onPressed: _isReverseGeocodingLoading
                    ? null
                    : () {
                        setState(() {
                          _showMapPicker = !_showMapPicker;
                        });
                      },
                icon: Icon(_showMapPicker ? Icons.close : Icons.map),
                label: Text(_showMapPicker ? '地図を閉じる' : '地図で位置を選択'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),

              // 地図表示エリア（トグル）
              if (_showMapPicker) ...[
                const SizedBox(height: 16),
                if (_isReverseGeocodingLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: Colors.black),
                          SizedBox(height: 12),
                          Text(
                            '住所を取得中...',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  LocationPickerMap(
                    initialLatitude: _latitude,
                    initialLongitude: _longitude,
                    onLocationSelected: _onMapLocationSelected,
                    height: 350,
                  ),
                const SizedBox(height: 8),
                if (_latitude != null && _longitude != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '位置情報が設定されました',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '緯度: ${_latitude!.toStringAsFixed(6)}, 経度: ${_longitude!.toStringAsFixed(6)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],

              const SizedBox(height: 16),

              // Address line 2 (Building/Apartment - Optional)
              CustomTextField(
                controller: _addressLine2Controller,
                labelText: '住所2 (建物名・部屋番号)',
                hintText: '例: グランドメゾン青山 402号室',
                prefixIcon: const Icon(Icons.apartment_outlined),
                validator: null, // Optional field
                enabled: !_isReverseGeocodingLoading,
              ),

              const SizedBox(height: 24),

              // Set as default checkbox
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: CheckboxListTile(
                  value: _isDefault,
                  onChanged: (value) {
                    setState(() {
                      _isDefault = value ?? false;
                    });
                  },
                  title: const Text('デフォルトの住所に設定'),
                  subtitle: Text(
                    'この住所を優先的に使用します',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  activeColor: Colors.black,
                  controlAffinity: ListTileControlAffinity.leading,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Save button
              CustomButton(
                text: '住所を保存',
                onPressed: _isLoading ? null : _saveAddress,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
