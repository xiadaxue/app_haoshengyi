import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 时区服务类，用于全局管理时区设置
class TimezoneService extends ChangeNotifier {
  static const String _timeZoneKey = 'app_timezone';
  
  String _currentTimezone = '';
  bool _useDeviceTimezone = true;
  
  String get currentTimezone => _currentTimezone;
  bool get useDeviceTimezone => _useDeviceTimezone;
  
  /// 初始化时区服务
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _currentTimezone = prefs.getString(_timeZoneKey) ?? '';
    _useDeviceTimezone = _currentTimezone.isEmpty;
    
    // 如果没有保存的时区或设置为使用设备时区，则获取设备时区
    if (_useDeviceTimezone) {
      _currentTimezone = DateTime.now().timeZoneName;
    }
    
    notifyListeners();
  }
  
  /// 设置使用设备时区
  Future<void> useDeviceTimeZone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_timeZoneKey, '');
    
    _currentTimezone = DateTime.now().timeZoneName;
    _useDeviceTimezone = true;
    
    notifyListeners();
  }
  
  /// 设置自定义时区
  Future<void> setCustomTimezone(String timezone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_timeZoneKey, timezone);
    
    _currentTimezone = timezone;
    _useDeviceTimezone = false;
    
    notifyListeners();
  }
  
  /// 获取当前时区的DateTime
  DateTime getNow() {
    return DateTime.now().toLocal();
  }
  
  /// 将UTC时间转换为当前时区时间
  DateTime convertToLocalTime(DateTime utcTime) {
    return utcTime.toLocal();
  }
  
  /// 将本地时间转换为UTC时间
  DateTime convertToUtcTime(DateTime localTime) {
    return localTime.toUtc();
  }
}