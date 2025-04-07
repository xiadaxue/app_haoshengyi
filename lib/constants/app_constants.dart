/// 应用常量定义
class AppConstants {
  // 应用名称
  static const String appName = '好生意记账本';

  // 应用标语
  static const String appSlogan = '用说的方式记账，更轻松！';

  // 本地存储键
  static const String tokenKey = 'token';
  static const String userInfoKey = 'user_info';
  static const String isLoggedInKey = 'is_logged_in';

  // 交易类型
  static const String incomeType = 'income';
  static const String expenseType = 'expense';
  static const String borrowType = 'borrow';
  static const String returnType = 'return';
  static const String settleType = 'settle';

  // 交易分类类型
  static const String cashType = 'cash';
  static const String assetType = 'asset';

  // 结算状态
  static const String settledStatus = 'settled';
  static const String unsettledStatus = 'unsettled';

  // 底部导航栏索引
  static const int homeIndex = 0;
  static const int transactionsIndex = 1;
  static const int statsIndex = 2;
  static const int profileIndex = 3;
}
