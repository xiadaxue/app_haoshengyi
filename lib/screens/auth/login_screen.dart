import 'package:flutter/material.dart';
import 'package:haoshengyi_jzzs_app/constants/app_constants.dart';
import 'package:haoshengyi_jzzs_app/providers/auth_provider.dart';
import 'package:haoshengyi_jzzs_app/screens/auth/register_screen.dart'; // 引入注册页面
import 'package:haoshengyi_jzzs_app/screens/home/main_screen.dart';
import 'package:haoshengyi_jzzs_app/theme/app_theme.dart';
import 'package:haoshengyi_jzzs_app/utils/toast_util.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

/// 登录页面
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  bool _isCodeSent = false;
  int _countdown = 60;
  bool _isCountingDown = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  // 开始倒计时
  void _startCountdown() {
    if (_isCountingDown) return;

    setState(() {
      _isCountingDown = true;
      _countdown = 60;
    });

    // 创建定时器递归调用
    _countdownTimer();
  }

  // 倒计时定时器
  void _countdownTimer() {
    if (!mounted) return;
    
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      setState(() {
        _countdown--;
      });

      if (_countdown > 0) {
        _countdownTimer();
      } else {
        setState(() {
          _isCountingDown = false;
        });
      }
    });
  }

  // 发送验证码
  Future<void> _sendVerificationCode() async {
    if (_phoneController.text.isEmpty) {
      ToastUtil.showError('请输入手机号码');
      return;
    }

    if (_phoneController.text.length != 11) {
      ToastUtil.showError('请输入正确的手机号码');
      return;
    }

    if (_isCountingDown) return;

    try {
      ToastUtil.showLoading(message: '发送中...');

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result =
          await authProvider.sendVerificationCode(_phoneController.text);

      ToastUtil.dismissLoading();

      if (result) {
        setState(() {
          _isCodeSent = true;
        });
        _startCountdown();
        ToastUtil.showSuccess('验证码已发送');
      }
    } catch (e) {
      ToastUtil.dismissLoading();
      ToastUtil.showError(e.toString());
    }
  }

  // 登录
  Future<void> _login() async {
    if (_phoneController.text.isEmpty) {
      ToastUtil.showError('请输入手机号码');
      return;
    }

    if (_phoneController.text.length != 11) {
      ToastUtil.showError('请输入正确的手机号码');
      return;
    }

    if (_codeController.text.isEmpty) {
      ToastUtil.showError('请输入验证码');
      return;
    }

    try {
      ToastUtil.showLoading(message: '登录中...');

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.login(
        _phoneController.text,
        _codeController.text,
      );

      ToastUtil.dismissLoading();

      if (result) {
        if (!mounted) return;

        // 登录成功，跳转到主页面
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      ToastUtil.dismissLoading();
      ToastUtil.showError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 40.h),

              // 标题
              Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 10.h),

              // 副标题
              Text(
                '轻松记账，生意更好',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppTheme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 50.h),

              // 手机号输入框
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: '请输入手机号码',
                    prefixIcon: Icon(
                      Icons.phone_android,
                      color: AppTheme.primaryColor,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 15.w,
                      vertical: 15.h,
                    ),
                  ),
                  maxLength: 11,
                  buildCounter: (context,
                          {required currentLength,
                          required isFocused,
                          maxLength}) =>
                      null,
                ),
              ),

              SizedBox(height: 20.h),

              // 验证码输入框
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '请输入验证码',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 15.w,
                            vertical: 15.h,
                          ),
                        ),
                        maxLength: 6,
                        buildCounter: (context,
                                {required currentLength,
                                required isFocused,
                                maxLength}) =>
                            null,
                      ),
                    ),
                  ),

                  SizedBox(width: 10.w),

                  // 发送验证码按钮
                  GestureDetector(
                    onTap: _isCountingDown ? null : _sendVerificationCode,
                    child: Container(
                      width: 120.w,
                      height: 50.h,
                      decoration: BoxDecoration(
                        color: _isCountingDown
                            ? Colors.grey.shade300
                            : AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _isCountingDown ? '$_countdown秒后重发' : '获取验证码',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: _isCountingDown
                              ? Colors.grey.shade600
                              : AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 30.h),

              // 登录按钮
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 15.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                child: Text(
                  '马上开始记账',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const Spacer(),

              // 注册链接
              Padding(
                padding: EdgeInsets.only(bottom: 20.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '还没有账号？',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // 跳转到注册页面
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RegisterScreen(),
                          ),
                        );
                      },
                      child: Text(
                        '立即注册',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
