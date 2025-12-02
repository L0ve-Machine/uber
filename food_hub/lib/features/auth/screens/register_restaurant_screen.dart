import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../providers/auth_provider.dart';

class RegisterRestaurantScreen extends ConsumerStatefulWidget {
  const RegisterRestaurantScreen({super.key});

  @override
  ConsumerState<RegisterRestaurantScreen> createState() =>
      _RegisterRestaurantScreenState();
}

class _RegisterRestaurantScreenState
    extends ConsumerState<RegisterRestaurantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'Japanese';
  double? _latitude;
  double? _longitude;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Category mapping: English value (for DB) -> Japanese label (for UI)
  final Map<String, String> _categoryMap = {
    'Japanese': '和食',
    'Italian': 'イタリアン',
    'Chinese': '中華',
    'Korean': '韓国料理',
    'American': 'アメリカン',
    'French': 'フレンチ',
    'Thai': 'タイ料理',
    'Indian': 'インド料理',
    'Mexican': 'メキシカン',
    'Cafe': 'カフェ',
    'Dessert': 'デザート',
    'Fast Food': 'ファストフード',
    'Other': 'その他',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Show loading
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('住所を確認しています...'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    // Geocode address automatically
    final address = _addressController.text.trim();
    try {
      final locations = await locationFromAddress(address);

      if (locations.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('入力された住所が見つかりませんでした。正しい住所を入力してください'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final location = locations.first;
      _latitude = location.latitude;
      _longitude = location.longitude;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('住所の確認に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Proceed with registration
    await ref.read(authProvider.notifier).registerRestaurant(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          category: _selectedCategory,
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          latitude: _latitude!,
          longitude: _longitude!,
        );

    final authState = ref.read(authProvider);
    authState.when(
      data: (user) {
        if (user != null) {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/restaurant/dashboard');
          }
        }
      },
      loading: () {},
      error: (error, _) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '店舗登録',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '登録後、管理者の承認が必要です',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),

                CustomTextField(
                  controller: _nameController,
                  label: '店舗名',
                  prefixIcon: const Icon(Icons.store),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '店舗名を入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _emailController,
                  label: 'メールアドレス',
                  prefixIcon: const Icon(Icons.email),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'メールアドレスを入力してください';
                    }
                    if (!value.contains('@')) {
                      return '有効なメールアドレスを入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _phoneController,
                  label: '電話番号',
                  prefixIcon: const Icon(Icons.phone),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '電話番号を入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category Dropdown
                const Text(
                  'カテゴリ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      items: _categoryMap.entries.map((entry) {
                        return DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _addressController,
                  label: '住所',
                  prefixIcon: const Icon(Icons.location_on),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '住所を入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _descriptionController,
                  label: '説明 (任意)',
                  prefixIcon: const Icon(Icons.description),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _passwordController,
                  label: 'パスワード',
                  prefixIcon: const Icon(Icons.lock),
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'パスワードを入力してください';
                    }
                    if (value.length < 8) {
                      return 'パスワードは8文字以上で入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _confirmPasswordController,
                  label: 'パスワード確認',
                  prefixIcon: const Icon(Icons.lock_outline),
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'パスワードを再入力してください';
                    }
                    if (value != _passwordController.text) {
                      return 'パスワードが一致しません';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                CustomButton(
                  text: '登録',
                  onPressed: authState.isLoading ? null : _handleRegister,
                  isLoading: authState.isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
