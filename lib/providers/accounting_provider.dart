import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:haoshengyi_jzzs_app/api/accounting_service.dart';
import 'package:haoshengyi_jzzs_app/api/transaction_service.dart';
import 'package:haoshengyi_jzzs_app/models/transaction_model.dart';
import 'package:haoshengyi_jzzs_app/models/voice_recognition_model.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

/// 语音/文本记账状态提供者
// 在现有的 AccountingProvider 中添加以下代码

import 'package:haoshengyi_jzzs_app/services/xunfei_voice_service.dart';

class AccountingProvider extends ChangeNotifier {
  final AccountingService _accountingService = AccountingService();
  final SpeechToText _speechToText = SpeechToText();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  VoiceRecognitionModel? _recognitionResult;
  VoiceRecognitionModel? get recognitionResult => _recognitionResult;

  String _recognizedText = '';
  String get recognizedText => _recognizedText;

  bool _isSpeechAvailable = false;
  bool get isSpeechAvailable => _isSpeechAvailable;

  bool _isListening = false;
  bool get isListening => _isListening;

  Future<void> initSpeech() async {
    _isSpeechAvailable = await _speechToText.initialize(
      onStatus: _handleSpeechStatus,
      onError: _handleSpeechError,
    );
    notifyListeners();
  }

  void _handleSpeechStatus(String status) {
    if (status == 'done') {
      _isListening = false;
      notifyListeners();
    }
  }

  void _handleSpeechError(dynamic error) {
    print('Speech recognition error: $error');
  }

