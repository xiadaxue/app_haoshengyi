import 'dart:io';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'voice_recognition_interface.dart';

class DefaultVoiceService implements VoiceRecognitionInterface {
  late stt.SpeechToText _speech;
  bool _isAvailable = false;

  // 回调函数
  Function(String)? onResult;
  Function()? onFinished;
  Function(String)? onError;

  DefaultVoiceService() {
    _speech = stt.SpeechToText();
  }

  @override
  Future<bool> initialize({
    Function(String)? onResult,
    Function()? onFinished,
    Function(String)? onError,
  }) async {
    this.onResult = onResult;
    this.onFinished = onFinished;
    this.onError = onError;

    try {
      _isAvailable = await _speech.initialize(
        onStatus: _handleStatus,
        onError: _handleError,
      );
      return _isAvailable;
    } catch (e) {
      print('语音服务初始化失败: $e');
      if (onError != null) onError(e.toString());
      return false;
    }
  }

  void _handleStatus(String status) {
    print('语音识别状态: $status');
    if (status == 'done' && onFinished != null) {
      onFinished!();
    }
  }

  void _handleError(dynamic error) {
    print('语音识别错误: $error');
    if (onError != null) onError!(error.toString());
  }

  @override
  Future<bool> startListening() async {
    if (!_isAvailable) return false;

    try {
      return await _speech.listen(
        localeId: Platform.isIOS ? 'zh-CN' : 'zh_CN',
        onResult: (result) {
          if (onResult != null) onResult!(result.recognizedWords);
        },
        cancelOnError: true,
      );
    } catch (e) {
      print('开始语音识别失败: $e');
      if (onError != null) onError!(e.toString());
      return false;
    }
  }

  @override
  Future<void> stopListening() async {
    try {
      await _speech.stop();
    } catch (e) {
      print('停止语音识别失败: $e');
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await _speech.cancel();
    } catch (e) {
      print('释放语音服务资源失败: $e');
    }
  }
}
