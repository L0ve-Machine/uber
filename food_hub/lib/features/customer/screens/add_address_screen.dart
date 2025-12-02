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
  final _postalCodeController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();

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
    _postalCodeController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
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
            postalCode: _postalCodeController.text.trim(),
            addressLine1: _addressLine1Controller.text.trim(),
            addressLine2: _addressLine2Controller.text.trim().isEmpty
                ? null
                : _addressLine2Controller.text.trim(),
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
              ),

              const SizedBox(height: 16),

              // Address line 2 (Building/Apartment - Optional)
              CustomTextField(
                controller: _addressLine2Controller,
                labelText: '住所2 (建物名・部屋番号)',
                hintText: '例: グランドメゾン青山 402号室',
                prefixIcon: const Icon(Icons.apartment_outlined),
                validator: null, // Optional field
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
