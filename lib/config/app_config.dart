enum Environment { dev, staging, prod }

class AppConfig {
  final Environment environment;
  final String apiBaseUrl;
  final bool enableLogging;
  final String appName;

  AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.enableLogging,
    required this.appName,
  });

  // 开发环境配置
  factory AppConfig.dev() {
    return AppConfig(
      environment: Environment.dev,
      apiBaseUrl: 'http://192.168.1.15:8080',
      enableLogging: true,
      appName: '好生意记账本(开发版)',
    );
  }

  // 测试环境配置
  factory AppConfig.staging() {
    return AppConfig(
      environment: Environment.staging,
      apiBaseUrl: 'https://api.qianjin.xin/haoshengyi',
      enableLogging: true,
      appName: '好生意记账本(bate)',
    );
  }

  // 生产环境配置
  factory AppConfig.prod() {
    return AppConfig(
      environment: Environment.prod,
      apiBaseUrl: 'https://api.qianjin.xin/haoshengyi',
      enableLogging: false,
      appName: '好生意记账本',
    );
  }

  static late AppConfig _instance;

  static void initialize(Environment env) {
    switch (env) {
      case Environment.dev:
        _instance = AppConfig.dev();
        break;
      case Environment.staging:
        _instance = AppConfig.staging();
        break;
      case Environment.prod:
        _instance = AppConfig.prod();
        break;
    }
    print('当前环境: ${AppConfig.instance.appName}');
    print('API Base URL: ${AppConfig.instance.apiBaseUrl}');
  }

  static AppConfig get instance => _instance;
}
