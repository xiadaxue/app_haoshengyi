import 'dart:io';
import 'package:flutter/material.dart'; // 添加以支持对话框
import 'package:haoshengyi_jzzs_app/api/http_client.dart';
import 'package:haoshengyi_jzzs_app/constants/api_constants.dart';
import 'package:haoshengyi_jzzs_app/models/voice_recognition_model.dart';

/// 语音/文本记账服务类，处理语音识别和文本解析功能
class AccountingService {
  final HttpClient _httpClient = HttpClient();

  /// 语音识别记账
  Future<VoiceRecognitionModel?> voiceRecognition(
      File audioFile, double duration) async {
    try {
      final data = await _httpClient.uploadFile(
        ApiConstants.accountingVoice,
        audioFile.path,
      );

      // 直接返回解析后的数据
      return VoiceRecognitionModel.fromJson(data);
    } catch (e) {
      // 打印错误日志并抛出异常
      print('语音识别失败: $e');
      rethrow;
    }
  }

  /// 文本记账
  Future<VoiceRecognitionModel?> textRecognition(String text) async {
    try {
      final data = await _httpClient.post(
        ApiConstants.accountingText,
        data: {
          'text': text,
        },
      );
      final newData = {
        'text': text,
        'data': data,
      };
      // 直接返回解析后的数据
      return VoiceRecognitionModel.fromJson(newData);
    } catch (e) {
      // 打印错误日志并抛出异常
      print('文本记账失败: $e');
      rethrow;
    }
  }

  /// 弹出用户确认对话框
  void showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('记账成功'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('确认'),
          ),
        ],
      ),
    );
  }
}
