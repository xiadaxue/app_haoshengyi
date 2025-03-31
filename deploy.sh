#!/bin/bash
set -e

# 确保环境变量
if [ -z "$BUILD_TYPE" ]; then
  echo "请设置 BUILD_TYPE (android/ios)"
  exit 1
fi

# 清理前一次构建
flutter clean

# 获取依赖
flutter pub get

# 运行测试
flutter test

# 构建应用
if [ "$BUILD_TYPE" = "android" ]; then
  echo "构建Android应用..."
  flutter build apk --release
  flutter build appbundle --release
  mkdir -p release
  cp build/app/outputs/flutter-apk/app-release.apk release/
  cp build/app/outputs/bundle/release/app-release.aab release/
  echo "Android应用已构建完成，位于release目录"
elif [ "$BUILD_TYPE" = "ios" ]; then
  echo "构建iOS应用..."
  flutter build ios --release --no-codesign
  echo "iOS应用已构建完成，请使用Xcode进行打包"
else
  echo "不支持的构建类型: $BUILD_TYPE"
  exit 1
fi
