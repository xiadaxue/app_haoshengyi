import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// 将 typedef 移到类外部
typedef VoiceResultCallback = void Function(String text, {bool isFinal});

/// 语言类型枚举
enum XunfeiLanguage {
  /// 中文普通话
  chinese,

  /// 英语
  english,

  /// 粤语
  cantonese,

  /// 四川话
  sichuanese,

  /// 小语种
  other
}

/// 科大讯飞语音听写服务
class XunfeiVoiceService {
  // 科大讯飞API配置
  // 以下参数来自科大讯飞开放平台，如需修改，请按照以下步骤获取:
  //
  // 【科大讯飞API获取/更新步骤】
  // 1. 访问科大讯飞开放平台: https://console.xfyun.cn/ 并登录
  // 2. 在"我的应用"中查看应用详情，或创建新应用
  // 3. 应用平台选择"WebAPI"，应用类型选择"语音听写"
  // 4. 在应用详情页获取以下参数:
  //    - APPID
  //    - APISecret
  //    - APIKey
  //
  // 【常见问题】
  // - 如果遇到403错误，请检查以下几点:
  //   1. APIKey和APISecret是否正确
  //   2. 应用是否已审核通过
  //   3. 是否需要设置IP白名单(特别是生产环境)
  //   4. 免费试用额度是否已用完

  // 科大讯飞API服务地址
  static const String _hostUrl = "iat-api.xfyun.cn"; // 中英文主机名
  static const String _hostUrlNiche = "iat-niche-api.xfyun.cn"; // 小语种主机名

  static const String _appId = "db7eb000"; // 您的APPID
  static const String _apiKey = "5ca7358fec5fe25f149365dcbce3cdbb"; // 您的APIKey
  static const String _apiSecret =
      "M2EwODEyOTQyMTc3NzcyNDcwOWQ4OTFi"; // 您的APISecret

  // WebSocket连接
  IOWebSocketChannel? _channel;
  bool _isConnected = false;
  bool _isRecording = false;

  // 录音相关
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  StreamSubscription? _recorderSubscription;

  // 回调函数
  final VoiceResultCallback onResult;
  final Function() onError;
  final Function() onFinish;

  // 错误状态
  bool _hasError = false;
  String _errorMessage = "";

  // 语言配置
  XunfeiLanguage _language = XunfeiLanguage.chinese;
  String _languageCode = "zh_cn";
  String _accent = "mandarin";
  bool _enableDynamicCorrection = true;

  // 创建音频数据流控制器
  final _audioStreamController = StreamController<Uint8List>();

  // 修改成员变量
  final List<String> _recognizedParts = []; // 存储所有有效的识别片段
  final Set<String> _addedParts = {}; // 用于跟踪已添加的片段，避免重复
  String _lastCompleteResult = '';
  String _currentSegment = '';
  bool _hasStartedNewSegment = false; // 标记是否开始了新的片段

  XunfeiVoiceService({
    required this.onResult,
    required this.onError,
    required this.onFinish,
    XunfeiLanguage language = XunfeiLanguage.chinese,
  }) {
    setLanguage(language);
  }

  /// 设置识别语言
  void setLanguage(XunfeiLanguage language) {
    _language = language;

    switch (language) {
      case XunfeiLanguage.chinese:
        _languageCode = "zh_cn";
        _accent = "mandarin";
        break;
      case XunfeiLanguage.english:
        _languageCode = "en_us";
        _accent = "";
        break;
      case XunfeiLanguage.cantonese:
        _languageCode = "zh_cn";
        _accent = "cantonese";
        break;
      case XunfeiLanguage.sichuanese:
        _languageCode = "zh_cn";
        _accent = "lmz";
        break;
      case XunfeiLanguage.other:
        // 小语种需要单独设置
        _languageCode = "zh_cn"; // 默认值，应该由调用者手动设置
        _accent = "";
        break;
    }
  }

  /// 手动设置语言代码（适用于小语种）
  void setLanguageCode(String code) {
    _languageCode = code;
  }

  /// 设置是否启用动态修正（仅中文支持）
  void setDynamicCorrection(bool enable) {
    _enableDynamicCorrection = enable;
  }

