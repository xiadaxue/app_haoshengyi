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

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // 使用延迟加载确保页面完全初始化
    ToastUtil.debug("统计页面初始化");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ToastUtil.debug("统计页面准备加载数据");
      _loadMonths();
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
      final currentMonth = '${now.year}年${now.month.toString().padLeft(2, '0')}月';
      
      ToastUtil.debug("当前月份: $currentMonth");
      
      final transactionProvider = context.read<TransactionProvider>();
      ToastUtil.debug("开始获取可用月份");
      final months = await transactionProvider.getAvailableMonths();
  
      ToastUtil.debug("获取到月份列表: $months");
      
      // 如果没有月份数据，则使用当前月份
      if (months.isEmpty) {
        ToastUtil.debug("没有月份数据，使用当前月份");
        
        setState(() {
          _months = [currentMonth];
          _selectedMonth = currentMonth;
        });
        
        // 尝试加载当前月份的数据
        await _loadTransactionsForMonth(currentMonth);
      } else {
        setState(() {
          _months = months;
          _selectedMonth = months.last;
        });
        
        ToastUtil.debug("选择月份: $_selectedMonth");
        // 加载选中月份的数据
        await _loadTransactionsForMonth(_selectedMonth!);
      }
    } catch (e) {
      ToastUtil.debug("加载月份列表失败: $e");
      
      // 出错时使用当前月份
      final now = DateTime.now().toLocal();
      final currentMonth = '${now.year}年${now.month.toString().padLeft(2, '0')}月';
      
      ToastUtil.debug("使用默认月份: $currentMonth");
      
      setState(() {
        _months = [currentMonth];
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

      // 获取交易数据
      await transactionProvider.getTransactions(
        startDate: startDateStr,
        endDate: endDateStr,
        refresh: true,
      );

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
      final category = transaction.category;
      final amount = transaction.amount;

      _categoryStats[category] = (_categoryStats[category] ?? 0) + amount;
    }

    print('计算完成的分类统计: $_categoryStats');
  }

  // 修改 build 方法
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('统计分析'),
      ),
      body: Column(
        children: [
          // 月份选择器
          Padding(
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
              items: _months
                  .map((month) => DropdownMenuItem(
                        value: month,
                        child: Text(month),
                      ))
                  .toList(),
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
          ),
          SizedBox(height: 10.h),

          // 统计类型选择和视图类型切换
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.r, vertical: 10.r),
            child: Row(
              children: [
                // 收入/支出切换
                Expanded(
                  child: Container(
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
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

                // 图表/列表切换
                Container(
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      _buildViewTab('chart', Icons.pie_chart),
                      _buildViewTab('list', Icons.list),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 修改：主内容区域
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _transactions.isEmpty
                    ? _buildEmptyView()
                    : _statsType == AppConstants.incomeType &&
                            !_transactions
                                .any((t) => t.type == AppConstants.incomeType)
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.bar_chart,
                                  size: 60.sp,
                                  color: Colors.grey.shade300,
                                ),
                                SizedBox(height: 20.h),
                                Text(
                                  '暂无收入数据',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _statsType == AppConstants.expenseType &&
                                !_transactions.any(
                                    (t) => t.type == AppConstants.expenseType)
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.bar_chart,
                                      size: 60.sp,
                                      color: Colors.grey.shade300,
                                    ),
                                    SizedBox(height: 20.h),
                                    Text(
                                      '暂无支出数据',
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              )
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
                                    ? _buildChartView(
                                        _categoryStats, _transactions)
                                    : _buildListView(
                                        _categoryStats, _transactions),
          ),
        ],
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

  // 构建图例

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
}
