import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'voice_recognition_interface.dart';
import 'default_voice_service.dart';

class VoiceServiceFactory {
  static Future<VoiceRecognitionInterface> createVoiceService() async {
    // 统一返回默认语音服务，不再区分华为设备
    return DefaultVoiceService();
  }

  // 判断是否为华为设备（保留这个方法供其他地方使用）
  static Future<bool> isHuaweiDevice() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      final brand = androidInfo.brand.toLowerCase();
      return brand.contains('huawei') ||
          brand.contains('honor') ||
          brand.contains('华为') ||
          brand.contains('荣耀');
    }
    return false;
  }
}
