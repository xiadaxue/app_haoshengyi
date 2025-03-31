import 'package:flutter/material.dart';

/// 交易分类模型类
class CategoryModel {
  final String id;
  final String name;
  final String type;
  final IconData icon;  // 保持原定义
  final Color color;
  final bool isDefault;

  const CategoryModel({  // 添加const构造函数
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    this.isDefault = false,
  });

  /// 从JSON映射转换为CategoryModel对象
  static const Map<String, IconData> _iconMap = {
    'restaurant': Icons.restaurant,
    'shopping_bag': Icons.shopping_bag,
    'directions_car': Icons.directions_car,
    'home': Icons.home,
    'movie': Icons.movie,
    'local_hospital': Icons.local_hospital,
    'account_balance_wallet': Icons.account_balance_wallet,
    'card_giftcard': Icons.card_giftcard,
    'trending_up': Icons.trending_up,
    'store': Icons.store,
    'more_horiz': Icons.more_horiz,
  };

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      icon: _iconMap[json['iconName']] ?? Icons.help_outline, // 使用映射获取常量图标
      color: Color(json['colorValue']),
      isDefault: json['isDefault'] ?? false,
    );
  }

  /// 将CategoryModel对象转换为JSON映射
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'iconFontPackage': icon.fontPackage,
      'colorValue': color.value,
      'isDefault': isDefault,
    };
  }

  /// 创建CategoryModel的拷贝，并可选择性修改部分属性
  CategoryModel copyWith({
    String? id,
    String? name,
    String? type,
    IconData? icon,
    Color? color,
    bool? isDefault,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

/// 默认类别数据
class DefaultCategories {
  // 支出类别
  static List<CategoryModel> expenseCategories = const [
    CategoryModel(
      id: 'food',
      name: '餐饮',
      type: 'expense',
      icon: Icons.restaurant,  // MaterialIcons是预定义的常量
      color: Colors.orange,
      isDefault: true,
    ),
    CategoryModel(
      id: 'shopping',
      name: '购物',
      type: 'expense',
      icon: Icons.shopping_bag,
      color: Colors.pink,
      isDefault: true,
    ),
    CategoryModel(
      id: 'transport',
      name: '交通',
      type: 'expense',
      icon: Icons.directions_car,
      color: Colors.blue,
      isDefault: true,
    ),
    CategoryModel(
      id: 'housing',
      name: '住房',
      type: 'expense',
      icon: Icons.home,
      color: Colors.brown,
      isDefault: true,
    ),
    CategoryModel(
      id: 'entertainment',
      name: '娱乐',
      type: 'expense',
      icon: Icons.movie,
      color: Colors.purple,
      isDefault: true,
    ),
    CategoryModel(
      id: 'medical',
      name: '医疗',
      type: 'expense',
      icon: Icons.local_hospital,
      color: Colors.red,
      isDefault: true,
    ),
    CategoryModel(
      id: 'education',
      name: '教育',
      type: 'expense',
      icon: Icons.school,
      color: Colors.teal,
      isDefault: true,
    ),
    CategoryModel(
      id: 'other_expense',
      name: '其他支出',
      type: 'expense',
      icon: Icons.more_horiz,
      color: Colors.grey,
      isDefault: true,
    ),
  ];

  // 收入类别 
  static List<CategoryModel> incomeCategories = const [
    CategoryModel(
      id: 'salary',
      name: '工资',
      type: 'income',
      icon: Icons.account_balance_wallet,
      color: Colors.green,
      isDefault: true,
    ),
    CategoryModel(
      id: 'bonus',
      name: '奖金',
      type: 'income',
      icon: Icons.card_giftcard,
      color: Colors.amber,
      isDefault: true,
    ),
    CategoryModel(
      id: 'investment',
      name: '投资',
      type: 'income',
      icon: Icons.trending_up,
      color: Colors.blue,
      isDefault: true,
    ),
    CategoryModel(
      id: 'business',
      name: '生意收入',
      type: 'income',
      icon: Icons.store,
      color: Colors.indigo,
      isDefault: true,
    ),
    CategoryModel(
      id: 'other_income',
      name: '其他收入',
      type: 'income',
      icon: Icons.more_horiz,
      color: Colors.grey,
      isDefault: true,
    ),
  ];

  // 获取所有默认类别
  static List<CategoryModel> getAllCategories() {
    return [...expenseCategories, ...incomeCategories];
  }

  // 根据类型获取类别
  static List<CategoryModel> getCategoriesByType(String type) {
    return type == 'income' ? incomeCategories : expenseCategories;
  }

  // 根据ID获取类别
  static CategoryModel? getCategoryById(String id) {
    final allCategories = getAllCategories();
    try {
      return allCategories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }
}
