# ========================================
# Flutter Stripe - R8/ProGuard Rules
# ========================================

# Push Provisioning関連の警告を無視
-dontwarn com.stripe.android.pushProvisioning.**

# Stripe SDK全体を保護（決済機能に必須）
-keep class com.stripe.** { *; }

# React Native Stripe SDK参照の警告を無視
-dontwarn com.reactnativestripesdk.**
