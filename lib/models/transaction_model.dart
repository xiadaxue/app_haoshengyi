import 'package:haoshengyi_jzzs_app/models/voice_recognition_model.dart';

/// 交易记录模型类
class TransactionModel {
  final String? transactionId;
  final String type;
  final double amount;
  final String category;
  final String remark; // 替换 description
  final String transactionDate; // 替换 transactionTime
  final List<String>? tags;
  final List<String>? users; // 新增字段
  final List<ProductsModel>? products; // 新增字段
  final List<ContainerModel>? containers; // 修改为ContainerModel
  final String? createdAt;
  final String? updatedAt;
  final bool? isDeleted;
  final String? status; // 添加状态字段，可以是 'returned', 'pending' 等

  TransactionModel({
    this.transactionId,
    required this.type,
    required this.amount,
    required this.category,
    required this.remark, // 替换 description
    required this.transactionDate, // 替换 transactionTime
    this.users = const [], // 新增字段
    this.products = const [], // 新增字段
    this.containers = const [], // 新增字段
    this.tags = const [], // 新增字段
    this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
    this.status,
  });

  /// 从JSON映射转换为TransactionModel对象
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      transactionId: json['transactionId'],
      type: json['type'],
      amount:
          (json['amount'] is int)
              ? (json['amount'] as int).toDouble()
              : (json['amount'] ?? 0.0),
      transactionDate: json['transaction_date'],
      remark: json['remark'],
      users: List<String>.from(json['users']),
      products:
          (json['products'] as List)
              .map((e) => ProductsModel.fromJson(e))
              .toList(),
      containers:
          (json['containers'] as List)
              .map((e) => ContainerModel.fromJson(e))
              .toList(),
      category: json['category'],
      tags: List<String>.from(json['tags']),
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  /// 将TransactionModel对象转换为JSON映射
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'type': type,
      'amount': amount,
      'category': category,
      'remark': remark,
      'transaction_date': transactionDate,
    };

    if (transactionId != null) {
      data['transactionId'] = transactionId;
    }

    if (tags != null && tags!.isNotEmpty) {
      data['tags'] = tags;
    }

    if (users != null && users!.isNotEmpty) {
      data['users'] = users;
    }

    if (products != null && products!.isNotEmpty) {
      data['products'] = products!.map((e) => e.toJson()).toList();
    }

    if (containers != null && containers!.isNotEmpty) {
      data['containers'] = containers!.map((e) => e.toJson()).toList();
    }

    if (createdAt != null) {
      data['createdAt'] = createdAt;
    }

    if (updatedAt != null) {
      data['updatedAt'] = updatedAt;
    }

    if (isDeleted != null) {
      data['isDeleted'] = isDeleted;
    }

    return data;
  }

  /// 创建 TransactionModel 的拷贝，并可选择性修改部分属性
  TransactionModel copyWith({
    String? transactionId,
    String? type,
    double? amount,
    String? category,
    String? remark,
    String? transactionDate,
    List<String>? tags,
    List<String>? users,
    List<ProductsModel>? products,
    List<ContainerModel>? containers,
    String? createdAt,
    String? updatedAt,
    bool? isDeleted,
  }) {
    return TransactionModel(
      transactionId: transactionId ?? this.transactionId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      remark: remark ?? this.remark,
      transactionDate: transactionDate ?? this.transactionDate,
      tags: tags ?? this.tags,
      users: users ?? this.users,
      products: products ?? this.products,
      containers: containers ?? this.containers,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

/// 产品模型类
class ProductsModel {
  final String name;
  final String quantity;
  final String unit;
  final double unitPrice;

  ProductsModel({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
  });

  factory ProductsModel.fromJson(Map<String, dynamic> json) {
    return ProductsModel(
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 0,
      unit: json['unit'] ?? '',
      unitPrice:
          json['unit_price'] is int
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
class ContainerModel {
  final String name;
  final String quantity;

  ContainerModel({required this.name, required this.quantity});

  factory ContainerModel.fromJson(Map<String, dynamic> json) {
    return ContainerModel(
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'quantity': quantity};
  }
}
