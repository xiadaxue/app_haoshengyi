import 'package:flutter/material.dart';
import 'package:haoshengyi_jzzs_app/api/transaction_service.dart';
import 'package:haoshengyi_jzzs_app/constants/app_constants.dart';
import 'package:haoshengyi_jzzs_app/models/transaction_model.dart';
import 'package:haoshengyi_jzzs_app/utils/format_util.dart';
import 'package:haoshengyi_jzzs_app/utils/toast_util.dart';

/// 交易记录状态提供者
class TransactionProvider extends ChangeNotifier {
  final TransactionService _transactionService = TransactionService();

  // ============ 数据存储区 ============
  // 交易记录列表 - 按日期或月份存储
  final Map<String, List<TransactionModel>> _transactionCache = {};

  // 当前显示的交易列表（如当前月份或当前日期的数据）
  List<TransactionModel> _currentTransactions = [];
  List<TransactionModel> get transactions => _currentTransactions;

  // 首页交易记录列表
  List<TransactionModel> _homePageTransactions = [];
  List<TransactionModel> get homePageTransactions => _homePageTransactions;

  // 今日汇总数据
  Map<String, dynamic> _todaySummary = {
    'income': 0.0,
    'expense': 0.0,
    'profit': 0.0,
  };
  Map<String, dynamic> get todaySummary => _todaySummary;

  // 可用月份集合
  final Set<String> _availableMonths = {};
  List<String> get availableMonths => _availableMonths.toList()..sort();

  // 有数据的日期集合，按月份组织
  final Map<String, Set<String>> _datesWithDataByMonth = {};

  // ============ 状态标记区 ============
  // 加载状态
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isHomeLoading = false;
  bool get isHomeLoading => _isHomeLoading;

  // 当前使用的数据范围
  String? _currentDateRange;

  // 当前首页选中的日期
  String? _currentHomeDate;

  // 最后一次请求时间（用于限流）
  final Map<String, DateTime> _lastRequestTimes = {};

  // ============ 初始化和数据加载 ============
  /// 初始化数据 - 应用启动时调用一次
  Future<void> initializeData() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      // 加载今日数据
      final today = FormatUtil.formatDate(DateTime.now());
      await _loadDayData(today, forceRefresh: false);

      // 加载当前月数据
      final currentMonth = _getMonthFromDate(today);
      await _loadMonthData(currentMonth, forceRefresh: false);

