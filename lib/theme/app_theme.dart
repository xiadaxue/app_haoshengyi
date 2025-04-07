import 'package:flutter/material.dart';
import 'package:haoshengyi_jzzs_app/constants/app_constants.dart';

/// 应用主题定义
class AppTheme {
  // 主色调
  static const Color primaryColor = Color(0xFF4CAF50);
  static const Color primaryLightColor = Color(0xFF8BC34A);
  static const Color primaryGradientStart = Color(0xFF4CAF50);
  static const Color primaryGradientEnd = Color(0xFF8BC34A);

  // 文本颜色
  static const Color textPrimaryColor = Color(0xFF333333);
  static const Color textSecondaryColor = Color(0xFF666666);
  static const Color textTertiaryColor = Color(0xFF999999);

  // 背景颜色
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color cardBackgroundColor = Color(0xFFFFFFFF);

  // 收支颜色
  static const Color incomeColor = Color(0xFF4CAF50);
  static const Color expenseColor = Color(0xFFF44336);
  static const Color profitColor = Color(0xFF2196F3);
  static const Color creditColor = Color(0xFFFF9800);

  // 分割线颜色
  static const Color dividerColor = Color(0xFFEEEEEE);

  // 获取主题数据
  static ThemeData getTheme() {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: 'PingFang SC',
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        displayMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        displaySmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textPrimaryColor,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textSecondaryColor,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: textTertiaryColor,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 3,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryColor),
        ),
        hintStyle: const TextStyle(
          color: textTertiaryColor,
          fontSize: 16,
        ),
      ),
      cardTheme: CardTheme(
        color: cardBackgroundColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: primaryColor,
        secondary: primaryLightColor,
      ),
    );
  }

  // 渐变背景
  static LinearGradient primaryGradient() {
    return const LinearGradient(
      colors: [primaryGradientStart, primaryGradientEnd],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // 添加交易类型颜色和图标定义
  static const Map<String, Color> transactionTypeColors = {
    'income': Colors.green, // 收入 - 绿色
    'expense': Colors.red, // 支出 - 红色
    'borrow': Color(0xFF4A90E2), // 借入 - 蓝色
    'return': Color(0xFF9C27B0), // 还款 - 紫色
    'settle': Color(0xFF795548), // 结算 - 棕色
  };

  static const Map<String, IconData> transactionTypeIcons = {
    'income': Icons.arrow_downward,
    'expense': Icons.arrow_upward,
    'borrow': Icons.call_received,
    'return': Icons.call_made,
    'settle': Icons.swap_horiz,
  };

  // 获取交易类型颜色
  static Color getTransactionTypeColor(String type) {
    return transactionTypeColors[type] ?? Colors.grey;
  }

  // 获取交易类型图标
  static IconData getTransactionTypeIcon(String type) {
    return transactionTypeIcons[type] ?? Icons.help_outline;
  }

// 获取交易类型标签
  static String getTransactionTypeLabel(String type, String classType) {
    if (classType == AppConstants.assetType) {
      // 资产类型
      if (type == AppConstants.incomeType) {
        return '借出';
      } else if (type == AppConstants.expenseType) {
        return '归还';
      }
    } else if (classType == AppConstants.cashType) {
      // 现金类型
      if (type == AppConstants.incomeType) {
        return '收款';
      } else if (type == AppConstants.expenseType) {
        return '付款';
      }
    }

    // 默认类型标签
    const Map<String, String> typeLabels = {
      'all': '全部',
      'income': '收入',
      'expense': '支出',
      'borrow': '借入',
      'return': '还款',
      'settle': '结算',
    };

    return typeLabels[type] ?? '未知类型';
  }
}
