import 'dart:async';
import 'package:flutter/material.dart';
import 'package:haoshengyi_jzzs_app/constants/app_constants.dart';
import 'package:haoshengyi_jzzs_app/providers/auth_provider.dart';
import 'package:haoshengyi_jzzs_app/screens/home/main_screen.dart';
import 'package:haoshengyi_jzzs_app/theme/app_theme.dart';
import 'package:haoshengyi_jzzs_app/utils/toast_util.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _verificationCodeController =
      TextEditingController();
  bool isButtonEnabled = false;
  int _countdown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 添加监听器
    _phoneController.addListener(_updateButtonState);
    _nicknameController.addListener(_updateButtonState);
    _verificationCodeController.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.removeListener(_updateButtonState);
    _nicknameController.removeListener(_updateButtonState);
    _verificationCodeController.removeListener(_updateButtonState);
    _phoneController.dispose();
    _nicknameController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    setState(() {
      isButtonEnabled = _phoneController.text.length == 11 &&
          _nicknameController.text.isNotEmpty &&
          _verificationCodeController.text.isNotEmpty;
    });
  }

  void _startCountdown() {
    setState(() {
      _countdown = 60;
    });
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          timer.cancel();
        }
      });
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

    if (_countdown > 0) return;

    try {
      ToastUtil.showLoading(message: '发送中...');

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result =
          await authProvider.sendVerificationCode(_phoneController.text);

      ToastUtil.dismissLoading();

      if (result) {
        _startCountdown();
        ToastUtil.showSuccess('验证码已发送');
      }
    } catch (e) {
      ToastUtil.dismissLoading();
      ToastUtil.showError(e.toString());
    }
  }

  // 注册
  Future<void> _register() async {
    if (_phoneController.text.isEmpty) {
      ToastUtil.showError('请输入手机号码');
      return;
    }

    if (_phoneController.text.length != 11) {
      ToastUtil.showError('请输入正确的手机号码');
      return;
    }

    if (_nicknameController.text.isEmpty) {
      ToastUtil.showError('请输入昵称');
      return;
    }

    if (_verificationCodeController.text.isEmpty) {
      ToastUtil.showError('请输入验证码');
      return;
    }

    try {
      ToastUtil.showLoading(message: '注册中...');

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.register(
        _phoneController.text,
        _verificationCodeController.text,
        nickname: _nicknameController.text,
      );

      ToastUtil.dismissLoading();

      if (result) {
        if (!mounted) return;

        // 注册成功，跳转到主页面
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
      appBar: AppBar(
        title: Text('注册账号'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 30.h),

              // 标题
              Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 10.h),

              // 副标题
              Text(
                '创建新账号，开始记账之旅',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppTheme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 40.h),

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

              SizedBox(height: 15.h),

              // 昵称输入框
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
                  controller: _nicknameController,
                  decoration: InputDecoration(
                    hintText: '请输入昵称',
                    prefixIcon: Icon(
                      Icons.person,
                      color: AppTheme.primaryColor,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 15.w,
                      vertical: 15.h,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 15.h),

              // 验证码输入框
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
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _verificationCodeController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '请输入验证码',
                          prefixIcon: Icon(
                            Icons.security,
                            color: AppTheme.primaryColor,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 15.w,
                            vertical: 15.h,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _countdown > 0 ? null : _sendVerificationCode,
                      child: Container(
                        width: 120.w,
                        height: 50.h,
                        decoration: BoxDecoration(
                          color: _countdown > 0
                              ? Colors.grey.shade300
                              : AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _countdown > 0 ? '$_countdown秒后重发' : '获取验证码',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: _countdown > 0
                                ? Colors.grey.shade600
                                : AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30.h),

              // 注册按钮
              ElevatedButton(
                onPressed: isButtonEnabled ? _register : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade500,
                  padding: EdgeInsets.symmetric(vertical: 15.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                child: Text(
                  '立即注册',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              SizedBox(height: 20.h),

              // 已有账号提示
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '已有账号？',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      '立即登录',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
