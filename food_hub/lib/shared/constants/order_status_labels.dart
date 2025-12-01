import 'package:flutter/material.dart';

/// 注文ステータスの表示ラベル
/// 各ロール（顧客・レストラン・配達員）ごとに異なる表示を提供
class OrderStatusLabels {
  /// 顧客向けステータスラベル
  static const Map<String, String> customer = {
    'pending': '支払い済み',  // 「保留中」→「支払い済み」に変更
    'accepted': '受理済み',
    'preparing': '準備中',
    'ready': '準備完了',
    'picked_up': 'ピックアップ済み',
    'delivering': '配達中',
    'delivered': '配達完了',
    'cancelled': 'キャンセル',
  };

  /// レストラン向けステータスラベル
  static const Map<String, String> restaurant = {
    'pending': '新規',  // レストラン側では「新規」
    'accepted': '受付済み',
    'preparing': '準備中',
    'ready': '準備完了',
    'picked_up': '配達中',
    'delivering': '配達中',
    'delivered': '配達完了',
    'cancelled': 'キャンセル',
  };

  /// 配達員向けステータスラベル
  static const Map<String, String> driver = {
    'pending': '保留中',
    'accepted': '受理済み',
    'preparing': '準備中',
    'ready': 'ピックアップ可能',  // 配達員には「ピックアップ可能」
    'picked_up': 'ピックアップ済み',
    'delivering': '配達中',
    'delivered': '配達完了',
    'cancelled': 'キャンセル',
  };

  /// ステータスに対応する色を取得
  static Map<String, dynamic> getStatusStyle(String status) {
    switch (status) {
      case 'pending':
        return {'color': const Color(0xFF4CAF50), 'label': 'success'};  // 緑色（支払い済み）
      case 'accepted':
        return {'color': const Color(0xFF2196F3), 'label': 'info'};  // 青色
      case 'preparing':
        return {'color': const Color(0xFF9C27B0), 'label': 'warning'};  // 紫色
      case 'ready':
        return {'color': const Color(0xFF4CAF50), 'label': 'success'};  // 緑色
      case 'picked_up':
        return {'color': const Color(0xFF00BCD4), 'label': 'info'};  // 水色
      case 'delivering':
        return {'color': const Color(0xFFFF9800), 'label': 'warning'};  // オレンジ色
      case 'delivered':
        return {'color': const Color(0xFF9E9E9E), 'label': 'default'};  // グレー
      case 'cancelled':
        return {'color': const Color(0xFFF44336), 'label': 'danger'};  // 赤色
      default:
        return {'color': const Color(0xFF9E9E9E), 'label': 'default'};
    }
  }
}
