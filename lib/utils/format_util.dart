import 'package:intl/intl.dart';
import 'package:haoshengyi_jzzs_app/services/timezone_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

/// 格式化工具类
class FormatUtil {
  /// 获取时区服务实例
  static TimezoneService? _getTimezoneService(BuildContext? context) {
    if (context == null) return null;
    return Provider.of<TimezoneService>(context, listen: false);
  }

  /// 格式化金额，保留两位小数，如 "¥12.34"
  static String formatCurrency(double amount) {
    final numberFormat = NumberFormat.currency(
      locale: 'zh_CN',
      symbol: '¥',
      decimalDigits: 2,
    );
    return numberFormat.format(amount);
  }

  /// 格式化日期，如 "2023-06-15"
  static String formatDate(DateTime date, {BuildContext? context}) {
    // 使用时区服务转换时间
    final timezoneService = _getTimezoneService(context);
    final localDate = timezoneService != null
        ? timezoneService.convertToLocalTime(date)
        : date.toLocal();

    return DateFormat('yyyy-MM-dd').format(localDate);
  }

  /// 格式化日期时间，如 "2023-06-15 14:30:00"
  static String formatDateTime(DateTime dateTime, {BuildContext? context}) {
    final timezoneService = _getTimezoneService(context);
    final localDateTime = timezoneService != null
        ? timezoneService.convertToLocalTime(dateTime)
        : dateTime.toLocal();

    return DateFormat('yyyy-MM-dd HH:mm:ss').format(localDateTime);
  }

  /// 格式化日期时间，支持自定义格式，如 "MM月dd日 HH:mm"
  static String formatDateTimeWithFormat(DateTime dateTime,
      {String format = 'yyyy-MM-dd HH:mm:ss'}) {
    return DateFormat(format).format(dateTime);
  }

  /// 格式化日期，返回人性化的表示，如 "今天"、"昨天"、"2023年6月15日"
  static String formatDateFriendly(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return '今天';
    } else if (dateOnly == yesterday) {
      return '昨天';
    } else {
      return DateFormat('yyyy年M月d日').format(date);
    }
  }

  /// 格式化时间，如 "14:30"
  static String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  /// 解析ISO8601格式的日期时间字符串为DateTime对象
  static DateTime? parseDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) {
      return null;
    }

    try {
      return DateTime.parse(dateTimeString);
    } catch (e) {
      return null;
    }
  }

  /// 将字符串解析为日期
  static DateTime? parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return null;
    }

    try {
      return DateFormat('yyyy-MM-dd').parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// 格式化当前月份为 "2023年04月" 格式
  static String formatCurrentMonth() {
    final now = DateTime.now();
    return '${now.year}年${now.month.toString().padLeft(2, '0')}月';
  }

  /// 将金额字符串解析为double
  static double? parseCurrency(String? amountString) {
    if (amountString == null || amountString.isEmpty) {
      return null;
    }

    // 移除货币符号和千分位分隔符
    final cleanString = amountString
        .replaceAll('¥', '')
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .trim();

    try {
      return double.parse(cleanString);
    } catch (e) {
      return null;
    }
  }
}
