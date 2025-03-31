import 'package:dio/dio.dart';
import 'package:haoshengyi_jzzs_app/constants/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:haoshengyi_jzzs_app/constants/app_constants.dart';
import 'package:haoshengyi_jzzs_app/config/app_config.dart';

/// HTTP客户端类
class HttpClient {
  static final HttpClient _instance = HttpClient._internal();
  late Dio _dio;

  factory HttpClient() {
    return _instance;
  }

  HttpClient._internal() {
    _initDio();
  }

  // 初始化Dio实例
  void _initDio() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // 添加拦截器
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 确保每次请求都使用最新的baseUrl
        options.baseUrl = ApiConstants.baseUrl;
        
        // 获取本地存储的Token并添加到请求头
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? token = prefs.getString(AppConstants.tokenKey);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        
        // 添加日志
        if (AppConfig.instance.enableLogging) {
          print('请求: ${options.method} ${options.baseUrl}${options.path}');
          print('参数: ${options.queryParameters}');
          print('数据: ${options.data}');
        }
        
        return handler.next(options);
      },
      onResponse: (response, handler) {
        // 统一处理响应
        if (response.data is Map && response.data['code'] != null) {
          if (response.data['code'] == 200) {
            // 成功响应，提取data部分
            response.data = response.data['data'];
          } else {
            // 业务错误，抛出异常
            throw DioException(
              requestOptions: response.requestOptions,
              response: response,
              error: response.data['message'] ?? '未知错误',
              type: DioExceptionType.badResponse,
            );
          }
        }
        return handler.next(response);
      },
      onError: (error, handler) {
        // 统一处理错误
        return handler.next(error);
      },
    ));
  }

  /// GET请求
  Future<dynamic> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response.data;
    } catch (e) {
      _handleError(e);
    }
  }

  /// POST请求
  Future<dynamic> post(String path, {dynamic data}) async {
    try {
      final response = await _dio.post(path, data: data);
      return response.data;
    } catch (e) {
      _handleError(e);
    }
  }

  /// PUT请求
  Future<dynamic> put(String path, {dynamic data}) async {
    try {
      final response = await _dio.put(path, data: data);
      return response.data;
    } catch (e) {
      _handleError(e);
    }
  }

  /// DELETE请求
  Future<dynamic> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return response.data;
    } catch (e) {
      _handleError(e);
    }
  }

  /// 上传文件
  Future<dynamic> uploadFile(String path, String filePath,
      {String method = 'POST'}) async {
    try {
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(filePath),
      });

      final response = method.toUpperCase() == 'POST'
          ? await _dio.post(path, data: formData)
          : await _dio.put(path, data: formData);

      return response.data;
    } catch (e) {
      _handleError(e);
    }
  }

  /// 错误处理
  void _handleError(dynamic error) {
    if (error is DioException) {
      // 网络错误处理
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          throw '网络连接超时，请检查网络设置';
        case DioExceptionType.badResponse:
          if (error.response?.statusCode == 401) {
            // Token失效，需要重新登录
            throw '登录已过期，请重新登录';
          } else {
            // 其他HTTP错误
            final message = error.response?.data?['message'] ?? '服务器错误';
            throw message;
          }
        case DioExceptionType.cancel:
          throw '请求被取消';
        case DioExceptionType.unknown:
          final message = error.response?.data?['message'] ?? '服务器错误';
          throw message;
        default:
          throw '网络错误，请稍后重试';
      }
    } else {
      // 其他错误
      throw error.toString();
    }
  }
}
