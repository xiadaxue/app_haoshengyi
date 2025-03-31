import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:haoshengyi_jzzs_app/models/category_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 交易分类状态提供者
class CategoryProvider extends ChangeNotifier {
  // 所有类别
  List<CategoryModel> _categories = [];
  List<CategoryModel> get categories => _categories;

  // 收入类别
  List<CategoryModel> get incomeCategories =>
      _categories.where((category) => category.type == 'income').toList();

  // 支出类别
  List<CategoryModel> get expenseCategories =>
      _categories.where((category) => category.type == 'expense').toList();

  // 初始化类别
  Future<void> initCategories() async {
    try {
      // 从本地存储加载类别
      final prefs = await SharedPreferences.getInstance();
      final categoriesJson = prefs.getString('categories');

      if (categoriesJson != null) {
        // 解析JSON并转换为类别对象
        final List<dynamic> categoriesList = json.decode(categoriesJson);
        _categories = categoriesList.map((categoryJson) {
          return CategoryModel.fromJson(categoryJson);
        }).toList();
      } else {
        // 使用默认类别
        _categories = DefaultCategories.getAllCategories();
        // 保存到本地存储
        await saveCategories();
      }
    } catch (e) {
      // 如果加载失败，使用默认类别
      _categories = DefaultCategories.getAllCategories();
    }

    notifyListeners();
  }

  // 保存类别到本地存储
  Future<void> saveCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categoriesJson = json.encode(
        _categories.map((category) => category.toJson()).toList(),
      );
      await prefs.setString('categories', categoriesJson);
    } catch (e) {
      // 忽略存储错误
    }
  }

  // 添加类别
  Future<void> addCategory(CategoryModel category) async {
    // 检查是否已存在同名类别
    if (_categories
        .any((c) => c.name == category.name && c.type == category.type)) {
      throw '已存在相同名称的${category.type == 'income' ? '收入' : '支出'}类别';
    }

    _categories.add(category);
    await saveCategories();
    notifyListeners();
  }

  // 更新类别
  Future<void> updateCategory(String id, CategoryModel category) async {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index == -1) {
      throw '类别不存在';
    }

    // 检查是否已存在同名类别（排除自己）
    if (_categories.any((c) =>
        c.name == category.name && c.type == category.type && c.id != id)) {
      throw '已存在相同名称的${category.type == 'income' ? '收入' : '支出'}类别';
    }

    _categories[index] = category;
    await saveCategories();
    notifyListeners();
  }

  // 删除类别
  Future<void> deleteCategory(String id) async {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index == -1) {
      throw '类别不存在';
    }

    final category = _categories[index];

    // 不允许删除默认类别
    if (category.isDefault) {
      throw '不能删除默认类别';
    }

    _categories.removeWhere((c) => c.id == id);
    await saveCategories();
    notifyListeners();
  }

  // 根据ID获取类别
  CategoryModel? getCategoryById(String id) {
    try {
      return _categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  // 根据类型获取类别
  List<CategoryModel> getCategoriesByType(String type) {
    return _categories.where((category) => category.type == type).toList();
  }

  // 重置为默认类别
  Future<void> resetToDefault() async {
    _categories = DefaultCategories.getAllCategories();
    await saveCategories();
    notifyListeners();
  }
}
