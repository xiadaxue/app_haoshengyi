import 'package:flutter/material.dart';
import 'package:haoshengyi_jzzs_app/constants/app_constants.dart';
import 'package:haoshengyi_jzzs_app/models/transaction_model.dart';
import 'package:haoshengyi_jzzs_app/providers/transaction_provider.dart';
import 'package:haoshengyi_jzzs_app/theme/app_theme.dart';
import 'package:haoshengyi_jzzs_app/utils/format_util.dart';
import 'package:haoshengyi_jzzs_app/utils/toast_util.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

/// 统计分析页面
class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage>
    with AutomaticKeepAliveClientMixin {
  bool _isLoading = false;
  List<String> _months = [];
  String? _selectedMonth;

  // 添加缺失的变量定义
  List<TransactionModel> _transactions = [];
  Map<String, double> _categoryStats = {};
  int? _selectedSectionIndex;

  // 统计类型：收入/支出
  String _statsType = AppConstants.incomeType; // 默认显示收入统计

  // 统计视图类型：图表/列表
  String _viewType = 'chart'; // chart, list

  // 搜索相关
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<TransactionModel> _filteredTransactions = [];
  bool _showSearchResults = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // 使用延迟加载确保页面完全初始化
    ToastUtil.debug("统计页面初始化");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ToastUtil.debug("统计页面准备加载数据");
      _generateLocalMonths();
      _loadMonths();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 生成本地月份列表
  void _generateLocalMonths() {
    final now = DateTime.now();
    final List<String> localMonths = [];

    // 从2025-01开始生成月份
    DateTime startDate = DateTime(2025, 1, 1);

    // 生成到当前月份的列表
    while (startDate.year <= now.year &&
        (startDate.year != now.year || startDate.month <= now.month)) {
      localMonths.add(
          '${startDate.year}年${startDate.month.toString().padLeft(2, '0')}月');
      startDate = DateTime(startDate.year, startDate.month + 1, 1);
    }

    setState(() {
      _months = localMonths;
      _selectedMonth = '${now.year}年${now.month.toString().padLeft(2, '0')}月';
    });
  }

  // 加载月份列表
  Future<void> _loadMonths() async {
    if (_isLoading) {
      ToastUtil.debug("已在加载中，跳过");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 获取当前月份作为默认值
      final now = DateTime.now().toLocal();
      final currentMonth =
          '${now.year}年${now.month.toString().padLeft(2, '0')}月';

      ToastUtil.debug("当前月份: $currentMonth");

      final transactionProvider = context.read<TransactionProvider>();
      ToastUtil.debug("开始获取可用月份");
      final apiMonths = await transactionProvider.getAvailableMonths();

      ToastUtil.debug("获取到月份列表: $apiMonths");

      // 合并本地生成的月份和API返回的月份，去重
      if (apiMonths.isNotEmpty) {
        setState(() {
          final Set<String> uniqueMonths = Set<String>.from(_months)
            ..addAll(apiMonths);
          _months = uniqueMonths.toList()..sort();
        });
      }

      // 如果当前选中的月份不在列表中，使用列表中最新的月份
      setState(() {
        if (!_months.contains(_selectedMonth)) {
          _selectedMonth = _months.isNotEmpty ? _months.last : currentMonth;
        }
      });

      // 加载选中月份的数据
      await _loadTransactionsForMonth(_selectedMonth!);
    } catch (e) {
      ToastUtil.debug("加载月份列表失败: $e");

      // 出错时使用当前月份
      final now = DateTime.now().toLocal();
      final currentMonth =
          '${now.year}年${now.month.toString().padLeft(2, '0')}月';

      ToastUtil.debug("使用默认月份: $currentMonth");

      setState(() {
        if (!_months.contains(currentMonth)) {
          _months.add(currentMonth);
          _months.sort();
        }
        _selectedMonth = currentMonth;
      });

      // 尝试加载当前月份的数据
      try {
        await _loadTransactionsForMonth(currentMonth);
      } catch (e) {
        ToastUtil.debug("加载默认月份数据失败: $e");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 修改加载月份数据方法
  Future<void> _loadTransactionsForMonth(String month) async {
    print('开始加载月份数据: $month');

    setState(() {
      _isLoading = true;
    });

    try {
      final transactionProvider = context.read<TransactionProvider>();

      // 解析月份字符串为日期范围
      int year, monthNum;
      try {
        final parts = month.split('年');
        year = int.parse(parts[0]);
        monthNum = int.parse(parts[1].replaceAll('月', ''));
      } catch (e) {
        print('解析月份字符串失败: $e，使用当前日期');
        final now = DateTime.now().toLocal();
        year = now.year;
        monthNum = now.month;
      }

      // 计算月份的开始和结束日期（使用本地时区）
      final startDate = DateTime(year, monthNum, 1).toLocal();
      final endDate = DateTime(year, monthNum + 1, 0).toLocal();

      // 格式化日期为字符串
      final startDateStr = FormatUtil.formatDate(startDate);
      final endDateStr = FormatUtil.formatDate(endDate);

      print('加载月份数据: $month, 日期范围: $startDateStr 至 $endDateStr');

      // 加载指定月份的交易数据
      await transactionProvider.getTransactionsByMonth(month);

      // 更新本地数据
      setState(() {
        _transactions = transactionProvider.transactions;
        // 新增：计算分类统计数据
        _calculateCategoryStats();
      });

      print('成功加载交易数据，数量: ${_transactions.length}');
    } catch (e) {
      print('加载交易数据失败: $e');

      // 确保即使出错也设置空数据，而不是保留旧数据
      setState(() {
        _transactions = [];
        _categoryStats = {};
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 将 "2023年11月" 转换为 "2023-11"
  String _parseMonthString(String month) {
    try {
      final parts = month.split('年');
      final year = parts[0];
      final monthPart = parts[1].replaceAll('月', '');
      return '$year-$monthPart';
    } catch (e) {
      print('解析月份字符串失败: $e');
      // 返回当前月份作为默认值
      final now = DateTime.now().toLocal();
      return '${now.year}-${now.month.toString().padLeft(2, '0')}';
    }
  }

  // 新增：计算分类统计数据
  void _calculateCategoryStats() {
    _categoryStats = {};

    // 检查是否有交易数据
    if (_transactions.isEmpty) {
      print('没有交易数据，无法计算分类统计');
      return;
    }

    // 过滤当前统计类型的数据
    final filteredTransactions =
        _transactions.where((t) => t.type == _statsType).toList();

    print('过滤后的交易数据数量: ${filteredTransactions.length}');

    // 按分类统计金额
    for (var transaction in filteredTransactions) {
      // 获取显示名称
      String displayName = '';
      if (transaction.users != null && transaction.users!.isNotEmpty) {
        // 如果有用户信息，显示第一个用户
        displayName = transaction.users!.first;
      } else {
        // 如果没有用户信息，显示类别
        displayName = transaction.category;
      }

      final amount = transaction.amount;

      _categoryStats[displayName] = (_categoryStats[displayName] ?? 0) + amount;
    }

    print('计算完成的分类统计: $_categoryStats');
  }

  // 新增：搜索备注
  void _searchRemarks(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchQuery = '';
        _showSearchResults = false;
        _filteredTransactions = [];
      });
      return;
    }

    setState(() {
      _searchQuery = query;
      _showSearchResults = true;
      _filteredTransactions = _transactions.where((transaction) {
        return transaction.remark.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  // 修改 build 方法
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('统计分析'),
        actions: [
          // 搜索按钮
          IconButton(
            icon: Icon(_showSearchResults ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearchResults = !_showSearchResults;
                if (!_showSearchResults) {
                  _searchController.clear();
                  _searchQuery = '';
                  _filteredTransactions = [];
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          if (_showSearchResults)
            Padding(
              padding: EdgeInsets.only(top: 8.r, left: 15.r, right: 15.r),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '搜索备注...',
                  prefixIcon: Icon(Icons.search, size: 18.sp),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, size: 18.sp),
                          onPressed: () {
                            _searchController.clear();
                            _searchRemarks('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 0.r),
                  isDense: true,
                ),
                onChanged: _searchRemarks,
                textInputAction: TextInputAction.search,
              ),
            ),

          if (!_showSearchResults) ...[
            // 月份选择器
            _buildMonthSelector(),
            SizedBox(height: 10.h),

            // 统计类型选择和视图类型切换
            Container(
              padding: EdgeInsets.symmetric(horizontal: 15.r, vertical: 10.r),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40.h,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        children: [
                          _buildTypeTab(AppConstants.incomeType, '收入'),
                          _buildTypeTab(AppConstants.expenseType, '支出'),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 15.w),
                  // 视图类型切换
                  Container(
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      children: [
                        _buildViewTab('chart', Icons.pie_chart),
                        _buildViewTab('list', Icons.view_list),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 数据内容
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _showSearchResults
                    ? _buildSearchResults()
                    : _transactions.isEmpty
                        ? _buildEmptyView()
                        : _categoryStats.isEmpty
                            ? Center(
                                child: Text(
                                  '当前月份没有${_statsType == AppConstants.incomeType ? '收入' : '支出'}数据',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                ),
                              )
                            : _viewType == 'chart'
                                ? _buildChartView(_categoryStats, _transactions)
                                : _buildListView(_categoryStats, _transactions),
          ),
        ],
      ),
    );
  }

  // 新增：构建搜索结果视图
  Widget _buildSearchResults() {
    if (_filteredTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 60.sp,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: 15.h),
            Text(
              '未找到包含"$_searchQuery"的备注',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(15.r),
      itemCount: _filteredTransactions.length,
      itemBuilder: (context, index) {
        final transaction = _filteredTransactions[index];
        return _buildTransactionItem(transaction);
      },
    );
  }

  // 新增：构建交易项卡片
  Widget _buildTransactionItem(TransactionModel transaction) {
    final isIncome = transaction.type == AppConstants.incomeType;
    final isExpense = transaction.type == AppConstants.expenseType;

    final typeColor = isIncome ? AppTheme.incomeColor : AppTheme.expenseColor;
    final typeText = isIncome ? '收入' : '支出';

    // 获取显示名称
    String displayName = '';
    if (transaction.users != null && transaction.users!.isNotEmpty) {
      // 如果有用户信息，显示第一个用户
      displayName = transaction.users!.first;
    } else {
      // 如果没有用户信息，显示类别
      displayName = transaction.category;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 10.r),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.r, vertical: 2.r),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    typeText,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: typeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    transaction.remark.isEmpty ? '无备注' : transaction.remark,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  FormatUtil.formatCurrency(transaction.amount),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: typeColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 5.h),
            Text(
              FormatUtil.formatDateTimeWithFormat(
                FormatUtil.parseDateTime(transaction.transactionDate)
                        ?.toLocal() ??
                    DateTime.now(),
                format: 'yyyy-MM-dd HH:mm',
              ),
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建统计类型选项卡
  Widget _buildTypeTab(String type, String label) {
    final isSelected = _statsType == type;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _statsType = type;
            // 切换类型后重新计算统计数据
            _calculateCategoryStats();
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8.r),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
            ),
          ),
        ),
      ),
    );
  }

  // 构建视图类型选项卡
  Widget _buildViewTab(String type, IconData icon) {
    final isSelected = _viewType == type;

    return InkWell(
      onTap: () {
        setState(() {
          _viewType = type;
        });
      },
      child: Container(
        width: 40.w,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 22.sp,
          color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
        ),
      ),
    );
  }

  // 构建图表视图
  Widget _buildChartView(
      Map<String, double> stats, List<TransactionModel> transactions) {
    // 计算总额
    final filteredTransactions =
        transactions.where((t) => t.type == _statsType).toList();
    final total =
        filteredTransactions.fold<double>(0, (sum, t) => sum + t.amount);

    return SingleChildScrollView(
      padding: EdgeInsets.all(15.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 总额卡片
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(20.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _statsType == AppConstants.incomeType ? '本月总收入' : '本月总支出',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    FormatUtil.formatCurrency(total),
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: _statsType == AppConstants.incomeType
                          ? AppTheme.incomeColor
                          : AppTheme.expenseColor,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '共${filteredTransactions.length}笔交易',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 25.h),

          // 饼图标题
          Padding(
            padding: EdgeInsets.only(left: 5.r, bottom: 15.r),
            child: Text(
              '支出分类占比',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),

          // 修改饼图尺寸和容器
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: EdgeInsets.all(15.r),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: PieChart(
                PieChartData(
                  sections: _buildPieChartSections(stats),
                  centerSpaceRadius: 0, // 实心饼图
                  sectionsSpace: 1.5, // 小间距更美观
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (event is FlTapUpEvent &&
                            pieTouchResponse?.touchedSection != null) {
                          _selectedSectionIndex = pieTouchResponse!
                              .touchedSection!.touchedSectionIndex;
                        } else {
                          _selectedSectionIndex = null;
                        }
                      });
                    },
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 25.h),

          // 添加图例标题
          Padding(
            padding: EdgeInsets.only(left: 5.r, bottom: 10.r),
            child: Text(
              '分类明细',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),

          // 添加图例容器
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: EdgeInsets.all(15.r),
            child: _buildLegend(stats),
          ),
        ],
      ),
    );
  }

  // 构建饼状图数据
  List<PieChartSectionData> _buildPieChartSections(Map<String, double> stats) {
    // 优化颜色配置 - 使用更鲜艳的颜色
    final colors = [
      Color(0xFF4285F4), // Google Blue
      Color(0xFFEA4335), // Google Red
      Color(0xFF34A853), // Google Green
      Color(0xFFFBBC05), // Google Yellow
      Color(0xFF9C27B0), // Purple
      Color(0xFF00BCD4), // Cyan
      Color(0xFFFF9800), // Orange
      Color(0xFF795548), // Brown
      Color(0xFF607D8B), // Blue Grey
      Color(0xFF3F51B5), // Indigo
    ];

    final total = stats.values.fold<double>(0, (sum, amount) => sum + amount);

    return stats.entries.map((entry) {
      final index = stats.keys.toList().indexOf(entry.key);
      final percentage = (entry.value / total * 100);

      return PieChartSectionData(
        color: colors[index % colors.length],
        value: entry.value,
        title: percentage >= 5
            ? '${percentage.toStringAsFixed(1)}%'
            : '', // 只在较大区块显示百分比
        titleStyle: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        radius: 130, // 大幅增加饼图半径
        titlePositionPercentageOffset: 0.55, // 调整标题位置
        borderSide: _selectedSectionIndex == index
            ? BorderSide(color: Colors.white, width: 2)
            : BorderSide.none,
      );
    }).toList();
  }

  // 构建图例
  Widget _buildLegend(Map<String, double> stats) {
    if (stats.isEmpty) {
      return const SizedBox();
    }

    // 计算总额
    final total = stats.values.fold<double>(0, (sum, amount) => sum + amount);

    // 对统计数据排序（按金额降序）
    final sortedStats = stats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 颜色列表 - 与饼图保持一致
    final colors = [
      Color(0xFF4285F4), // Google Blue
      Color(0xFFEA4335), // Google Red
      Color(0xFF34A853), // Google Green
      Color(0xFFFBBC05), // Google Yellow
      Color(0xFF9C27B0), // Purple
      Color(0xFF00BCD4), // Cyan
      Color(0xFFFF9800), // Orange
      Color(0xFF795548), // Brown
      Color(0xFF607D8B), // Blue Grey
      Color(0xFF3F51B5), // Indigo
    ];

    return Column(
      children: List.generate(
        sortedStats.length,
        (index) {
          final entry = sortedStats[index];
          final category = entry.key;
          final amount = entry.value;
          final percentage = total > 0 ? (amount / total * 100) : 0;

          return Container(
            margin: EdgeInsets.only(bottom: 12.h),
            child: Row(
              children: [
                // 颜色指示器
                Container(
                  width: 20.r,
                  height: 20.r,
                  decoration: BoxDecoration(
                    color: colors[index % colors.length],
                    shape: BoxShape.circle,
                  ),
                ),

                SizedBox(width: 15.w),

                // 分类名称
                Expanded(
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),

                // 百分比
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: colors[index % colors.length],
                  ),
                ),

                SizedBox(width: 15.w),

                // 金额
                Text(
                  FormatUtil.formatCurrency(amount),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 构建列表视图
  Widget _buildListView(
      Map<String, double> stats, List<TransactionModel> transactions) {
    // 计算总额
    final filteredTransactions =
        transactions.where((t) => t.type == _statsType).toList();
    final total =
        filteredTransactions.fold<double>(0, (sum, t) => sum + t.amount);

    // 对统计数据排序（按金额降序）
    final sortedStats = stats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: EdgeInsets.all(15.r),
      children: [
        // 总额卡片
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(15.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _statsType == AppConstants.incomeType ? '本月总收入' : '本月总支出',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  FormatUtil.formatCurrency(total),
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: _statsType == AppConstants.incomeType
                        ? AppTheme.incomeColor
                        : AppTheme.expenseColor,
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  '共${filteredTransactions.length}笔交易',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 20.h),

        // 添加分类数据列表
        ...sortedStats.map((entry) {
          final category = entry.key;
          final amount = entry.value;
          final percentage = total > 0 ? (amount / total * 100) : 0;

          return Card(
            margin: EdgeInsets.only(bottom: 10.h),
            elevation: 1,
            child: Padding(
              padding: EdgeInsets.all(15.r),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    FormatUtil.formatCurrency(amount),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: _statsType == AppConstants.incomeType
                          ? AppTheme.incomeColor
                          : AppTheme.expenseColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  // 构建空数据视图
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart,
            size: 80.sp,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 20.h),
          Text(
            '暂无统计数据',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            '记录一些收支后可以查看统计分析',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // 修改 build 方法中的月份选择器部分
  Widget _buildMonthSelector() {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: EdgeInsets.all(15.r),
          child: DropdownButtonFormField<String>(
            value: _selectedMonth,
            decoration: InputDecoration(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10.r, vertical: 5.r),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              isDense: true,
            ),
            items: _months.map((month) {
              // 判断是否有数据
              final hasData = provider.hasDataForMonth(month);
              return DropdownMenuItem(
                value: month,
                child: Text(
                  month,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: hasData ? Colors.black : Colors.grey,
                    fontWeight: hasData ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedMonth = value;
              });
              // 切换月份后重新加载数据
              if (value != null) {
                _loadTransactionsForMonth(value);
              }
            },
          ),
        );
      },
    );
  }
}
