import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

/// Toast提示工具类
class ToastUtil {
  // 是否启用调试日志
  static bool _debugMode = true;

  /// 显示加载中
  static void showLoading({String? message}) {
    EasyLoading.show(status: message ?? '加载中...', dismissOnTap: false);
  }

  /// 隐藏加载中
  static void dismissLoading() {
    EasyLoading.dismiss();
  }

  /// 显示成功提示
  static void showSuccess(String message) {
    EasyLoading.showSuccess(message);
    if (_debugMode) {
      debugPrint('✅ 成功: $message');
    }
  }

  /// 显示错误提示
  static void showError(String message) {
    EasyLoading.showError(message);
    if (_debugMode) {
      debugPrint('❌ 错误: $message');
    }
  }

  /// 显示信息提示
  static void showInfo(String message) {
    EasyLoading.showInfo(message);
    if (_debugMode) {
      debugPrint('ℹ️ 信息: $message');
    }
  }

  /// 显示Toast提示
  static void showToast(String message) {
    EasyLoading.showToast(message);
    if (_debugMode) {
      debugPrint('🔔 提示: $message');
    }
  }
  
  /// 打印调试日志（不显示UI提示）
  static void debug(String message) {
    if (_debugMode) {
      debugPrint('🔍 调试: $message');
    }
  }
  
  /// 设置调试模式
  static void setDebugMode(bool enabled) {
    _debugMode = enabled;
  }

  /// 配置EasyLoading
  static void configLoading() {
    EasyLoading.instance
      ..displayDuration = const Duration(milliseconds: 2000)
      ..indicatorType = EasyLoadingIndicatorType.fadingCircle
      ..loadingStyle = EasyLoadingStyle.dark
      ..indicatorSize = 45.0
      ..radius = 10.0
      ..progressColor = Colors.white
      ..backgroundColor = Colors.black.withOpacity(0.7)
      ..indicatorColor = Colors.white
      ..textColor = Colors.white
      ..maskType = EasyLoadingMaskType.black
      ..maskColor = Colors.black.withOpacity(0.5)
      ..userInteractions = false
      ..dismissOnTap = true;
  }
}
