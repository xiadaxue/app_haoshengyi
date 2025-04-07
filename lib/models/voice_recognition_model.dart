/// 语音识别结果模型类
class VoiceRecognitionModel {
  final String text;
  final ParsedData parsedData;

  VoiceRecognitionModel({
    required this.text,
    required this.parsedData,
  });

  /// 从JSON映射转换为VoiceRecognitionModel对象
  factory VoiceRecognitionModel.fromJson(Map<String, dynamic> json) {
    return VoiceRecognitionModel(
      text: json['text'],
      parsedData: ParsedData.fromJson(json['data']),
    );
  }

  /// 将VoiceRecognitionModel对象转换为JSON映射
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'parsedData': parsedData.toJson(),
    };
  }
}

class ParsedData {
  final String type;
  final double amount;
  final String? category;
  final String? remark; // 替换 description
  final String? transactionDate; // 替换 transactionTime
  final List<String> users; // 默认值为空列表
  final List<Products> products; // 默认值为空列表
  final List<Container> containers; // 默认值为空列表
  final List<String> tags; // 默认值为空列表
  final String? classType;
  final String? settlementStatus;

  ParsedData({
    required this.type,
    required this.amount,
    this.category = '',
    this.remark = '', // 替换 description
    this.transactionDate, // 替换 transactionTime
    this.users = const [], // 设置默认值为空列表
    this.products = const [], // 设置默认值为空列表
    this.containers = const [], // 设置默认值为空列表
    this.tags = const [], // 设置默认值为空列表
    this.classType = '',
    this.settlementStatus = '',
  });

  /// 从JSON映射转换为ParsedData对象
  factory ParsedData.fromJson(Map<String, dynamic> json) {
    return ParsedData(
      type: json['type'] ?? '', // 如果没有 'type' 键，则默认为空字符串
      amount: json['amount'] is int
          ? (json['amount'] as int).toDouble()
          : (json['amount'] ?? 0.0), // 如果没有 'amount' 键，则默认为 0.0
      category: json['category'] ?? '', // 如果没有 'category' 键，则默认为空字符串
      remark: json['remark'] ?? '', // 如果没有 'remark' 键，则默认为空字符串
      transactionDate:
          json['transaction_date'], // 如果没有 'transaction_date' 键，则为 null
      users: json['users'] != null
          ? List<String>.from(json['users'])
          : [], // 如果没有 'users' 键，则默认为空列表
      products: json['products'] != null
          ? (json['products'] as List).map((e) => Products.fromJson(e)).toList()
          : [], // 如果没有 'products' 键，则默认为空列表
      containers: json['containers'] != null
          ? (json['containers'] as List)
              .map((e) => Container.fromJson(e))
              .toList()
          : [], // 如果没有 'containers' 键，则默认为空列表
      tags: json['tags'] != null
          ? List<String>.from(json['tags'])
          : [], // 如果没有 'tags' 键，则默认为空列表
      classType: json['class_type'] ?? '',
      settlementStatus: json['settlement_status'] ?? '',
    );
  }

  /// 将ParsedData对象转换为JSON映射
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'type': type,
      'amount': amount,
    };

    if (category != null) {
      data['category'] = category;
    }

    if (remark != null) {
      data['remark'] = remark;
    }

    if (transactionDate != null) {
      data['transaction_date'] = transactionDate;
    }

    if (users.isNotEmpty) {
      data['users'] = users;
    }

    if (products.isNotEmpty) {
      data['products'] = products.map((e) => e.toJson()).toList();
    }

    if (containers.isNotEmpty) {
      data['containers'] = containers.map((e) => e.toJson()).toList();
    }

    if (tags.isNotEmpty) {
      data['tags'] = tags;
    }

    if (classType != null) {
      data['class_type'] = classType;
    }

    if (settlementStatus != null) {
      data['settlement_status'] = settlementStatus;
    }
    return data;
  }
}

/// 产品模型类
class Products {
  final String name;
  final String quantity;
  final String unit;
  final double unitPrice;

  Products({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
  });

  factory Products.fromJson(Map<String, dynamic> json) {
    return Products(
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 0,
      unit: json['unit'] ?? '',
      unitPrice: json['unit_price'] is int
          ? (json['unit_price'] as int).toDouble()
          : (json['unit_price'] ?? 0.0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'unit_price': unitPrice,
    };
  }
}

/// 容器模型类
class Container {
  final String name;
  final String quantity;

  Container({
    required this.name,
    required this.quantity,
  });

  factory Container.fromJson(Map<String, dynamic> json) {
    return Container(
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
    };
  }
}
