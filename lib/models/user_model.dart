/// 用户模型类
class UserModel {
  final String userId;
  final String nickname;
  final String? avatar;
  final String phone;
  final int? expiresIn;

  UserModel({
    required this.userId,
    required this.nickname,
    this.avatar,
    required this.phone,
    this.expiresIn,
  });

  /// 从JSON映射转换为UserModel对象
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'],
      nickname: json['nickname'] ?? '用户',
      avatar: json['avatar'],
      phone: json['phone'],
      expiresIn: json['expiresIn'],
    );
  }

  /// 将UserModel对象转换为JSON映射
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'nickname': nickname,
      'avatar': avatar,
      'phone': phone,
      'expiresIn': expiresIn,
    };
  }

  /// 创建一个新的UserModel实例，可以选择性地更新某些字段
  UserModel copyWith({
    String? userId,
    String? nickname,
    String? avatar,
    String? phone,
    int? expiresIn,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      nickname: nickname ?? this.nickname,
      avatar: avatar ?? this.avatar,
      phone: phone ?? this.phone,
      expiresIn: expiresIn ?? this.expiresIn,
    );
  }
}
