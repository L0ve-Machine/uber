import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../providers/address_provider.dart';

class AddAddressScreen extends ConsumerStatefulWidget {
  const AddAddressScreen({super.key});

  @override
  ConsumerState<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends ConsumerState<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressLineController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();

  String _selectedLabel = 'Home';
  bool _isDefault = false;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _labelOptions = [
    {'value': 'Home', 'label': '自宅', 'icon': Icons.home},
    {'value': 'Work', 'label': '会社', 'icon': Icons.business},
    {'value': 'Other', 'label': 'その他', 'icon': Icons.location_on},
  ];

  @override
  void dispose() {
    _addressLineController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ref.read(addressListProvider.notifier).addAddress(
            addressLine: _addressLineController.text.trim(),
            city: _cityController.text.trim(),
            postalCode: _postalCodeController.text.trim(),
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

              // Address line
              CustomTextField(
                controller: _addressLineController,
                labelText: '住所',
                hintText: '例: 東京都渋谷区神南1-2-3',
                prefixIcon: const Icon(Icons.location_on_outlined),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '住所を入力してください';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // City
              CustomTextField(
                controller: _cityController,
                labelText: '市区町村',
                hintText: '例: 渋谷区',
                prefixIcon: const Icon(Icons.location_city),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '市区町村を入力してください';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Postal code
              CustomTextField(
                controller: _postalCodeController,
                labelText: '郵便番号',
                hintText: '例: 150-0041',
                prefixIcon: const Icon(Icons.markunread_mailbox_outlined),
                keyboardType: TextInputType.text,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '郵便番号を入力してください';
                  }
                  return null;
                },
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