      // 初始化月份列表
      await _initializeAvailableMonths();
    } catch (e) {
      print('初始化数据失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 初始化可用月份列表
  Future<void> _initializeAvailableMonths() async {
    try {
      // 获取服务器返回的可用月份
      final months = await _transactionService.getAvailableMonths();

      // 添加到可用月份集合
      for (final month in months) {
        final formattedMonth = _formatMonthForDisplay(month);
        if (formattedMonth != null) {
          _availableMonths.add(formattedMonth);
        }
      }

      // 确保当前月份在列表中
      final now = DateTime.now();
      final currentMonth =
          '${now.year}年${now.month.toString().padLeft(2, '0')}月';
      _availableMonths.add(currentMonth);
    } catch (e) {
      print('初始化月份列表失败: $e');

      // 失败时使用当前月份
      final now = DateTime.now();
      final currentMonth =
          '${now.year}年${now.month.toString().padLeft(2, '0')}月';
      _availableMonths.add(currentMonth);
    }
  }

  // ============ 核心数据加载函数 ============
  /// 加载指定日期的数据
  Future<List<TransactionModel>> _loadDayData(String date,
      {bool forceRefresh = false}) async {
    // 检查是否需要限流（仅当非强制刷新时检查）
    if (!forceRefresh && _shouldThrottle('day_$date')) {
      print('限流：跳过日期 $date 的数据加载');
      // 返回缓存数据
      return _transactionCache['day_$date'] ?? [];
    }

    try {
      _updateLastRequestTime('day_$date');

      // 检查缓存（仅当非强制刷新时检查）
      if (!forceRefresh && _transactionCache.containsKey('day_$date')) {
        return _transactionCache['day_$date']!;
      }

      // 请求API获取数据
      final result = await _transactionService.getTransactions(
        startDate: date,
        endDate: date,
        page: 1,
        pageSize: 100,
      );

      final transactions = result['transactions'] as List<TransactionModel>;

      // 无论是否有数据，都更新缓存
      _transactionCache['day_$date'] = transactions;

      // 更新月份数据集合
      final month = _getMonthFromDate(date);
      _addAvailableMonth(month);

      // 更新日期集合
      _datesWithDataByMonth.putIfAbsent(month, () => {});
      if (transactions.isNotEmpty) {
        _datesWithDataByMonth[month]!.add(date);
      } else {
        // 如果没有数据，从日期集合中移除
        _datesWithDataByMonth[month]!.remove(date);
      }

      return transactions;
    } catch (e) {
      print('加载日期 $date 数据失败: $e');
      return [];
    }
  }

  /// 加载指定月份的数据
  Future<List<TransactionModel>> _loadMonthData(String month,
      {bool forceRefresh = false}) async {
    // 检查是否需要限流（仅当非强制刷新时检查）
    if (!forceRefresh && _shouldThrottle('month_$month')) {
      print('限流：跳过月份 $month 的数据加载');
      // 返回缓存数据
      return _transactionCache['month_$month'] ?? [];
    }

    try {
      _updateLastRequestTime('month_$month');

      // 检查缓存（仅当非强制刷新时检查）
      if (!forceRefresh && _transactionCache.containsKey('month_$month')) {
        return _transactionCache['month_$month']!;
      }

      // 解析月份获取日期范围
      final dateRange = _getDateRangeFromMonth(month);
      if (dateRange == null) {
        print('无效的月份格式: $month');
        return [];
      }

      // 请求API获取数据
      final result = await _transactionService.getTransactions(
        startDate: dateRange['start'],
        endDate: dateRange['end'],
        page: 1,
        pageSize: 100,
      );

      final transactions = result['transactions'] as List<TransactionModel>;

      // 无论是否有数据，都更新缓存
      _transactionCache['month_$month'] = transactions;

      // 更新月份数据集合
      _addAvailableMonth(month);

      // 更新日期集合
      _datesWithDataByMonth.putIfAbsent(month, () => {});
      _datesWithDataByMonth[month]!.clear(); // 清除旧数据
      for (final transaction in transactions) {
        final dateStr = transaction.transactionDate.split('T')[0];
        _datesWithDataByMonth[month]!.add(dateStr);
      }

      return transactions;
    } catch (e) {
      print('加载月份 $month 数据失败: $e');
      return [];
    }
  }

  // ============ 对外公开的接口 ============
  /// 获取交易记录 - 按日期
  Future<void> getTransactionsByDate(String date,
      {bool updateCurrent = true, bool forceRefresh = false}) async {
    _isLoading = true;
    if (updateCurrent) {
      _currentDateRange = 'day_$date';
      notifyListeners();
    }

    try {
      final transactions = await _loadDayData(date, forceRefresh: forceRefresh);

      if (updateCurrent) {
        _currentTransactions = transactions;
      }
    } catch (e) {
      print('获取日期 $date 交易记录失败: $e');
    } finally {
      _isLoading = false;
      if (updateCurrent) {
        notifyListeners();
      }
    }
  }

  /// 获取交易记录 - 按月份
  Future<void> getTransactionsByMonth(String month,
      {bool updateCurrent = true, bool forceRefresh = false}) async {
    _isLoading = true;
    if (updateCurrent) {
      _currentDateRange = 'month_$month';
      notifyListeners();
    }

    try {
      final transactions =
          await _loadMonthData(month, forceRefresh: forceRefresh);

      if (updateCurrent) {
        _currentTransactions = transactions;
      }
    } catch (e) {
      print('获取月份 $month 交易记录失败: $e');
    } finally {
      _isLoading = false;
      if (updateCurrent) {
        notifyListeners();
      }
    }
  }

  /// 获取首页需要的交易数据
  Future<void> getHomePageData(String date, {bool forceRefresh = false}) async {
    _isHomeLoading = true;
    _currentHomeDate = date;
    notifyListeners();

    try {
      // 加载指定日期数据
      final transactions = await _loadDayData(date, forceRefresh: forceRefresh);

      // 更新首页交易列表
      _homePageTransactions = transactions;
    } catch (e) {
      print('获取首页数据失败: $e');
    } finally {
      _isHomeLoading = false;
      notifyListeners();
    }
  }

  /// 获取今日统计数据
  Future<void> getTodaySummary({bool refresh = false}) async {
    try {
      // 如果没有强制刷新且最近更新过，则跳过
      if (!refresh && _shouldThrottle('today_summary')) {
        print('限流：跳过今日统计数据加载');
        return;
      }

      _updateLastRequestTime('today_summary');

      // 从API获取今日统计
      final summary = await _transactionService.getTodaySummary();
      print('获取今日统计数据成功: $summary');

      // 更新统计数据
      _todaySummary = summary;
      notifyListeners();
    } catch (e) {
      print('获取今日统计数据失败: $e');
    }
  }

  /// 获取指定月份中有交易数据的日期列表
  Future<List<String>> getDatesWithDataForMonth(String month) async {
    try {
      // 确保月份数据已加载
      await _loadMonthData(month);

      // 从缓存返回该月份的日期列表
      return _datesWithDataByMonth[month]?.toList() ?? [];
    } catch (e) {
      print('获取月份 $month 的日期列表失败: $e');
      return [];
    }
  }

  /// 刷新当前数据
  Future<void> refreshCurrentData({bool force = true}) async {
    try {
      print('开始刷新当前数据，强制刷新: $force');

      // 强制刷新当前选中的数据范围
      if (_currentDateRange != null) {
        if (_currentDateRange!.startsWith('day_')) {
          final date = _currentDateRange!.substring(4);
          print('刷新日期数据: $date');
          await getTransactionsByDate(date,
              updateCurrent: true, forceRefresh: force);
        } else if (_currentDateRange!.startsWith('month_')) {
          final month = _currentDateRange!.substring(6);
          print('刷新月份数据: $month');
          await getTransactionsByMonth(month,
              updateCurrent: true, forceRefresh: force);
        } else if (_currentDateRange!.startsWith('range_')) {
          final parts = _currentDateRange!.substring(6).split('_');
          if (parts.length == 2) {
            final startDate = parts[0];
            final endDate = parts[1];
            print('刷新日期范围数据: $startDate 至 $endDate');
            final result = await _transactionService.getTransactions(
              startDate: startDate,
              endDate: endDate,
              page: 1,
              pageSize: 100,
            );
            _currentTransactions =
                result['transactions'] as List<TransactionModel>;
          }
        }
      }

      // 强制刷新首页数据
      if (_currentHomeDate != null) {
        print('刷新首页数据，日期: $_currentHomeDate');
        await getHomePageData(_currentHomeDate!, forceRefresh: force);
      } else {
        // 如果没有当前首页日期，默认刷新今日数据
        final today = FormatUtil.formatDate(DateTime.now());
        print('刷新默认今日数据: $today');
        await getHomePageData(today, forceRefresh: force);
      }

      // 刷新今日统计
      await getTodaySummary(refresh: true);

      // 清除请求限流记录，确保下次可以立即刷新
      if (force) {
        _lastRequestTimes.clear();
      }

      // 通知UI更新
      notifyListeners();

      print('数据刷新完成');
    } catch (e) {
      print('刷新数据失败: $e');
    }
  }

  /// 获取可用月份列表
  Future<List<String>> getAvailableMonths() async {
    // 确保月份列表已初始化
    if (_availableMonths.isEmpty) {
      await _initializeAvailableMonths();
    }
    return availableMonths;
  }

  // ============ CRUD 操作 ============
  /// 创建交易记录
  Future<String> createTransaction(TransactionModel transaction) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 确保结算状态字段有默认值
      final transactionWithStatus = transaction.settlementStatus == null
          ? transaction.copyWith(
              settlementStatus: TransactionModel.unsettledStatus)
          : transaction;

      // 调用API创建记录
      final transactionId =
          await _transactionService.createTransaction(transactionWithStatus);

      print(
          '创建交易记录成功，ID: $transactionId, 日期: ${transaction.transactionDate.split('T')[0]}');

      // 创建新的交易记录对象
      final newTransaction = TransactionModel(
        transactionId: transactionId,
        type: transactionWithStatus.type,
        amount: transactionWithStatus.amount,
        category: transactionWithStatus.category,
        remark: transactionWithStatus.remark,
        transactionDate: transactionWithStatus.transactionDate,
        tags: transactionWithStatus.tags,
        users: transactionWithStatus.users,
        products: transactionWithStatus.products,
        containers: transactionWithStatus.containers,
        createdAt: DateTime.now().toIso8601String(),
        classType: transactionWithStatus.classType,
        settlementStatus: transactionWithStatus.settlementStatus,
      );

      // 更新缓存
      final date = transactionWithStatus.transactionDate.split('T')[0];
      final month = _getMonthFromDate(date);

      // 更新日期缓存
      _transactionCache.putIfAbsent('day_$date', () => []);
      _transactionCache['day_$date']!.insert(0, newTransaction);

      // 更新月份缓存
      _transactionCache.putIfAbsent('month_$month', () => []);
      _transactionCache['month_$month']!.insert(0, newTransaction);

      // 更新当前显示的数据
      if (_currentDateRange == 'day_$date') {
        _currentTransactions.insert(0, newTransaction);
      } else if (_currentDateRange == 'month_$month') {
        _currentTransactions.insert(0, newTransaction);
      }

      // 更新首页数据 - 无论当前日期是否匹配，都更新首页数据，确保记录立即可见
      if (_currentHomeDate == date) {
        _homePageTransactions.insert(0, newTransaction);
      } else {
        // 如果不是当前显示的日期，则尝试强制刷新首页数据
        final today = FormatUtil.formatDate(DateTime.now());
        if (date == today) {
          // 如果是今天的记录，但首页不是展示今天，也强制添加
          _homePageTransactions.insert(0, newTransaction);
        }
      }

      // 更新日期集合
      _datesWithDataByMonth.putIfAbsent(month, () => {});
      _datesWithDataByMonth[month]!.add(date);

      // 更新月份集合
      _addAvailableMonth(month);

      // 如果是今天的数据，更新今日统计
      final today = FormatUtil.formatDate(DateTime.now());
      if (date == today) {
        // 直接更新缓存中的今日统计，无需重新请求API
        if (transaction.type == AppConstants.incomeType) {
          _todaySummary['income'] =
              (_todaySummary['income'] ?? 0.0) + transaction.amount;
          _todaySummary['profit'] =
              (_todaySummary['profit'] ?? 0.0) + transaction.amount;
        } else if (transaction.type == AppConstants.expenseType) {
          _todaySummary['expense'] =
              (_todaySummary['expense'] ?? 0.0) + transaction.amount;
          _todaySummary['profit'] =
              (_todaySummary['profit'] ?? 0.0) - transaction.amount;
        }
      }

      _isLoading = false;
      notifyListeners();

      // 立即触发一次额外的通知，确保UI更新
      Future.delayed(Duration(milliseconds: 100), () {
        notifyListeners();
      });

      return transactionId;
    } catch (e) {
      print('创建交易记录失败: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// 更新交易记录
  Future<bool> updateTransaction(
      String transactionId, TransactionModel transaction) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _transactionService.updateTransaction(transactionId, transaction);

      // 创建更新后的交易记录对象
      final updatedTransaction = TransactionModel(
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
        classType: transaction.classType,
        settlementStatus: transaction.settlementStatus,
      );

      // 更新所有缓存
      final oldTransaction = _findTransactionById(transactionId);
      final newDate = transaction.transactionDate.split('T')[0];
      final newMonth = _getMonthFromDate(newDate);

      // 如果找到了旧记录并且日期有变化，需要从旧的日期和月份中删除
      if (oldTransaction != null) {
        final oldDate = oldTransaction.transactionDate.split('T')[0];
        final oldMonth = _getMonthFromDate(oldDate);

        // 更新日期缓存
        if (_transactionCache.containsKey('day_$oldDate')) {
          _transactionCache['day_$oldDate']!
              .removeWhere((t) => t.transactionId == transactionId);
        }

        if (_transactionCache.containsKey('day_$newDate')) {
          final index = _transactionCache['day_$newDate']!
              .indexWhere((t) => t.transactionId == transactionId);
          if (index >= 0) {
            _transactionCache['day_$newDate']![index] = updatedTransaction;
          } else {
            _transactionCache['day_$newDate']!.add(updatedTransaction);
          }
        }

        // 更新月份缓存
        if (_transactionCache.containsKey('month_$oldMonth')) {
          _transactionCache['month_$oldMonth']!
              .removeWhere((t) => t.transactionId == transactionId);
        }

        if (_transactionCache.containsKey('month_$newMonth')) {
          final index = _transactionCache['month_$newMonth']!
              .indexWhere((t) => t.transactionId == transactionId);
          if (index >= 0) {
            _transactionCache['month_$newMonth']![index] = updatedTransaction;
          } else {
            _transactionCache['month_$newMonth']!.add(updatedTransaction);
          }
        }
      }

      // 更新当前显示的数据
      final currentIndex = _currentTransactions
          .indexWhere((t) => t.transactionId == transactionId);
      if (currentIndex >= 0) {
        _currentTransactions[currentIndex] = updatedTransaction;
      }

      // 更新首页数据
      final homeIndex = _homePageTransactions
          .indexWhere((t) => t.transactionId == transactionId);
      if (homeIndex >= 0) {
        _homePageTransactions[homeIndex] = updatedTransaction;
      }

      // 如果是今天的数据，更新今日统计
      final today = FormatUtil.formatDate(DateTime.now());
      if (newDate == today ||
          (oldTransaction != null &&
              oldTransaction.transactionDate.split('T')[0] == today)) {
        await getTodaySummary(refresh: true);
      }

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

  /// 删除交易记录
  Future<bool> deleteTransaction(String transactionId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _transactionService.deleteTransaction(transactionId);

      if (result) {
        // 找到要删除的记录
        final oldTransaction = _findTransactionById(transactionId);

        if (oldTransaction != null) {
          final date = oldTransaction.transactionDate.split('T')[0];
          final month = _getMonthFromDate(date);

          // 从日期缓存中删除
          if (_transactionCache.containsKey('day_$date')) {
            _transactionCache['day_$date']!
                .removeWhere((t) => t.transactionId == transactionId);
          }

          // 从月份缓存中删除
          if (_transactionCache.containsKey('month_$month')) {
            _transactionCache['month_$month']!
                .removeWhere((t) => t.transactionId == transactionId);
          }

          // 从当前显示的数据中删除
          _currentTransactions
              .removeWhere((t) => t.transactionId == transactionId);

          // 从首页数据中删除
          _homePageTransactions
              .removeWhere((t) => t.transactionId == transactionId);

          // 如果是今天的数据，更新今日统计
          final today = FormatUtil.formatDate(DateTime.now());
          if (date == today) {
            await getTodaySummary(refresh: true);
          }
        }
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

  /// 获取交易记录详情
  Future<TransactionModel> getTransactionDetail(String transactionId) async {
    try {
      return await _transactionService.getTransactionDetail(transactionId);
    } catch (e) {
      print('获取交易记录详情失败: $e');
      rethrow;
    }
  }

  /// 更新交易记录的结算状态
  Future<bool> updateTransactionSettlementStatus(
      String transactionId, String status) async {
    try {
      // 查找交易记录
      final transaction = _findTransactionById(transactionId);
      if (transaction == null) {
        print('未找到交易记录: $transactionId');
        return false;
      }

      // 使用copyWith创建新的交易记录，并更新结算状态
      final updatedTransaction = transaction.copyWith(
        settlementStatus: status,
      );

      // 使用现有的更新方法保存更改
      return await updateTransaction(transactionId, updatedTransaction);
    } catch (e) {
      print('更新结算状态失败: $e');
      return false;
    }
  }

  /// 更新交易记录（不自动刷新UI，用于结算状态更新等小修改）
  Future<bool> updateTransactionWithoutRefresh(
      String transactionId, TransactionModel transaction) async {
    try {
      // 直接调用服务更新数据
      await _transactionService.updateTransaction(transactionId, transaction);
      print(
          '交易记录更新成功，ID: $transactionId, 结算状态: ${transaction.settlementStatus}');
      return true;
    } catch (e) {
      print('更新交易记录失败: $e');
      return false;
    }
  }

  /// 只在本地更新交易记录，不触发服务端请求
  void updateLocalTransaction(TransactionModel updatedTransaction) {
    final transactionId = updatedTransaction.transactionId;
    if (transactionId == null) return;

    // 更新当前显示的数据
    final currentIndex = _currentTransactions.indexWhere(
        (transaction) => transaction.transactionId == transactionId);
    if (currentIndex >= 0) {
      _currentTransactions[currentIndex] = updatedTransaction;
    }

    // 更新首页数据
    final homeIndex = _homePageTransactions.indexWhere(
        (transaction) => transaction.transactionId == transactionId);
    if (homeIndex >= 0) {
      _homePageTransactions[homeIndex] = updatedTransaction;
    }

    // 更新日期缓存
    final date = updatedTransaction.transactionDate.split('T')[0];
    final dayCacheKey = 'day_$date';
    if (_transactionCache.containsKey(dayCacheKey)) {
      final dayIndex = _transactionCache[dayCacheKey]!.indexWhere(
          (transaction) => transaction.transactionId == transactionId);
      if (dayIndex >= 0) {
        _transactionCache[dayCacheKey]![dayIndex] = updatedTransaction;
      }
    }

    // 更新月份缓存
    final month = _getMonthFromDate(date);
    final monthCacheKey = 'month_$month';
    if (_transactionCache.containsKey(monthCacheKey)) {
      final monthIndex = _transactionCache[monthCacheKey]!.indexWhere(
          (transaction) => transaction.transactionId == transactionId);
      if (monthIndex >= 0) {
        _transactionCache[monthCacheKey]![monthIndex] = updatedTransaction;
      }
    }

    notifyListeners();
  }

  // ============ 工具方法 ============
  /// 查找指定ID的交易记录
  TransactionModel? _findTransactionById(String transactionId) {
    // 先在当前显示的数据中查找
    for (var transaction in _currentTransactions) {
      if (transaction.transactionId == transactionId) {
        return transaction;
      }
    }

    // 再在首页数据中查找
    for (var transaction in _homePageTransactions) {
      if (transaction.transactionId == transactionId) {
        return transaction;
      }
    }

    // 最后在所有缓存中查找
    for (var entry in _transactionCache.entries) {
      for (var transaction in entry.value) {
        if (transaction.transactionId == transactionId) {
          return transaction;
        }
      }
    }

    return null;
  }

  /// 从日期中提取月份，如 "2023-04-15" -> "2023年04月"
  String _getMonthFromDate(String date) {
    final parts = date.split('-');
    if (parts.length >= 2) {
      return '${parts[0]}年${parts[1]}月';
    }
    return '';
  }

  /// 将月份转换为API格式，如 "2023年04月" -> "2023-04"
  String _formatMonthForAPI(String month) {
    final parts = month.split('年');
    if (parts.length == 2) {
      final yearPart = parts[0];
      final monthPart = parts[1].replaceAll('月', '');
      return '$yearPart-$monthPart';
    }
    return month;
  }

  /// 将API月份格式转换为显示格式，如 "2023-04" -> "2023年04月"
  String? _formatMonthForDisplay(String apiMonth) {
    try {
      final parts = apiMonth.split('-');
      if (parts.length == 2) {
        final year = parts[0];
        final month = parts[1];
        return '${year}年${month}月';
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 从月份获取日期范围，如 "2023年04月" -> {start: "2023-04-01", end: "2023-04-30"}
  Map<String, String>? _getDateRangeFromMonth(String month) {
    try {
      final apiMonth = _formatMonthForAPI(month);
      final parts = apiMonth.split('-');

      if (parts.length == 2) {
        final year = int.parse(parts[0]);
        final monthNum = int.parse(parts[1]);

        final firstDay = DateTime(year, monthNum, 1);
        final lastDay = DateTime(year, monthNum + 1, 0); // 获取当月最后一天

        return {
          'start': FormatUtil.formatDate(firstDay),
          'end': FormatUtil.formatDate(lastDay),
        };
      }

      return null;
    } catch (e) {
      print('解析月份日期范围失败: $e');
      return null;
    }
  }

  /// 添加月份到可用月份集合
  void _addAvailableMonth(String month) {
    _availableMonths.add(month);
  }

  /// 更新今日统计数据
  void _updateTodaySummary(List<TransactionModel> todayTransactions) {
    double income = 0;
    double expense = 0;

    for (final transaction in todayTransactions) {
      if (transaction.type == AppConstants.incomeType) {
        income += transaction.amount;
      } else if (transaction.type == AppConstants.expenseType) {
        expense += transaction.amount;
      }
    }

    _todaySummary = {
      'income': income,
      'expense': expense,
      'profit': income - expense,
    };
  }

  /// 更新最后一次请求时间
  void _updateLastRequestTime(String key) {
    _lastRequestTimes[key] = DateTime.now();
  }

  /// 检查是否需要限流
  bool _shouldThrottle(String key) {
    if (!_lastRequestTimes.containsKey(key)) {
      return false;
    }

    final lastTime = _lastRequestTimes[key]!;
    final now = DateTime.now();

    // 1秒内不重复请求
    return now.difference(lastTime).inMilliseconds < 1000;
  }

  /// 清空缓存
  void clearCache() {
    _transactionCache.clear();
    _currentTransactions = [];
    _homePageTransactions = [];
    _availableMonths.clear();
    _datesWithDataByMonth.clear();
    _lastRequestTimes.clear();
    notifyListeners();
  }

  /// 检查指定月份是否有数据
  bool hasDataForMonth(String month) {
    // 检查缓存中是否有该月数据
    if (_transactionCache.containsKey('month_$month')) {
      return _transactionCache['month_$month']!.isNotEmpty;
    }

    // 检查日期集合中是否有该月数据
    if (_datesWithDataByMonth.containsKey(month)) {
      return _datesWithDataByMonth[month]!.isNotEmpty;
    }

    // 默认假设没有数据
    return false;
  }
}
