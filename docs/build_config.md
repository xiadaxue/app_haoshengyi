# 构建配置指南

## 环境准备
1. 安装Flutter SDK (版本 3.10.0 或更高)
2. 安装Android Studio 和/或 Xcode
3. 配置Flutter环境变量

## 开发环境构建
```bash
# 启动开发环境
flutter run
```

## 测试环境构建
```bash
# 通过--dart-define指定环境
flutter run --dart-define=ENV=staging
```

## 生产环境构建
```bash
# Android生产版本
flutter build apk --release --dart-define=ENV=prod

# iOS生产版本
flutter build ios --release --dart-define=ENV=prod
```

## 多环境启动脚本
为方便日常开发，可以创建以下启动脚本:

```bash
# dev.sh
flutter run --dart-define=ENV=dev

# staging.sh
flutter run --dart-define=ENV=staging

# prod.sh
flutter run --dart-define=ENV=prod
```
```

## 五、安装指南

创建文件 `docs/installation.md`:

```markdown
# 好生意记账本安装指南

## 系统要求
- Android 5.0 (API级别21) 或更高
- iOS 11.0 或更高
- 最低1GB RAM
- 存储空间100MB以上

## Android安装步骤
1. 下载APK文件 `haoshengyi-vX.X.X.apk`
2. 打开手机设置，允许从未知来源安装应用
3. 点击APK文件开始安装
4. 安装完成后，点击"打开"启动应用

## iOS安装步骤
1. 通过App Store搜索"好生意记账本"并安装
2. 或者通过TestFlight链接进行测试版安装
3. 安装完成后，点击应用图标启动

## 首次使用配置
1. 启动应用后，您需要使用手机号码登录
2. 输入手机号码并获取验证码
3. 输入验证码完成登录
4. 登录后可以设置个人信息和偏好

## 故障排除
- 如果应用无法安装，请检查设备存储空间和系统版本
- 如果无法登录，请确保网络连接正常
- 如果遇到闪退问题，请尝试重启设备或重新安装应用

## 联系支持
- 邮箱: support@haoshengyi.com
- 电话: 400-123-4567
- 官网: https://www.haoshengyi.com
```

以上是基于你的Flutter应用程序提供的测试、部署安装、调试和配置步骤。这些文档和脚本为项目提供了完整的开发和部署流程指南，让团队成员可以更容易地参与项目并保持一致的开发和发布标准。