  Future<bool> requestMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if (status.isDenied) {
      status = await Permission.microphone.request();
    }
    return status.isGranted;
  }

  // 修改startListening方法，添加空值处理
  Future<void> startListening() async {
    try {
      print('AccountingProvider: 开始语音识别');

      // 初始化语音识别
      _isListening = false; // 确保有初始值
      _recognizedText = '';

      // 这里可能是调用语音识别API的地方
      // 例如：await _speechRecognition.listen(onResult: _onSpeechResult);

      // 更新状态
      _isListening = true;
      notifyListeners();

      print('AccountingProvider: 语音识别已启动，状态: $_isListening');
    } catch (e) {
      print('AccountingProvider: 语音识别启动失败: $e');
      _isListening = false; // 确保失败时状态正确
      notifyListeners();
      rethrow; // 重新抛出异常以便上层处理
    }
  }

  // 修改stopListening方法，添加空值处理
  Future<void> stopListening() async {
    try {
      print('AccountingProvider: 停止语音识别');

      // 这里可能是调用语音识别API停止的地方
      // 例如：await _speechRecognition.stop();

      // 更新状态
      _isListening = false;
      notifyListeners();

      print('AccountingProvider: 语音识别已停止');
    } catch (e) {
      print('AccountingProvider: 语音识别停止失败: $e');
      _isListening = false; // 确保失败时状态正确
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> _checkPermissionsAndAvailability() async {
    final hasPermission = await requestMicrophonePermission();
    if (!hasPermission) {
      throw '需要麦克风权限才能使用语音功能';
    }

    if (!_isSpeechAvailable) {
      await initSpeech();
      if (!_isSpeechAvailable) {
        throw '语音识别功能不可用';
      }
    }

    return true;
  }

  void _resetRecognitionState() {
    _recognizedText = '';
    _recognitionResult = null;
    notifyListeners();
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    _recognizedText = result.recognizedWords;
    notifyListeners();
  }

  Future<VoiceRecognitionModel?> textRecognition(String text) async {
    if (text.isEmpty) return null;

    _setLoading(true);

    try {
      _recognitionResult = await _accountingService.textRecognition(text);
      return _recognitionResult;
    } catch (e) {
      print('文本记账失败: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> processTextAccounting(
    String text, [
    BuildContext? context,
  ]) async {
    if (text.isEmpty) return false;

    _setLoading(true);

    try {
      _recognitionResult = await _accountingService.textRecognition(text);
      if (_recognitionResult == null) return false;

      if (context != null && !await _showConfirmationDialog(context)) {
        return false;
      }

      await _sendTransactionToServer();
      return true;
    } catch (e) {
      print('处理文本记账失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _sendTransactionToServer() async {
    final transactionService = TransactionService();
    final parsedData = _recognitionResult?.parsedData;
    if (parsedData == null) {
      throw '解析数据为空，无法创建交易';
    }

    // 添加到列表第一位
    final newTransaction = TransactionModel(
      type: parsedData.type,
      amount: parsedData.amount,
      category: parsedData.category ?? '',
      remark: parsedData.remark ?? '',
      transactionDate:
          parsedData.transactionDate ?? DateTime.now().toIso8601String(),
      tags: parsedData.tags,
      users: parsedData.users,
      products: List<ProductsModel>.from(
        parsedData.products.map((p) => ProductsModel.fromJson(p.toJson())),
      ),
      containers: List<ContainerModel>.from(
        parsedData.containers.map((c) => ContainerModel.fromJson(c.toJson())),
      ),
      createdAt: DateTime.now().toIso8601String(),
    );

    await transactionService.createTransaction(newTransaction);
  }

  Future<bool> _showConfirmationDialog(BuildContext context) async {
    if (_recognitionResult == null) return false;

    final parsedData = _recognitionResult!.parsedData;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('确认记账'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('您确定要记录以下交易吗？'),
                SizedBox(height: 10),
                Text('类型: ${parsedData.type == 'income' ? '收入' : '支出'}'),
                Text('金额: ${parsedData.amount.toStringAsFixed(2)}元'),
                if (parsedData.products.isNotEmpty) ...[
                  Text(
                      '商品: ${parsedData.products.map((e) => e.name).join(', ')}'),
                  Text(
                      '单价: ${parsedData.products.map((e) => e.unitPrice).join(', ')}元'),
                  Text(
                      '数量: ${parsedData.products.map((e) => e.quantity).join(', ')}'),
                ],
                if (parsedData.remark != null) Text('备注: ${parsedData.remark}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('再想想'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('确定'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _setLoading(bool isLoading) {
    _isLoading = isLoading;
    notifyListeners();
  }

  void clearRecognitionResult() {
    _recognizedText = '';
    _recognitionResult = null;
    notifyListeners();
  }

  // 科大讯飞语音服务
  XunfeiVoiceService? _xunfeiVoiceService;
  bool _isInitialized = false;
  String _xunfeiErrorMessage = "";

  // 初始化科大讯飞语音服务
  Future<bool> initializeXunfeiVoiceService() async {
    try {
      _xunfeiVoiceService = XunfeiVoiceService(
        onResult: (text, {bool isFinal = false}) {
          _recognizedText = text;
          notifyListeners();
        },
        onError: () {
          _isListening = false;
          // 获取详细的错误信息
          if (_xunfeiVoiceService != null) {
            _xunfeiErrorMessage = _xunfeiVoiceService!.getErrorMessage();
            print('讯飞语音错误: $_xunfeiErrorMessage');
          }
          notifyListeners();
        },
        onFinish: () {
          _isListening = false;
          notifyListeners();
        },
      );

      // 检查是否使用默认API密钥，但仍然尝试连接
      if (_xunfeiVoiceService!.isUsingDefaultApiKey()) {
        print('⚠️ 提示: 正在使用代码中默认的科大讯飞API密钥配置');
        print('⚠️ 如果这是您自己的API密钥，请忽略此提示');
      }

      // // 不管是否使用默认密钥，都尝试初始化
      // final initialized = await _xunfeiVoiceService!.initialize();

      // // 连接测试
      // if (initialized) {
      //   final connectionWorks = await _xunfeiVoiceService!.testConnection();
      //   if (!connectionWorks) {
      //     // 记录连接测试失败的错误信息
      //     _xunfeiErrorMessage = _xunfeiVoiceService!.getErrorMessage();
      //     print('讯飞语音服务连接测试失败: $_xunfeiErrorMessage');

      //     // 检查是否是403错误（API密钥问题）
      //     if (_xunfeiErrorMessage.contains('403') ||
      //         _xunfeiErrorMessage.contains('鉴权失败') ||
      //         _xunfeiErrorMessage.contains('密钥')) {
      //       print('⚠️ 科大讯飞API密钥可能已过期，请更新');
      //     }
      //   }
      //   return connectionWorks;
      // }

      return false;
    } catch (e) {
      print('初始化科大讯飞语音服务失败: $e');
      _xunfeiErrorMessage = e.toString();
      return false;
    }
  }

  // 获取讯飞语音服务错误信息
  String getXunfeiErrorMessage() {
    return _xunfeiErrorMessage;
  }

  // 开始科大讯飞语音识别
  Future<bool> startXunfeiVoiceRecognition() async {
    // 每次都尝试初始化服务，确保状态正确
    final initialized = await initializeXunfeiVoiceService();
    if (!initialized) {
      print('❌ 错误: 语音服务初始化失败');
      _xunfeiErrorMessage = "语音服务初始化失败";
      if (_xunfeiVoiceService != null) {
        _xunfeiErrorMessage = _xunfeiVoiceService!.getErrorMessage();
        print('❌ 错误详情: $_xunfeiErrorMessage');
      }
      return false;
    }

    // 标记服务已初始化
    _isInitialized = true;

    _recognizedText = '';
    _isListening = true;
    notifyListeners();

    try {
      final success = await _xunfeiVoiceService!.startRecording();
      if (!success) {
        _isListening = false;
        _xunfeiErrorMessage = _xunfeiVoiceService!.getErrorMessage();
        notifyListeners();
      }

      return success;
    } catch (e) {
      _isListening = false;
      _xunfeiErrorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // 停止科大讯飞语音识别
  Future<void> stopXunfeiVoiceRecognition() async {
    if (_xunfeiVoiceService != null) {
      await _xunfeiVoiceService!.stopRecording();
    }

    _isListening = false;
    notifyListeners();
  }

  // 释放科大讯飞语音服务资源
  Future<void> disposeXunfeiVoiceService() async {
    if (_xunfeiVoiceService != null) {
      await _xunfeiVoiceService!.dispose();
      _xunfeiVoiceService = null;
      _isInitialized = false;
    }
  }

  @override
  void dispose() {
    disposeXunfeiVoiceService();
    super.dispose();
  }
}
