# 好生意记账助手

![App Logo](assets/images/app_icon.png)

## 项目简介

好生意记账助手是一款专为个人和小型企业设计的多功能记账应用，它采用了语音识别技术，让用户可以通过语音命令轻松记录收支明细，大大简化了记账过程。

## 主要功能

- **语音记账**：只需说出交易详情，应用自动识别并记录
- **智能分类**：自动对交易进行分类，便于财务管理
- **数据统计**：直观的图表和报表，帮助用户了解财务状况
- **多平台支持**：支持Android、iOS及网页版
- **数据同步**：在不同设备间安全同步数据
- **自定义分类**：根据个人需求定制收支类别

## 截图

<div style="display: flex; justify-content: space-between;">
  <img src="docs/screenshots/home.png" width="30%" alt="首页截图">
  <img src="docs/screenshots/stats.png" width="30%" alt="统计页面">
  <img src="docs/screenshots/voice.png" width="30%" alt="语音识别">
</div>

## 安装说明

### 前置要求

- Flutter SDK: >=3.3.0 <4.0.0
- Dart SDK: >=3.3.0 <4.0.0
- Android Studio / VS Code

### 安装步骤

1. 克隆项目仓库
```bash
git clone https://github.com/yourusername/haoshengyi-jzzs-app.git
cd haoshengyi-jzzs-app
```

2. 获取依赖
```bash
flutter pub get
```

3. 运行应用
```bash
flutter run
```

## 如何使用

1. **注册/登录**：首次使用需要创建账户或使用社交媒体账号登录
2. **添加交易**：点击首页的"+"按钮或使用语音按钮录入交易
3. **查看统计**：在统计页面查看各类支出收入图表
4. **管理分类**：在设置中可以自定义交易分类

## 技术栈

- Flutter
- Dart
- SQLite (本地数据存储)
- Dio (网络请求)
- Provider (状态管理)
- 语音识别 API

## 贡献指南

欢迎贡献代码，请查看[CONTRIBUTING.md](CONTRIBUTING.md)了解详情。

## 许可证

本项目采用 MIT 许可证，详情见 [LICENSE](LICENSE) 文件。

## 联系方式

- 项目维护者: [您的名字]
- 电子邮件: [您的邮箱]
