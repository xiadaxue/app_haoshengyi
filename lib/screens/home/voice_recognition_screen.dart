import 'package:flutter/material.dart';
import 'package:haoshengyi_jzzs_app/providers/accounting_provider.dart';
import 'package:haoshengyi_jzzs_app/theme/app_theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

/// 语音识别页面 - 使用科大讯飞语音听写API
class VoiceRecognitionScreen extends StatefulWidget {
  const VoiceRecognitionScreen({super.key});

  @override
  State<VoiceRecognitionScreen> createState() => _VoiceRecognitionScreenState();
}

class _VoiceRecognitionScreenState extends State<VoiceRecognitionScreen> {
  // 手势拖动相关
  double _dragStartY = 0;
  bool _isDragging = false;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    // 初始化科大讯飞语音服务
    _initializeVoiceService();
  }

  Future<void> _initializeVoiceService() async {
    final accountingProvider =
        Provider.of<AccountingProvider>(context, listen: false);
    await accountingProvider.initializeXunfeiVoiceService();
  }

  @override
  void dispose() {
    // 停止语音识别
    final accountingProvider =
        Provider.of<AccountingProvider>(context, listen: false);
    if (accountingProvider.isListening) {
      accountingProvider.stopXunfeiVoiceRecognition();
    }
    // 确保清空识别文本
    accountingProvider.clearRecognizedText();
    super.dispose();
  }

  // 开始语音识别（使用讯飞语音服务）
  Future<void> _startListening() async {
    final accountingProvider =
        Provider.of<AccountingProvider>(context, listen: false);
    try {
      await accountingProvider.startXunfeiVoiceRecognition();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('语音识别失败，请检查麦克风权限或重试'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // 停止语音识别
  Future<void> _stopListening() async {
    final accountingProvider =
        Provider.of<AccountingProvider>(context, listen: false);
    await accountingProvider.stopXunfeiVoiceRecognition();
  }

  // 处理语音识别结果
  void _processRecognitionResult() {
    final accountingProvider =
        Provider.of<AccountingProvider>(context, listen: false);

    if (accountingProvider.recognizedText.isNotEmpty) {
      // 返回识别结果
      Navigator.of(context).pop(accountingProvider.recognizedText);

      // 清空识别内容
      accountingProvider.clearRecognizedText();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('语音记账'),
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Consumer<AccountingProvider>(
        builder: (context, provider, _) {
          final bool isListening = provider.isListening;

          return Column(
            children: [
              SizedBox(height: 20.h),

              // 语音识别提示
              Text(
                isListening ? '松开结束，上滑取消' : '按住说话',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppTheme.textSecondaryColor,
                ),
              ),

              SizedBox(height: 30.h),

              // 语音波形和按钮区域
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 识别的文本显示区域
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(20.r),
                        child: Text(
                          provider.recognizedText.isEmpty && !isListening
                              ? '请按住下方按钮开始语音输入'
                              : provider.recognizedText.isEmpty && isListening
                                  ? '正在聆听...'
                                  : provider.recognizedText,
                          style: TextStyle(
                            fontSize: 18.sp,
                            color: AppTheme.textPrimaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    // 取消提示 - 仅在上滑时显示
                    if (_isDragging && _isCancelling)
                      Positioned(
                        top: 100.h,
                        child: Container(
                          padding: EdgeInsets.all(15.r),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            '松开手指取消',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                    // 语音波形动画 - 仅在录音时显示
                    if (isListening && !_isCancelling)
                      Positioned(
                        bottom: 150.h,
                        child: Container(
                          width: 200.w,
                          height: 100.h,
                          child: _buildVoiceWaveAnimation(),
                        ),
                      ),

                    // 语音按钮 - 使用GestureDetector实现按住说话
                    Positioned(
                      bottom: 50.h,
                      child: GestureDetector(
                        onPanStart: (details) {
                          if (!isListening) {
                            _startListening();
                          }
                          setState(() {
                            _dragStartY = details.globalPosition.dy;
                            _isDragging = true;
                            _isCancelling = false;
                          });
                        },
                        onPanUpdate: (details) {
                          if (_isDragging) {
                            // 上滑超过50像素判定为取消
                            final dragDistance =
                                _dragStartY - details.globalPosition.dy;
                            setState(() {
                              _isCancelling = dragDistance > 50;
                            });
                          }
                        },
                        onPanEnd: (details) {
                          if (_isDragging) {
                            if (_isCancelling) {
                              // 取消录音
                              _stopListening();
                              Navigator.of(context).pop();
                            } else {
                              // 结束录音并处理结果
                              _stopListening();
                              _processRecognitionResult();
                            }
                            setState(() {
                              _isDragging = false;
                              _isCancelling = false;
                            });
                          }
                        },
                        child: Container(
                          width: 80.r,
                          height: 80.r,
                          decoration: BoxDecoration(
                            color: _isCancelling
                                ? Colors.red
                                : isListening
                                    ? AppTheme.primaryColor
                                    : Colors.grey.shade300,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (_isCancelling
                                        ? Colors.red
                                        : isListening
                                            ? AppTheme.primaryColor
                                            : Colors.grey)
                                    .withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isCancelling
                                ? Icons.close
                                : isListening
                                    ? Icons.mic
                                    : Icons.mic_none,
                            color: _isCancelling || isListening
                                ? Colors.white
                                : Colors.grey.shade700,
                            size: 30.r,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 构建语音波形动画
  Widget _buildVoiceWaveAnimation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        7,
        (index) => _buildWaveLine(index),
      ),
    );
  }

  // 构建单个波形线
  Widget _buildWaveLine(int index) {
    // 使用不同的高度和动画延迟创建波形效果
    final heights = [20.0, 40.0, 30.0, 50.0, 30.0, 40.0, 20.0];
    final delays = [1200, 700, 600, 800, 500, 900, 400];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 3.w),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 5.0, end: heights[index]),
        duration: Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return Container(
            width: 5.w,
            height: value,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.7),
              borderRadius: BorderRadius.circular(5.r),
            ),
          );
        },
      ),
    );
  }
}
