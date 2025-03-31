import 'package:haoshengyi_jzzs_app/config/app_config.dart';

/// API常量定义
class ApiConstants {
  // 基础URL - 从AppConfig获取
  static String get baseUrl => AppConfig.instance.apiBaseUrl;

  // API版本
  static const String apiVersion = 'v1';

  // API路径前缀
  static const String apiPrefix = '/api/$apiVersion';

  // 认证相关
  static const String auth = '$apiPrefix/auth';
  static const String register = '$auth/register';
  static const String login = '$auth/login';
  static const String sendVerificationCode = '$auth/sendVerificationCode';

  // 用户信息相关
  static const String user = '$apiPrefix/user';
  static const String userInfo = '$apiPrefix/userInfo';

  // 账单记录相关
  static const String transactions = '$apiPrefix/transactions';
  static const String availableMonths = '$transactions/availableMonths';

  // 语音/文本记账
  static const String accountingVoice = '$apiPrefix/accounting/voice';
  static const String accountingText = '$apiPrefix/accounting/text';
}
