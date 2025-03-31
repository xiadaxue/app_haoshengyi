import 'package:flutter/material.dart';
import 'package:haoshengyi_jzzs_app/api/transaction_service.dart';
import 'package:haoshengyi_jzzs_app/constants/app_constants.dart';
import 'package:haoshengyi_jzzs_app/models/transaction_model.dart';
import 'package:haoshengyi_jzzs_app/utils/format_util.dart';
import 'package:haoshengyi_jzzs_app/utils/toast_util.dart';

/// 交易记录状态提供者
class TransactionProvider extends ChangeNotifier {
  final TransactionService _transactionService = TransactionService();

  // 交易记录列表
  List<TransactionModel> _transactions = [];
  List<TransactionModel> get transactions => _transactions;

  // 今日交易记录
  List<TransactionModel> _todayTransactions = [];
  List<TransactionModel> get todayTransactions => _todayTransactions;

  // 是否加载中
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 是否所有数据已加载完毕
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  // 当前页码
  int _currentPage = 1;
  int get currentPage => _currentPage;

  // 每页数量
  final int _pageSize = 20;

  // 总记录数
  int _total = 0;
  int get total => _total;

  // 今日统计
  Map<String, dynamic> _todaySummary = {
    'income': 0.0,
    'expense': 0.0,
    'profit': 0.0,
  };
  Map<String, dynamic> get todaySummary => _todaySummary;

  // 刷新交易记录
  Future<void> refreshTransactions() async {
    await fetchTodayTransactions();
  }

