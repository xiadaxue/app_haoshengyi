import 'dart:io';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:haoshengyi_jzzs_app/utils/toast_util.dart';

/// 语音服务封装类，处理多平台兼容性
class VoiceService {
  late stt.SpeechToText _speech;
  static const MethodChannel _channel =
      MethodChannel('com.haoshengyi/voice_service');

  // 回调函数
  Function(String)? onResult;
  Function()? onFinished;
  Function(String)? onError;

  // 状态标志
  bool _isAvailable = false;

  VoiceService() {
    _speech = stt.SpeechToText();
  }

  /// 初始化语音服务
  Future<bool> initialize({
    Function(String)? onResult,
    Function()? onFinished,
    Function(String)? onError,
  }) async {
    this.onResult = onResult;
    this.onFinished = onFinished;
    this.onError = onError;

    try {
      bool isAvailable = await _speech.initialize(
        onStatus: _handleStatus,
        onError: _handleError,
      );

      _isAvailable = isAvailable;
      return isAvailable;
    } catch (e) {
      ToastUtil.debug('语音服务初始化失败: $e');
      if (onError != null) onError(e.toString());
      return false;
    }
  }

  /// 处理语音识别状态变化
  void _handleStatus(String status) {
    print('语音识别状态: $status');
    if (status == 'done' && onFinished != null) {
      onFinished!();
    }
  }

  /// 处理语音识别错误
  void _handleError(dynamic error) {
    print('语音识别错误: $error');
    if (onError != null) onError!(error.toString());
  }

  /// 开始语音识别
  Future<bool> startListening() async {
    if (!_isAvailable) return false;

    try {
      return await _speech.listen(
        localeId: Platform.isIOS ? 'zh-CN' : 'zh_CN',
        onResult: (result) {
          if (onResult != null) onResult!(result.recognizedWords);
        },
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );
    } catch (e) {
      print('开始语音识别失败: $e');
      if (onError != null) onError!(e.toString());
      return false;
    }
  }

  /// 停止语音识别
  Future<void> stopListening() async {
    try {
      await _speech.stop();
    } catch (e) {
      print('停止语音识别失败: $e');
    }
  }

  /// 获取设备品牌信息
  Object getDeviceBrand() {
    try {
      if (Platform.isAndroid) {
        return _getAndroidBrand();
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  /// 获取Android设备品牌
  Future<String> _getAndroidBrand() async {
    try {
      final String brand = await _channel.invokeMethod('getDeviceBrand');
      return brand;
    } catch (e) {
      return '';
    }
  }

  /// 释放资源
  void dispose() {
    try {
      _speech.cancel();
    } catch (e) {
      print('释放语音服务资源失败: $e');
    }
  }
}
