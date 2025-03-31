import 'package:flutter/material.dart';
import 'package:haoshengyi_jzzs_app/api/auth_service.dart';
import 'package:haoshengyi_jzzs_app/models/user_model.dart';

/// 用户认证状态提供者
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  // 用户是否已登录
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  // 当前用户信息
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  // 登录中状态
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 初始化认证状态
  Future<void> initAuthState() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 检查是否已登录
      _isLoggedIn = await _authService.isLoggedIn();

      if (_isLoggedIn) {
        // 获取当前用户信息
        _currentUser = await _authService.getCurrentUser();
      }
    } catch (e) {
      _isLoggedIn = false;
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 发送验证码
  Future<bool> sendVerificationCode(String phone) async {
    try {
      return await _authService.sendVerificationCode(phone);
    } catch (e) {
      rethrow;
    }
  }

  // 用户注册
  Future<bool> register(String phone, String verificationCode,
      {String? nickname}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.register(phone, verificationCode,
          nickname: nickname);
      _isLoggedIn = true;

      // 获取用户信息
      _currentUser = UserModel.fromJson({
        'userId': result['userId'],
        ...result['userInfo'] ?? {},
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // 用户登录
  Future<bool> login(String phone, String verificationCode) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.login(phone, verificationCode);
      _isLoggedIn = true;

      // 获取用户信息
      _currentUser = UserModel.fromJson({
        'userId': result['userId'],
        ...result['userInfo'] ?? {},
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // 退出登录
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      _isLoggedIn = false;
      _currentUser = null;
    } catch (e) {
      // 即使发生错误，也确保本地状态为登出状态
      _isLoggedIn = false;
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 更新用户信息
  Future<bool> updateUserInfo({String? nickname, String? avatar}) async {
    try {
      // 检查是否已登录
      if (_currentUser == null) {
        throw Exception('用户未登录');
      }
  
      // 调用服务层方法
      final result = await _authService.updateUserInfo(
        nickname: nickname,
        avatar: avatar,
      );
  
      if (result) {
        // 更新本地用户信息
        _currentUser = _currentUser!.copyWith(
          nickname: nickname ?? _currentUser!.nickname,
          avatar: avatar ?? _currentUser!.avatar,
        );
        
        // 保存到本地存储
        //await _saveUserToLocal();
        
        // 通知监听器
        notifyListeners();
        
        return true;
      } else {
        throw Exception('更新用户信息失败');
      }
    } catch (e) {
      print('更新用户信息失败: $e');
      rethrow;
    }
  }
}
