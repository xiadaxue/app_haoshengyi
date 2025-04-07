import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:haoshengyi_jzzs_app/providers/accounting_provider.dart';
import 'package:haoshengyi_jzzs_app/providers/transaction_provider.dart';
import 'package:haoshengyi_jzzs_app/screens/home/voice_recognition_screen.dart';
import 'package:haoshengyi_jzzs_app/services/voice_recognition_interface.dart';
import 'package:haoshengyi_jzzs_app/services/voice_service_factory.dart';
import 'package:haoshengyi_jzzs_app/theme/app_theme.dart';
import 'package:haoshengyi_jzzs_app/utils/toast_util.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:haoshengyi_jzzs_app/services/xunfei_voice_service.dart';

/// 语音输入组件
/// 包含语音输入和文字输入功能
class VoiceInputWidget extends StatefulWidget {
  /// 成功记账后的回调
  final VoidCallback onAccountingSuccess;

  const VoiceInputWidget({
    Key? key,
    required this.onAccountingSuccess,
  }) : super(key: key);

  @override
  State<VoiceInputWidget> createState() => _VoiceInputWidgetState();
}

class _VoiceInputWidgetState extends State<VoiceInputWidget> {
  late final XunfeiVoiceService _voiceService;
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isListening = false;
  String _lastWords = ''; // 实时识别结果
  String _finalResult = ''; // 最终识别结果
  String _errorMessage = '';
  String _fullRecognizedText = ''; // 用于存储完整的识别结果

  // 语音配置
  XunfeiLanguage _selectedLanguage = XunfeiLanguage.chinese;
  bool _enableDynamicCorrection = true;

  // 新增变量
  bool _isCancelling = false;
  double _startDragY = 0;

  // 添加一个标志位来防止重复触发
  bool _isProcessingResult = false;

  @override
  void initState() {
    super.initState();
    _initializeVoiceService();
  }

  Future<void> _initializeVoiceService() async {
    try {
      // 初始化讯飞语音服务
      _voiceService = XunfeiVoiceService(
        onResult: (text, {bool isFinal = false}) {
          setState(() {
            if (isFinal) {
              // 避免空结果或与当前结果相同
              if (text.isEmpty || text == _finalResult) return;

              _finalResult = text;
              _lastWords = text;
              _textController.text = text;

              // 直接处理识别结果，不使用延迟以避免任何额外的确认提示
              _processRecognizedText();
            } else {
              _lastWords = text;
            }
          });
        },
        onError: () {
          setState(() {
            _isListening = false;
            _isCancelling = false;
            _errorMessage = _voiceService.getErrorMessage();
          });
          ToastUtil.showError(_errorMessage);
        },
        onFinish: () {
          setState(() {
            _isListening = false;
            _isCancelling = false;
          });
        },
        language: _selectedLanguage,
      );
      // 设置动态修正
      _voiceService.setDynamicCorrection(_enableDynamicCorrection);

      final initialized = await _voiceService.initialize();
      setState(() {
        _isInitialized = initialized;
        if (!initialized) {
          _errorMessage = _voiceService.getErrorMessage();
          ToastUtil.showError(_errorMessage);
        }
      });
    } catch (e) {
      print('初始化语音服务失败: $e');
      ToastUtil.showError('初始化语音服务失败: $e');
    }
  }

  // 开始语音识别
  Future<void> _startListening() async {
    if (_isListening) return;

    try {
      // 清空上次的输入内容
      setState(() {
        _lastWords = '';
        _errorMessage = '';
        _fullRecognizedText = '';
        _isListening = true;
        _finalResult = ''; // 确保清空最终结果
        _textController.clear(); // 清空文本输入框
      });

      print('开始语音识别...');
      final success = await _voiceService.startRecording();
      if (!success) {
        setState(() {
          _isListening = false;
          _errorMessage = _voiceService.getErrorMessage();
        });
        print('语音识别启动失败: $_errorMessage');
        ToastUtil.showError(_errorMessage.isEmpty ? '启动语音识别失败' : _errorMessage);
      } else {
        print('语音识别已启动，等待用户说话...');
      }
    } catch (e) {
      print('语音识别异常: $e');
      setState(() {
        _isListening = false;
        _errorMessage = e.toString();
      });
      ToastUtil.showError(_errorMessage);
    }
  }

  // 停止语音识别
  Future<void> _stopListening({bool isCancelled = false}) async {
    if (!_isListening) return;

    print('停止语音识别，取消=${isCancelled}');
    try {
      await _voiceService.stopRecording();
      print('语音识别已停止');
    } catch (e) {
      print('停止语音识别失败: $e');
      setState(() {
        _errorMessage = e.toString();
      });
      ToastUtil.showError(_errorMessage);
    } finally {
      setState(() {
        _isListening = false;
        _isCancelling = false;
        if (isCancelled) {
          print('用户取消了语音输入');
          _lastWords = '';
          _finalResult = '';
          _fullRecognizedText = '';
          _textController.clear();
        }
      });
    }
  }

