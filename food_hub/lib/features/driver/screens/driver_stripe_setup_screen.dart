import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/driver_stripe_connect_service.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/driver_profile_provider.dart';

class DriverStripeSetupScreen extends ConsumerStatefulWidget {
  const DriverStripeSetupScreen({super.key});

  @override
  ConsumerState<DriverStripeSetupScreen> createState() => _DriverStripeSetupScreenState();
}

class _DriverStripeSetupScreenState extends ConsumerState<DriverStripeSetupScreen> {
  final DriverStripeConnectService _stripeConnectService = DriverStripeConnectService();

  bool _isLoading = true;
  bool _hasAccount = false;
  bool _onboardingComplete = false;
  bool _payoutsEnabled = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAccountStatus();
  }

  Future<void> _loadAccountStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final storageService = ref.read(storageServiceProvider);
      final token = await storageService.getAuthToken();

      if (token == null) {
        throw Exception('認証トークンが見つかりません');
      }

      final status = await _stripeConnectService.getAccountStatus(token);

      setState(() {
        _hasAccount = status['stripe_account_id'] != null;
        _onboardingComplete = status['stripe_onboarding_completed'] ?? false;
        _payoutsEnabled = status['stripe_payouts_enabled'] ?? false;
        _isLoading = false;
      });

      // プロフィールProviderも更新
      ref.read(driverProfileProvider.notifier).refresh();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _startOnboarding() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final storageService = ref.read(storageServiceProvider);
      final token = await storageService.getAuthToken();

      if (token == null) {
        throw Exception('認証トークンが見つかりません');
      }

      // オンボーディングURL取得
      final url = await _stripeConnectService.startOnboarding(token);

      // ブラウザで開く
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        // ダイアログ表示
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Stripe登録'),
              content: const Text(
                'Stripeのページで本人確認と銀行口座の登録を完了してください。\n\n'
                '完了後、このページに戻って「状態を更新」ボタンを押してください。',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('閉じる'),
                ),
              ],
            ),
          );
        }
      } else {
        throw Exception('URLを開けませんでした');
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('振込先設定'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  const Icon(
                    Icons.account_balance,
                    size: 80,
                    color: Colors.black,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Stripe Connect 設定',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '報酬を受け取るためにStripeアカウントの登録が必要です',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // エラーメッセージ
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ステータスカード
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'アカウント状態',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildStatusRow('アカウント作成', _hasAccount),
                          _buildStatusRow('オンボーディング完了', _onboardingComplete),
                          _buildStatusRow('支払い受取可能', _payoutsEnabled),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // アクションボタン
                  if (!_payoutsEnabled)
                    ElevatedButton.icon(
                      onPressed: _startOnboarding,
                      icon: const Icon(Icons.launch),
                      label: Text(
                        !_hasAccount
                            ? 'Stripe登録を開始'
                            : !_onboardingComplete
                                ? 'オンボーディング続行'
                                : '本人確認を完了',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    onPressed: _loadAccountStatus,
                    icon: const Icon(Icons.refresh),
                    label: const Text('状態を更新'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 情報セクション
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.grey.shade700),
                            const SizedBox(width: 8),
                            Text(
                              '登録について',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '・ Stripeは世界中で利用される決済プラットフォームです\n'
                          '・ 本人確認書類（運転免許証など）が必要です\n'
                          '・ 銀行口座情報の登録が必要です\n'
                          '・ 登録完了後、報酬の受け取りが可能になります\n'
                          '・ 手数料: なし（配送料を全額受け取れます）',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusRow(String label, bool isComplete) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isComplete ? Colors.green : Colors.grey,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: isComplete ? Colors.black : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
