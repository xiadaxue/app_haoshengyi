import 'package:flutter/material.dart';
import 'package:haoshengyi_jzzs_app/config/app_config.dart';
import 'package:haoshengyi_jzzs_app/providers/accounting_provider.dart';
import 'package:haoshengyi_jzzs_app/providers/auth_provider.dart';
import 'package:haoshengyi_jzzs_app/providers/category_provider.dart';
import 'package:haoshengyi_jzzs_app/providers/transaction_provider.dart';
import 'package:haoshengyi_jzzs_app/screens/splash_screen.dart';
import 'package:haoshengyi_jzzs_app/services/timezone_service.dart';
import 'package:haoshengyi_jzzs_app/theme/app_theme.dart';
import 'package:haoshengyi_jzzs_app/utils/toast_util.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化应用配置，这里选择开发环境
  // 可以根据需要切换环境: dev, staging, prod
  AppConfig.initialize(Environment.staging);

  ToastUtil.configLoading();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // 在 MultiProvider 中添加 TimezoneService
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => AccountingProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => TimezoneService()..initialize()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(360, 720),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          // 初始化CategoryProvider
          Future.delayed(Duration.zero, () {
            Provider.of<CategoryProvider>(
              context,
              listen: false,
            ).initCategories();
          });

          return MaterialApp(
            title: AppConfig.instance.appName, // 使用AppConfig中的应用名称
            theme: AppTheme.getTheme(),
            home: const SplashScreen(),
            debugShowCheckedModeBanner: false,
            builder: EasyLoading.init(),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('zh', 'CN'),
            ],
          );
        },
      ),
    );
  }
}