  /// 初始化服务
  Future<bool> initialize() async {
    try {
      print('初始化科大讯飞语音服务 - AppID: $_appId');

      // 检查API参数
      if (_appId.isEmpty || _apiKey.isEmpty || _apiSecret.isEmpty) {
        _errorMessage = "科大讯飞API参数无效，参数不能为空";
        _hasError = true;
        print('错误: $_errorMessage');
        onError();
        return false;
      }

      // 打印API密钥前几位字符，方便调试但不泄露完整密钥
      print('API密钥信息检查:');
      print('- AppID: ${_appId.substring(0, 4)}****');
      print('- APIKey: ${_apiKey.substring(0, 6)}****');
      print('- APISecret: ${_apiSecret.substring(0, 6)}****');

      // 检查麦克风权限
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        _errorMessage = "麦克风权限未授予";
        _hasError = true;
        print('错误: $_errorMessage');
        onError();
        return false;
      }

      // 初始化录音器
      await _recorder.openRecorder();
      print('录音器初始化成功');

      // 在初始化方法中添加
      await _recorder.startRecorder(
        toStream: _audioStreamController.sink,
        codec: Codec.pcm16,
        sampleRate: 16000,
        numChannels: 1,
      );

      // 监听流中的数据
      _audioStreamController.stream.listen((buffer) {
        _sendAudioBuffer(buffer);
      });

      return true;
    } catch (e) {
      print('初始化语音服务失败: $e');
      _errorMessage = e.toString();
      _hasError = true;
      onError();
      return false;
    }
  }

  /// 创建WebSocket连接
  Future<IOWebSocketChannel?> _createWebSocketConnection() async {
    try {
      // 1. 获取RFC1123格式的GMT时间（科大讯飞API要求的格式）
      final now = DateTime.now().toUtc();
      final String formattedDate = _formatRFC1123Date(now);

      print('当前UTC时间: $now');
      print('格式化的日期头: $formattedDate');

      // 根据语言类型选择不同的主机地址
      final String hostUrl = _isNicheLanguage() ? _hostUrlNiche : _hostUrl;
      print('使用主机地址: $hostUrl');

      // 2. 生成签名原始字符串，确保使用正确的日期格式
      final String signatureOrigin = 'host: $hostUrl\n'
          'date: $formattedDate\n'
          'GET /v2/iat HTTP/1.1';

      print('签名原始字符串: $signatureOrigin');

      // 3. 使用HMAC-SHA256加密
      final secretBytes = utf8.encode(_apiSecret);
      final signatureBytes = utf8.encode(signatureOrigin);
      final Hmac hmacSha256 = Hmac(sha256, secretBytes);
      final Digest signatureDigest = hmacSha256.convert(signatureBytes);
      final String signatureBase64 = base64.encode(signatureDigest.bytes);

      print('签名结果: $signatureBase64');

      // 4. 构造authorization字段
      final String authOrigin = 'api_key="$_apiKey", algorithm="hmac-sha256", '
          'headers="host date request-line", signature="$signatureBase64"';
      final String authorization = base64.encode(utf8.encode(authOrigin));

      // 5. 直接使用WebSocket.connect方法
      final wsUrl = 'wss://$hostUrl/v2/iat'
          '?authorization=${Uri.encodeComponent(authorization)}'
          '&date=${Uri.encodeComponent(formattedDate)}'
          '&host=${Uri.encodeComponent(hostUrl)}';

      print('使用WebSocket连接: $wsUrl');

      // 添加特定的头信息
      final headers = {
        'Host': hostUrl,
        'Date': formattedDate,
        'User-Agent': 'Dart/2.19 (dart:io)',
        'Origin': 'https://$hostUrl',
      };

      // 创建WebSocket连接
      final ws = await WebSocket.connect(wsUrl, headers: headers);

      print('WebSocket连接成功！');

      // 包装为IOWebSocketChannel
      final channel = IOWebSocketChannel(ws);
      return channel;
    } catch (e) {
      print('WebSocket连接失败: $e');
      _errorMessage = '连接失败: $e';
      _hasError = true;
      return null;
    }
  }

  /// 判断是否为小语种
  bool _isNicheLanguage() {
    // 根据文档，以下语言使用小语种主机地址
    final nicheLanguages = [
      'uy_xj', // 维语
      'ct_cn', // 藏语
      'ja_jp', // 日语等其他小语种
      'ko_kr', // 韩语
      'ru-ru', // 俄语
      'fr_fr', // 法语
      'de_de', // 德语
      'es_es', // 西班牙语
      'it_it', // 意大利语
      'tr_tr', // 土耳其语
      'pt_pt', // 葡萄牙语
      'vi_vn', // 越南语
      'id_id', // 印尼语
      'ms_my', // 马来语
      'ar_ae', // 阿拉伯语
      'th_th', // 泰语
      'hi_in', // 印地语
    ];

    return nicheLanguages.contains(_languageCode);
  }

  /// 连接WebSocket
  Future<bool> connect() async {
    try {
      if (_isConnected) {
        return true;
      }

      // 创建WebSocket连接
      final channel = await _createWebSocketConnection();
      if (channel == null) {
        _errorMessage = "无法创建WebSocket连接";
        _hasError = true;
        return false;
      }

      _channel = channel;

      // 设置业务参数
      final Map<String, dynamic> businessParams = {
        "language": _languageCode,
        "domain": "iat",
        "vad_eos": 3000,
        "speex_size": 1280
      };

      // 添加方言参数（如果有）
      if (_accent.isNotEmpty) {
        businessParams["accent"] = _accent;
      }

      // 添加动态修正（仅中文支持）
      if (_languageCode == "zh_cn" && _enableDynamicCorrection) {
        businessParams["dwa"] = "wpgs";
      }

      // 发送会话参数
      final params = {
        "common": {"app_id": _appId},
        "business": businessParams,
        "data": {
          "status": 0, // 会话状态，0-开始，1-继续，2-结束
          "format": "audio/L16;rate=16000", // 音频格式
          "encoding": "raw", // 音频编码
          "audio": "", // 音频数据
        },
      };

      _channel!.sink.add(jsonEncode(params));

      // 监听WebSocket消息
      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          print('WebSocket错误: $error');
          _parseWebSocketError(error);
          _isConnected = false;
          onError();
        },
        onDone: () {
          _isConnected = false;
        },
      );

      _isConnected = true;
      return true;
    } catch (e) {
      print('连接WebSocket失败: $e');
      _isConnected = false;
      onError();
      return false;
    }
  }

  /// 解析WebSocket错误
  void _parseWebSocketError(dynamic error) {
    String errorStr = error.toString();

    if (errorStr.contains('403')) {
      _errorMessage = "授权失败(403)：可能是API密钥无效、签名算法错误或权限问题";
    } else if (errorStr.contains('400')) {
      _errorMessage = "请求参数错误(400)：请检查业务参数";
    } else if (errorStr.contains('500')) {
      _errorMessage = "服务器内部错误(500)：请稍后重试";
    } else if (errorStr.contains('10105')) {
      _errorMessage = "应用未创建或审核未通过，请检查应用状态";
    } else if (errorStr.contains('10107')) {
      _errorMessage = "应用被禁用，请在控制台检查应用状态";
    } else if (errorStr.contains('10110')) {
      _errorMessage = "应用IP不在白名单中，请在控制台添加IP白名单";
    } else if (errorStr.contains('10201')) {
      _errorMessage = "WebAPI验证失败，请检查签名参数";
    } else {
      _errorMessage = "连接错误: $errorStr";
    }

    _hasError = true;
  }

  /// 处理WebSocket消息
  void _handleMessage(dynamic message) {
    try {
      final Map<String, dynamic> data = jsonDecode(message);

      // 检查是否有错误码
      if (data.containsKey('code') && data['code'] != 0) {
        final int code = data['code'];
        final String msg = data['message'] ?? '未知错误';
        print('科大讯飞API返回错误码: $code, 错误信息: $msg');
        _errorMessage = "API错误[$code]: $msg";
        _hasError = true;
        onError();
        return;
      }

      if (data.containsKey('data') && data['data'].containsKey('result')) {
        final result = data['data']['result'];
        final bool isFinal = data['data']['status'] == 2;

        // 解析当前文本
        String currentText = _extractText(result);
        print('原始识别文本: $currentText');

        // 处理有意义的文本
        if (currentText.isNotEmpty &&
            !RegExp(r'^[，。？！、：；""（）【】《》]+$').hasMatch(currentText)) {
          // 检测是否是新片段的开始 (长度突然变短且内容变化较大)
          if (_currentSegment.isNotEmpty &&
              currentText.length < _currentSegment.length * 0.5 &&
              !_currentSegment.contains(currentText)) {
            if (_currentSegment.length > 5 &&
                !_addedParts.contains(_currentSegment)) {
              _recognizedParts.add(_currentSegment);
              _addedParts.add(_currentSegment); // 记录已添加的片段
              print('添加片段: $_currentSegment');
            }
            _hasStartedNewSegment = true;
          }

          _currentSegment = currentText;

          // 构建完整结果
          String fullResult = _buildFullResult();

          // 保存最后的完整结果
          if (fullResult.length > 5) {
            _lastCompleteResult = fullResult;
          }

          // 回调当前结果
          print('当前完整识别结果: $fullResult (isFinal: $isFinal)');
          onResult(fullResult, isFinal: false);
        }

        // 处理最终结果
        if (isFinal) {
          // 如果当前有效片段不为空，添加到已识别部分
          if (_currentSegment.length > 5 &&
              !_recognizedParts.contains(_currentSegment)) {
            _recognizedParts.add(_currentSegment);
          }

          // 构建最终完整结果
          String finalResult = _buildFullResult();
          if (finalResult.isEmpty && _lastCompleteResult.isNotEmpty) {
            finalResult = _lastCompleteResult;
          }

          if (finalResult.isNotEmpty) {
            print('最终识别结果: $finalResult (isFinal: true)');
            onResult(finalResult, isFinal: true);
          }
          onFinish();
          closeConnection();
        }
      }
    } catch (e) {
      print('解析消息失败: $e');
    }
  }

  /// 提取文本内容 - 简化处理逻辑
  String _extractText(Map<String, dynamic> result) {
    String text = '';
    if (result.containsKey('ws')) {
      final List ws = result['ws'];
      for (var w in ws) {
        if (w.containsKey('cw')) {
          final List cw = w['cw'];
          if (cw.isNotEmpty && cw[0].containsKey('w')) {
            text += cw[0]['w'];
          }
        }
      }
    }
    return text;
  }

  /// 构建完整的识别结果 - 修改方法防止重复
  String _buildFullResult() {
    // 如果没有任何片段，直接返回当前片段
    if (_recognizedParts.isEmpty) {
      return _currentSegment;
    }

    // 如果当前片段是最后一个已识别片段的重复或子串，只使用已识别片段
    String lastRecognizedPart = _recognizedParts.last;
    if (_currentSegment.isEmpty ||
        lastRecognizedPart.contains(_currentSegment) ||
        _currentSegment == lastRecognizedPart) {
      return _recognizedParts.join("");
    }

    // 正常情况：合并所有片段和当前片段
    return _recognizedParts.join("") + _currentSegment;
  }

  /// 开始录音并发送音频数据
  Future<bool> startRecording() async {
    // 重置所有状态变量
    _recognizedParts.clear();
    _addedParts.clear(); // 清空已添加记录
    _lastCompleteResult = '';
    _currentSegment = '';
    _hasStartedNewSegment = false;
    try {
      // 先尝试连接WebSocket
      if (!_isConnected) {
        final connected = await connect();
        if (!connected) {
          print('无法连接到讯飞语音服务');
          onError();
          return false;
        }
      }

      // 开始录音
      await _recorder.startRecorder(
        toStream: _audioStreamController.sink,
        codec: Codec.pcm16,
        sampleRate: 16000,
        numChannels: 1,
      );

      _isRecording = true;
      return true;
    } catch (e) {
      print('开始录音失败: $e');
      onError();
      return false;
    }
  }

  /// 停止录音
  Future<void> stopRecording() async {
    try {
      if (!_isRecording) return;
      print('停止录音并结束会话');

      // 如果当前有效片段不为空，添加到已识别部分
      if (_currentSegment.length > 5 &&
          !_addedParts.contains(_currentSegment)) {
        _recognizedParts.add(_currentSegment);
        _addedParts.add(_currentSegment); // 记录已添加的片段
      }

      // 构建最终完整结果
      String finalResult = _buildFullResult();
      if (finalResult.isEmpty && _lastCompleteResult.isNotEmpty) {
        finalResult = _lastCompleteResult;
      }

      // 确保使用最完整的结果
      if (finalResult.isNotEmpty) {
        print('停止录音时使用最终结果: $finalResult');
        onResult(finalResult, isFinal: true);
      }

      // 停止录音
      await _recorder.stopRecorder();

      // 取消进度订阅
      if (_recorderSubscription != null) {
        await _recorderSubscription!.cancel();
        _recorderSubscription = null;
      }

      // 发送会话结束信号
      if (_isConnected && _channel != null) {
        print('发送会话结束信号');
        final params = {
          "data": {
            "status": 2, // 2-结束
            "format": "audio/L16;rate=16000",
            "encoding": "raw",
            "audio": "",
          },
        };

        _channel!.sink.add(jsonEncode(params));
        // 等待服务器处理完成
        await Future.delayed(const Duration(milliseconds: 500));
      }

      _isRecording = false;
    } catch (e) {
      print('停止录音失败: $e');
    } finally {
      _isRecording = false;
    }
  }

  /// 关闭连接
  Future<void> dispose() async {
    try {
      // 停止录音
      if (_isRecording) {
        await stopRecording();
      }

      // 关闭WebSocket
      if (_channel != null) {
        await _channel!.sink.close(1000, '客户端主动关闭');
        _channel = null;
      }

      // 关闭录音器
      if (_recorder.isRecording) {
        await _recorder.stopRecorder();
      }
      await _recorder.closeRecorder();

      // 重置状态
      _isConnected = false;
      _isRecording = false;
    } catch (e) {
      print('释放语音服务资源失败: $e');
    }
  }

  /// 获取最后的错误信息
  String getErrorMessage() {
    return _hasError ? _errorMessage : "未知错误";
  }

  /// 重置错误状态
  void resetError() {
    _hasError = false;
    _errorMessage = "";
  }

  /// 检查API密钥是否为默认值
  bool isUsingDefaultApiKey() {
    return _appId == "db7eb000" &&
        _apiKey == "5ca7358fec5fe25f149365dcbce3cdbb" &&
        _apiSecret == "M2EwODEyOTQyMTc3NzcyNDcwOWQ4OTFi";
  }

  /// 获取API错误描述
  String getApiKeyStatus() {
    if (isUsingDefaultApiKey()) {
      return "您正在使用演示API密钥，如果遇到403错误，请在控制台创建并使用自己的密钥";
    }
    return "API密钥已设置，如果遇到403错误，请检查密钥是否正确";
  }

  /// 格式化RFC1123日期
  String _formatRFC1123Date(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = _getMonthName(dateTime.month);
    final year = dateTime.year.toString();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    final dayOfWeek = _getDayOfWeek(dateTime.weekday);

    return '$dayOfWeek, $day $month $year $hour:$minute:$second GMT';
  }

  /// 获取月份名
  String _getMonthName(int month) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  /// 获取星期几
  String _getDayOfWeek(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        throw Exception('Invalid weekday');
    }
  }

  /// 创建发送音频缓冲区的方法
  void _sendAudioBuffer(Uint8List buffer) {
    if (!_isConnected || buffer.isEmpty) return;

    final params = {
      "data": {
        "status": 1, // 1-继续
        "format": "audio/L16;rate=16000",
        "encoding": "raw",
        "audio": base64.encode(buffer),
      },
    };

    if (_channel != null) {
      _channel!.sink.add(jsonEncode(params));
    }
  }

  /// 关闭WebSocket连接
  Future<void> closeConnection() async {
    if (_channel != null) {
      await _channel!.sink.close(1000, '会话结束');
      _channel = null;
      _isConnected = false;
      print('WebSocket连接已关闭');
    }
  }
}
