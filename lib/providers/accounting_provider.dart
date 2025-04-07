import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:haoshengyi_jzzs_app/api/accounting_service.dart';
import 'package:haoshengyi_jzzs_app/api/transaction_service.dart';
import 'package:haoshengyi_jzzs_app/models/transaction_model.dart';
import 'package:haoshengyi_jzzs_app/models/voice_recognition_model.dart'
    hide Container;
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

  // 语音/文本记账处理完成后清空数据
  void clearAfterProcessing() {
    _recognizedText = '';
    _recognitionResult = null;
    notifyListeners();
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

      // 如果提供了context，则显示确认对话框
      if (context != null) {
        if (!await _showConfirmationDialog(context)) {
          clearAfterProcessing();
          return false;
        }
      } else {
        // 没有context，则跳过确认对话框（语音识别直接处理）
        print('语音识别：直接处理记账，跳过确认对话框');
      }

      await _sendTransactionToServer();

      // 成功处理后清空所有识别数据
      clearAfterProcessing();
      return true;
    } catch (e) {
      print('处理文本记账失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 创建或更新交易记录对象（确保包含结算状态）
  Future<void> _sendTransactionToServer() async {
    final transactionService = TransactionService();
    final parsedData = _recognitionResult?.parsedData;
    if (parsedData == null) {
      throw '解析数据为空，无法创建交易';
    }

    print('开始创建交易记录：${parsedData.type} ${parsedData.amount}元');

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
      classType: parsedData.classType ?? 'cash', // 确保传递交易属性
      settlementStatus: parsedData.settlementStatus ??
          TransactionModel.unsettledStatus, // 确保传递结算状态，使用常量
    );

    final transactionId =
        await transactionService.createTransaction(newTransaction);
    print('交易记录创建成功，ID: $transactionId');
  }

  Future<bool> _showConfirmationDialog(BuildContext context) async {
    if (_recognitionResult == null) return false;

    ParsedData parsedData = _recognitionResult!.parsedData;

    // 创建可编辑副本
    String editType = parsedData.type;
    double editAmount = parsedData.amount;
    String editClassType = parsedData.classType ?? 'cash';
    String editSettlementStatus = parsedData.settlementStatus ?? 'unsettled';
    String editRemark = parsedData.remark ?? '';

    // 创建产品列表的可编辑副本
    List<Map<String, dynamic>> editProducts = parsedData.products
        .map((product) => {
              'name': product.name,
              'quantity': product.quantity,
              'unit': product.unit,
              'unitPrice': product.unitPrice,
            })
        .toList();

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, color: Colors.green, size: 24),
                SizedBox(width: 8),
                const Text('确认记账',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: StatefulBuilder(
              builder: (context, setState) {
                return Container(
                  constraints: BoxConstraints(maxHeight: 450), // 限制最大高度
                  width: MediaQuery.of(context).size.width * 0.85, // 设置宽度
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 交易类型选择 - 使用分段控件风格
                        Container(
                          margin: EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '交易类型',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            editType = 'income';
                                          });
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 10),
                                          decoration: BoxDecoration(
                                            color: editType == 'income'
                                                ? Colors.green
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '收入',
                                              style: TextStyle(
                                                color: editType == 'income'
                                                    ? Colors.white
                                                    : Colors.black87,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            editType = 'expense';
                                          });
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 10),
                                          decoration: BoxDecoration(
                                            color: editType == 'expense'
                                                ? Colors.red
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '支出',
                                              style: TextStyle(
                                                color: editType == 'expense'
                                                    ? Colors.white
                                                    : Colors.black87,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 资金/资产类型选择
                        Container(
                          margin: EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '交易属性',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            editClassType = 'cash';
                                          });
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 10),
                                          decoration: BoxDecoration(
                                            color: editClassType == 'cash'
                                                ? Colors.blue
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '现金',
                                              style: TextStyle(
                                                color: editClassType == 'cash'
                                                    ? Colors.white
                                                    : Colors.black87,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            editClassType = 'asset';
                                          });
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 10),
                                          decoration: BoxDecoration(
                                            color: editClassType == 'asset'
                                                ? Colors.purple
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '资产',
                                              style: TextStyle(
                                                color: editClassType == 'asset'
                                                    ? Colors.white
                                                    : Colors.black87,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 金额输入
                        Container(
                          margin: EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '金额',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              TextField(
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  prefixIcon: Icon(
                                    Icons.attach_money,
                                    color: editType == 'income'
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                keyboardType: TextInputType.numberWithOptions(
                                    decimal: true),
                                controller: TextEditingController(
                                    text: editAmount.toString()),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: editType == 'income'
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                onChanged: (value) {
                                  editAmount =
                                      double.tryParse(value) ?? editAmount;
                                },
                              ),
                            ],
                          ),
                        ),

                        // 结算状态选择
                        Container(
                          margin: EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '结算状态',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            editSettlementStatus = 'unsettled';
                                          });
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 10),
                                          decoration: BoxDecoration(
                                            color: editSettlementStatus ==
                                                    'unsettled'
                                                ? Colors.orange
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '未结算',
                                              style: TextStyle(
                                                color: editSettlementStatus ==
                                                        'unsettled'
                                                    ? Colors.white
                                                    : Colors.black87,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            editSettlementStatus = 'settled';
                                          });
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 10),
                                          decoration: BoxDecoration(
                                            color: editSettlementStatus ==
                                                    'settled'
                                                ? Colors.green
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '已结算',
                                              style: TextStyle(
                                                color: editSettlementStatus ==
                                                        'settled'
                                                    ? Colors.white
                                                    : Colors.black87,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 商品信息
                        if (parsedData.products.isNotEmpty) ...[
                          Container(
                            margin: EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '商品信息',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8),
                                ...editProducts.asMap().entries.map((entry) {
                                  int index = entry.key;
                                  Map<String, dynamic> product = entry.value;
                                  return Container(
                                    margin: EdgeInsets.only(bottom: 10),
                                    padding: EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${product['name']}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                decoration: InputDecoration(
                                                  labelText: '数量',
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                                ),
                                                controller:
                                                    TextEditingController(
                                                        text:
                                                            product['quantity']
                                                                .toString()),
                                                onChanged: (value) {
                                                  setState(() {
                                                    product['quantity'] = value;
                                                  });
                                                },
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: TextField(
                                                decoration: InputDecoration(
                                                  labelText: '单价',
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                                ),
                                                keyboardType: TextInputType
                                                    .numberWithOptions(
                                                        decimal: true),
                                                controller:
                                                    TextEditingController(
                                                        text:
                                                            product['unitPrice']
                                                                .toString()),
                                                onChanged: (value) {
                                                  setState(() {
                                                    product['unitPrice'] =
                                                        double.tryParse(
                                                                value) ??
                                                            product[
                                                                'unitPrice'];
                                                  });
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ],

                        // 备注
                        Container(
                          margin: EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '备注',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              TextField(
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  hintText: '添加备注信息...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                controller:
                                    TextEditingController(text: editRemark),
                                maxLines: 2,
                                onChanged: (value) {
                                  editRemark = value;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('取消', style: TextStyle(color: Colors.grey[700])),
              ),
              ElevatedButton(
                onPressed: () {
                  // 在确认前，用编辑后的值创建新的ParsedData对象并替换到_recognitionResult中
                  List<Products> updatedProducts = editProducts
                      .map((p) => Products(
                            name: p['name'],
                            quantity: p['quantity'],
                            unit: p['unit'] ?? '',
                            unitPrice: p['unitPrice'],
                          ))
                      .toList();

                  // 创建新的ParsedData对象
                  ParsedData updatedParsedData = ParsedData(
                    type: editType,
                    amount: editAmount,
                    category: parsedData.category,
                    remark: editRemark,
                    transactionDate: parsedData.transactionDate,
                    users: parsedData.users,
                    products: updatedProducts,
                    containers: parsedData.containers,
                    tags: parsedData.tags,
                    classType: editClassType,
                    settlementStatus: editSettlementStatus,
                  );

                  // 替换原始数据
                  _recognitionResult = VoiceRecognitionModel(
                    text: _recognitionResult!.text,
                    parsedData: updatedParsedData,
                  );

                  Navigator.of(context).pop(true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child:
                    Text('确认记账', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    // 每次开始前先清空识别文本
    _recognizedText = '';
    notifyListeners();

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

  void clearRecognizedText() {
    _recognizedText = '';
    notifyListeners();
  }
}
