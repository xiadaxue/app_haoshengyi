import 'dart:async';
import 'package:flutter/material.dart';
import 'package:haoshengyi_jzzs_app/constants/app_constants.dart';
import 'package:haoshengyi_jzzs_app/providers/auth_provider.dart';
import 'package:haoshengyi_jzzs_app/screens/auth/login_screen.dart';
import 'package:haoshengyi_jzzs_app/screens/home/main_screen.dart';
import 'package:haoshengyi_jzzs_app/theme/app_theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

/// 启动页面
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // 延迟2秒后初始化认证状态并跳转
    Timer(const Duration(seconds: 2), () {
      _initAuth();
    });
  }

  // 初始化认证状态并根据登录状态跳转
  Future<void> _initAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.initAuthState();

    if (!mounted) return;

    // 根据登录状态跳转到不同页面
    if (authProvider.isLoggedIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient(),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 120.w,
                height: 120.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.bookmark,
                  size: 60.w,
                  color: AppTheme.primaryColor,
                ),
              ),

              SizedBox(height: 20.h),

              // 应用名称
              Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              SizedBox(height: 10.h),

              // 标语
              Text(
                AppConstants.appSlogan,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
