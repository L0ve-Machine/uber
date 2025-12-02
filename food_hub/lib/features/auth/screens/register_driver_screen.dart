import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../providers/auth_provider.dart';

class RegisterDriverScreen extends ConsumerStatefulWidget {
  const RegisterDriverScreen({super.key});

  @override
  ConsumerState<RegisterDriverScreen> createState() =>
      _RegisterDriverScreenState();
}

class _RegisterDriverScreenState extends ConsumerState<RegisterDriverScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _vehicleTypeController.dispose();
    _licenseNumberController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await ref.read(authProvider.notifier).registerDriver(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _fullNameController.text.trim(),
          phone: _phoneController.text.trim(),
          vehicleType: _vehicleTypeController.text.trim(),
          licenseNumber: _licenseNumberController.text.trim(),
        );

    final authState = ref.read(authProvider);
    authState.when(
      data: (user) {
        if (user != null) {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/driver/dashboard');
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
                  '配達員登録',
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
                  controller: _fullNameController,
                  label: '氏名',
                  prefixIcon: Icons.person,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '氏名を入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _emailController,
                  label: 'メールアドレス',
                  prefixIcon: Icons.email,
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
                  prefixIcon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '電話番号を入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _vehicleTypeController,
                  label: '車両タイプ (例: バイク, 自転車)',
                  prefixIcon: Icons.directions_bike,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '車両タイプを入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _licenseNumberController,
                  label: '免許番号',
                  prefixIcon: Icons.badge,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '免許番号を入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _passwordController,
                  label: 'パスワード',
                  prefixIcon: Icons.lock,
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
                  prefixIcon: Icons.lock_outline,
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
