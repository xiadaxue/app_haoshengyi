# 生成密钥库
keytool -genkey -v -keystore ~/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key

# 创建密钥配置文件
cat > android/key.properties << EOF
storePassword=<密码>
keyPassword=<密码>
keyAlias=key
storeFile=</Users/username/key.jks>
EOF

# 配置build.gradle
# 编辑 android/app/build.gradle 文件，添加密钥配置

# 构建APK
flutter build apk --release

# 构建应用包 (AAB)
flutter build appbundle --release