import 'dart:convert';
import 'package:haoshengyi_jzzs_app/api/http_client.dart';
import 'package:haoshengyi_jzzs_app/constants/api_constants.dart';
import 'package:haoshengyi_jzzs_app/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:haoshengyi_jzzs_app/constants/app_constants.dart';

/// 认证服务类，处理用户登录、注册等功能
class AuthService {
  final HttpClient _httpClient = HttpClient();

  /// 发送验证码
  Future<bool> sendVerificationCode(String phone) async {
    try {
      await _httpClient.post(
        ApiConstants.sendVerificationCode,
        data: {
          'phone': phone,
        },
      );
      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// 用户注册
  Future<Map<String, dynamic>> register(String phone, String verificationCode,
      {String? nickname}) async {
    try {
      final data = await _httpClient.post(
        ApiConstants.register,
        data: {
          'phone': phone,
          'verificationCode': verificationCode,
          if (nickname != null) 'nickname': nickname,
        },
      );

      // 保存Token和用户信息
      await _saveAuthData(data);

      return data;
    } catch (e) {
      rethrow;
    }
  }

  /// 用户登录
  Future<Map<String, dynamic>> login(
      String phone, String verificationCode) async {
    try {
      final data = await _httpClient.post(
        ApiConstants.login,
        data: {
          'phone': phone,
          'verificationCode': verificationCode,
        },
      );

      // 保存Token和用户信息
      await _saveAuthData(data);

      return data;
    } catch (e) {
      rethrow;
    }
  }

  /// 保存认证数据到本地存储
  Future<void> _saveAuthData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    // 保存Token
    await prefs.setString(AppConstants.tokenKey, data['token']);

    // 保存登录状态
    await prefs.setBool(AppConstants.isLoggedInKey, true);

    // 保存用户信息
    if (data['userInfo'] != null) {
      final userModel = UserModel.fromJson({
        'userId': data['userId'],
        'expiresIn': data['expiresIn'],
        ...data['userInfo'],
      });
      await prefs.setString(
          AppConstants.userInfoKey, jsonEncode(userModel.toJson()));
    }
  }

  /// 退出登录
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userInfoKey);
    await prefs.setBool(AppConstants.isLoggedInKey, false);
  }

  /// 检查用户是否已登录
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.isLoggedInKey) ?? false;
  }

  /// 获取当前登录用户信息
  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userInfoString = prefs.getString(AppConstants.userInfoKey);

    if (userInfoString != null) {
      // 将字符串转换为Map
      try {
        final userInfoMap = jsonDecode(userInfoString) as Map<String, dynamic>;
        return UserModel.fromJson(userInfoMap);
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  /// 获取用户信息
  Future<UserModel> getUserInfo() async {
    try {
      final data = await _httpClient.get(
        ApiConstants.user,
      );
      return UserModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  /// 更新用户信息
  Future<bool> updateUserInfo({String? nickname, String? avatar}) async {
    try {
      final data = await _httpClient.put(
        ApiConstants.userInfo,
        data: {
          if (nickname != null) 'nickname': nickname,
          if (avatar != null) 'avatar': avatar,
        },
      );

      return true;
    } catch (e) {
      print('更新用户信息失败: $e');
      rethrow;
    }
  }
}