  // 根据月份获取交易记录
  Future<void> fetchTransactions({String? month}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 添加调试信息
      print('Fetching transactions for month: $month');

      // 处理月份
      String? startDate;
      String? endDate;

      if (month != null) {
        // 解析月份字符串，例如 "2024年02月"
        final year = int.parse(month.substring(0, 4));
        final monthNum = int.parse(month.substring(5, 7));

        // 计算该月的开始日期和结束日期
        final firstDay = DateTime(year, monthNum, 1);
        final lastDay = DateTime(year, monthNum + 1, 0);

        // 修改日期格式为 API 期望的格式
        startDate =
            "${firstDay.year}-${firstDay.month.toString().padLeft(2, '0')}-01";
        endDate =
            "${lastDay.year}-${lastDay.month.toString().padLeft(2, '0')}-${lastDay.day.toString().padLeft(2, '0')}";

        // 添加调试信息
        print('Start date: $startDate, End date: $endDate');
      }

      // 获取交易记录
      await getTransactions(
        startDate: startDate,
        endDate: endDate,
        refresh: true,
      );

      // 添加调试信息
      print('Total transactions fetched: ${_transactions.length}');
    } catch (e) {
      print('获取交易记录失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 获取今日交易记录
  Future<void> fetchTodayTransactions() async {
    try {
      // 获取今天的日期
      final today = DateTime.now();
      final todayStr =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

      final result = await _transactionService.getTransactions(
        startDate: todayStr,
        endDate: todayStr,
      );

      _todayTransactions = result['transactions'] as List<TransactionModel>;
      notifyListeners();
    } catch (e) {
      print('获取今日交易记录失败: $e');
    }
  }

  // 获取交易记录列表
  Future<void> getTransactions({
    String? startDate,
    String? endDate,
    String? type,
    String? category,
    bool refresh = false,
  }) async {
    print('getTransactions called with:');
    print(' - startDate: $startDate');
    print(' - endDate: $endDate');
    print(' - type: $type');
    print(' - category: $category');
    print(' - refresh: $refresh');

    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }

    if (!_hasMore || _isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      // 添加更详细的调试信息

      final result = await _transactionService.getTransactions(
        startDate: startDate,
        endDate: endDate,
        type: type,
        category: category,
        page: _currentPage,
        pageSize: _pageSize,
      );

      // 添加调试信息

      // 修复数据解析问题
      final List<TransactionModel> newTransactions =
          result['transactions'] ?? [];
      _total = result['total'] ?? 0;

      if (refresh) {
        _transactions = newTransactions;
      } else {
        _transactions.addAll(newTransactions);
      }

      // 如果是今天的交易记录，同时更新今日交易列表
      final today = DateTime.now();
      final todayStr =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
      if (startDate == todayStr && endDate == todayStr) {
        _todayTransactions = newTransactions;
      }

      _hasMore = newTransactions.length == _pageSize;
      _currentPage++;
    } catch (e) {
      print('获取交易记录列表失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 创建交易记录
  Future<String> createTransaction(TransactionModel transaction) async {
    _isLoading = true;
    notifyListeners();

    try {
      final transactionId =
          await _transactionService.createTransaction(transaction);

      // 添加到列表第一位
      final newTransaction = TransactionModel(
        transactionId: transactionId,
        type: transaction.type,
        amount: transaction.amount,
        category: transaction.category,
        remark: transaction.remark,
        transactionDate: transaction.transactionDate,
        tags: transaction.tags,
        users: transaction.users,
        products: transaction.products,
        containers: transaction.containers,
        createdAt: DateTime.now().toIso8601String(),
      );

      _transactions.insert(0, newTransaction);
      _total++;

      // 如果是今天的交易，也添加到今日交易列表
      final transactionDate = DateTime.parse(transaction.transactionDate);
      final today = DateTime.now();
      if (transactionDate.year == today.year &&
          transactionDate.month == today.month &&
          transactionDate.day == today.day) {
        _todayTransactions.insert(0, newTransaction);
      }

      // 更新今日统计
      await getTodaySummary();

      _isLoading = false;
      notifyListeners();
      return transactionId;
    } catch (e) {
      print('创建交易记录失败: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // 更新交易记录
  Future<bool> updateTransaction(
      String transactionId, TransactionModel transaction) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _transactionService.updateTransaction(transactionId, transaction);

      // 更新列表中的记录
      final index =
          _transactions.indexWhere((t) => t.transactionId == transactionId);
      if (index != -1) {
        _transactions[index] = TransactionModel(
          transactionId: transactionId,
          type: transaction.type,
          amount: transaction.amount,
          category: transaction.category,
          remark: transaction.remark,
          transactionDate: transaction.transactionDate,
          tags: transaction.tags,
          users: transaction.users,
          products: transaction.products,
          containers: transaction.containers,
          createdAt: transaction.createdAt,
          updatedAt: DateTime.now().toIso8601String(),
        );
      }

      // 更新今日交易列表
      final todayIndex = _todayTransactions
          .indexWhere((t) => t.transactionId == transactionId);
      if (todayIndex != -1) {
        _todayTransactions[todayIndex] = TransactionModel(
          transactionId: transactionId,
          type: transaction.type,
          amount: transaction.amount,
          category: transaction.category,
          remark: transaction.remark,
          transactionDate: transaction.transactionDate,
          tags: transaction.tags,
          users: transaction.users,
          products: transaction.products,
          containers: transaction.containers,
          createdAt: transaction.createdAt,
          updatedAt: DateTime.now().toIso8601String(),
        );
      }

      // 更新今日统计
      await getTodaySummary();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('更新交易记录失败: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // 删除交易记录
  Future<bool> deleteTransaction(String transactionId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _transactionService.deleteTransaction(transactionId);

      if (result) {
        // 从列表中移除
        _transactions.removeWhere((t) => t.transactionId == transactionId);
        _todayTransactions.removeWhere((t) => t.transactionId == transactionId);
        _total--;

        // 更新今日统计
        await getTodaySummary();
      }

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      print('删除交易记录失败: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // 获取交易记录详情
  Future<TransactionModel> getTransactionDetail(String transactionId) async {
    try {
      return await _transactionService.getTransactionDetail(transactionId);
    } catch (e) {
      print('获取交易记录详情失败: $e');
      rethrow;
    }
  }

  // 清空交易记录列表（例如切换账本时）
  void clearTransactions() {
    _transactions = [];
    _todayTransactions = [];
    _currentPage = 1;
    _hasMore = true;
    _total = 0;
    notifyListeners();
  }

  // 在 TransactionProvider 类中添加
  Future<void> getTodaySummary() async {
    try {
      // 获取今天的日期
      final today = DateTime.now();

      // 查询今日交易
      await fetchTodayTransactions();

      // 计算收入和支出
      double income = 0;
      double expense = 0;

      for (final transaction in _todayTransactions) {
        if (transaction.type == AppConstants.incomeType) {
          income += transaction.amount;
        } else if (transaction.type == AppConstants.expenseType) {
          expense += transaction.amount;
        }
      }

      // 更新今日统计
      _todaySummary = {
        'income': income,
        'expense': expense,
        'profit': income - expense,
      };

      notifyListeners();
    } catch (e) {
      print('获取今日统计失败: $e');
    }
  }

  // 获取可用的月份列表（修复后）
  Future<List<String>> getAvailableMonths() async {
    try {
      // 从服务层获取原始月份数据（例如：["2024-02", "2024-01"]）
      final result = await _transactionService.getAvailableMonths();

      // 转换日期格式并处理异常
      final months = result.map((monthStr) {
        try {
          // 解析服务端返回的月份格式（假设为 "YYYY-MM"）
          final parts = monthStr.split('-');
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          return '${year}年${month.toString().padLeft(2, '0')}月';
        } catch (e) {
          print('解析月份失败: $monthStr');
          return '无效月份';
        }
      }).toList();

      // 过滤无效数据并去重
      final validMonths = months.where((m) => m != '无效月份').toSet().toList();

      // 按时间倒序排序
      validMonths.sort((a, b) {
        final aDate =
            DateTime.parse(a.replaceAll('年', '-').replaceAll('月', ''));
        final bDate =
            DateTime.parse(b.replaceAll('年', '-').replaceAll('月', ''));
        return bDate.compareTo(aDate);
      });

      return validMonths;
    } catch (e) {
      print('获取可用月份失败: $e');
      ToastUtil.showError('无法获取月份数据');
      return [];
    }
  }

  // 根据月份获取交易数据
  Future<void> fetchTransactionsByMonth({String? month}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 添加调试信息
      print('Fetching transactions for month: $month');

      // 处理月份
      String? startDate;
      String? endDate;

      if (month != null) {
        // 解析月份字符串，例如 "2024年02月"
        final year = int.parse(month.substring(0, 4));
        final monthNum = int.parse(month.substring(5, 7));

        // 计算该月的开始日期和结束日期
        final firstDay = DateTime(year, monthNum, 1);
        final lastDay = DateTime(year, monthNum + 1, 0);

        // 修改日期格式为 API 期望的格式
        startDate =
            "${firstDay.year}-${firstDay.month.toString().padLeft(2, '0')}-01";
        endDate =
            "${lastDay.year}-${lastDay.month.toString().padLeft(2, '0')}-${lastDay.day.toString().padLeft(2, '0')}";

        // 添加调试信息
        print('Start date: $startDate, End date: $endDate');
      }

      // 获取交易记录
      await getTransactions(
        startDate: startDate,
        endDate: endDate,
        refresh: true,
      );

      // 添加调试信息
      print('Total transactions fetched: ${_transactions.length}');
    } catch (e) {
      print('获取交易记录失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
