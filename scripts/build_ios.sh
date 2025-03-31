# 配置iOS证书和配置文件
# 1. 在Apple Developer Portal创建应用ID
# 2. 创建开发和分发证书
# 3. 在Xcode中配置签名

# 构建IPA
# 确保Runner scheme设置为Release
flutter build ios --release
cd build/ios/iphoneos
mkdir Payload
cp -R Runner.app Payload
zip -r app.ipa Payload