  // 处理识别到的文本
  void _processRecognizedText() async {
    // 防止重复处理
    if (_isProcessingResult || _finalResult.isEmpty) return;

    _isProcessingResult = true;

    try {
      // 将识别结果设置到文本框
      _textController.text = _finalResult;

      // 调用处理方法，传入context以显示确认对话框
      await _processTextAccounting();
    } finally {
      // 确保处理完成后重置标志
      _isProcessingResult = false;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  // 打开语音录入页面
  void _openVoiceRecognition() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VoiceRecognitionScreen(),
      ),
    );
  }

  // 处理文本记账
  Future<void> _processTextAccounting() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ToastUtil.showInfo('请输入记账内容');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final accountingProvider =
          Provider.of<AccountingProvider>(context, listen: false);

      // 显示确认对话框进行记账，确保始终传入context以显示确认对话框
      final success =
          await accountingProvider.processTextAccounting(text, context);

      if (success) {
        _textController.clear();
        setState(() {
          _lastWords = '';
          _finalResult = '';
          _fullRecognizedText = '';
        });

        print('语音记账成功，开始刷新数据');

        // 确保记账成功后通知首页刷新数据
        widget.onAccountingSuccess();

        // 成功提示
        ToastUtil.showSuccess('记账成功');

        // 短暂延迟后刷新页面，确保新数据显示出来
        Future.delayed(Duration(milliseconds: 300), () {
          // 确保上下文仍有效
          if (mounted) {
            final transactionProvider =
                Provider.of<TransactionProvider>(context, listen: false);
            // 强制刷新当前数据
            transactionProvider.refreshCurrentData();

            // 额外延迟，再次确保UI更新
            Future.delayed(Duration(milliseconds: 300), () {
              if (mounted) {
                transactionProvider.notifyListeners();
              }
            });
          }
        });
      }
    } catch (e) {
      print('记账失败：$e');
      ToastUtil.showError('记账失败：$e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 修改识别结果显示部分的UI
  Widget _buildRecognitionResult() {
    if (!_isListening && _lastWords.isEmpty) return SizedBox();

    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isListening)
            Text(
              "正在聆听...",
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          Text(
            _lastWords.isEmpty ? "等待识别..." : _lastWords,
            style: TextStyle(
              fontSize: 14.sp,
              color: _lastWords.isEmpty ? Colors.grey : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 15.h),
      color: Colors.white,
      child: Column(
        children: [
          // 提示文本
          Text(
            _isListening ? '正在聆听...' : '点击下方按钮，用说的方式记账',
            style: TextStyle(
              fontSize: 14.sp,
              color: _isListening
                  ? AppTheme.primaryColor
                  : AppTheme.textSecondaryColor,
              fontWeight: _isListening ? FontWeight.bold : FontWeight.normal,
            ),
          ),

          SizedBox(height: 15.h),

          // 语音按钮
          Center(
            child: GestureDetector(
              onLongPressStart: (details) {
                _startDragY = details.globalPosition.dy;
                _startListening();
              },
              onLongPressMoveUpdate: (details) {
                if (_startDragY - details.globalPosition.dy > 50) {
                  if (!_isCancelling) {
                    setState(() {
                      _isCancelling = true;
                    });
                  }
                } else {
                  if (_isCancelling) {
                    setState(() {
                      _isCancelling = false;
                    });
                  }
                }
              },
              onLongPressEnd: (details) {
                if (_isCancelling) {
                  _stopListening(isCancelled: true);
                } else {
                  _stopListening();
                }
              },
              onLongPressCancel: () {
                _stopListening(isCancelled: true);
              },
              child: Container(
                width: 70.r,
                height: 70.r,
                decoration: BoxDecoration(
                  color: _isCancelling
                      ? Colors.grey
                      : (_isListening ? Colors.red : AppTheme.primaryColor),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isCancelling
                              ? Colors.grey
                              : (_isListening
                                  ? Colors.red
                                  : AppTheme.primaryColor))
                          .withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isCancelling ? Icons.close : Icons.mic,
                        color: Colors.white,
                        size: 30.r,
                      ),
                      if (_isListening)
                        Text(
                          _isCancelling ? '上滑取消' : '松开完成', // 修改提示文案
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // 使用修改后的识别结果显示组件
          _buildRecognitionResult(),

          SizedBox(height: 15.h),

          // 文本输入区域
          Container(
            padding: EdgeInsets.symmetric(horizontal: 15.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25.r),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: '输入一句话记账，如：卖出2斤苹果',
                      hintStyle: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    style: TextStyle(fontSize: 14.sp),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _processTextAccounting(),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _processTextAccounting,
                    borderRadius: BorderRadius.circular(20.r),
                    child: Container(
                      width: 40.r,
                      height: 40.r,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: _isLoading
                          ? Center(
                              child: SizedBox(
                                width: 20.r,
                                height: 20.r,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              ),
                            )
                          : Center(
                              child: Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 20.r,
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
    );
  }
}
